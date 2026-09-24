#requires -Version 5.1
<#
.SYNOPSIS
    Deploy AgroGestor to a single Ubuntu EC2 instance using Docker Compose.

.DESCRIPTION
    This script:
      1. Validates the local AWS CLI, SSH, SCP, tar, and environment file.
      2. Creates an SSH key pair and security group when needed.
      3. Launches an Ubuntu 24.04 EC2 instance with Docker installed by UserData.
      4. Uploads only the Compose file, backend, and a deployment .env.
      5. Runs Docker Compose and waits for /api/health/.
      6. Prints the public API URL.

    The default deployment listens on HTTP port 8000. It is suitable for a
    temporary POC only. Do not expose real or sensitive production data over
    plain HTTP. Use -ReplaceExisting to terminate previously named
    AgroGestor instances after the new instance passes its health check.

.EXAMPLE
    .\scripts\deploy-ec2.ps1 -UseElasticIp

.EXAMPLE
    .\scripts\deploy-ec2.ps1 -ReplaceExisting -ForceReplacement -UseElasticIp -ReleaseOldElasticIps

.EXAMPLE
    .\scripts\deploy-ec2.ps1 -Profile agrogestor-deploy -Region us-east-2 -InstanceType t3.small -UseElasticIp
#>

[CmdletBinding()]
param(
    [string]$Profile = '',
    [string]$Region = 'us-east-2',
    [string]$InstanceType = 't3.small',
    [string]$InstanceName = 'agrogestor-api',
    [string]$KeyName = '',
    [string]$KeyFile = '',
    [string]$AmiId = '',
    [string]$SecurityGroupId = '',
    [string]$EnvFile = '',
    [string]$SshCidr = '',
    [switch]$UseElasticIp,
    [switch]$AllowInsecureDebug,
    [switch]$ReplaceExisting,
    [switch]$ForceReplacement,
    [switch]$ReleaseOldElasticIps,
    [switch]$KeepInstanceOnFailure,
    [ValidateRange(5, 60)]
    [int]$WaitMinutes = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($null -ne (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue)) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$TempRoot = [System.IO.Path]::GetTempPath()
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

if ([string]::IsNullOrWhiteSpace($Profile)) {
    if (-not [string]::IsNullOrWhiteSpace($env:AWS_PROFILE)) {
        $Profile = $env:AWS_PROFILE
    } else {
        $Profile = 'default'
    }
}
$script:EffectiveProfile = $Profile
$script:Region = $Region

$instanceId = $null
$publicIp = $null
$allocationId = $null
$securityGroupId = $SecurityGroupId
$createdSecurityGroup = $false
$createdKey = $false
$archivePath = $null
$stagePath = $null
$remoteScriptPath = $null
$oldAgrogestorInstances = @()

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[deploy] $Message" -ForegroundColor Cyan
}

function Write-Notice {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[deploy] $Message" -ForegroundColor Yellow
}

function Assert-Command {
    param([Parameter(Mandatory)][string[]]$Names)
    foreach ($name in $Names) {
        if ($null -eq (Get-Command $name -ErrorAction SilentlyContinue)) {
            throw "Required command '$name' was not found in PATH."
        }
    }
}

function Invoke-Aws {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $fullArguments = @(
        '--profile', $script:EffectiveProfile,
        '--region', $script:Region,
        '--no-cli-pager'
    ) + $Arguments

    $output = & aws @fullArguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = (($output | Out-String).Trim())

    if ($exitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "AWS CLI failed with exit code $exitCode."
        }
        throw "AWS CLI failed with exit code ${exitCode}: $text"
    }

    return $text
}

function Get-EnvValue {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Name
    )

    foreach ($line in ($Content -split '\r?\n')) {
        if ($line -match "^\s*$([regex]::Escape($Name))\s*=\s*(.*)$") {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }

    return $null
}

function Set-EnvValue {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Content -split '\r?\n')) {
        [void]$lines.Add($line)
    }

    $pattern = "^\s*$([regex]::Escape($Name))\s*="
    $replacement = "$Name=$Value"
    $found = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $pattern) {
            $lines[$i] = $replacement
            $found = $true
        }
    }

    if (-not $found) {
        [void]$lines.Add($replacement)
    }

    return ($lines -join "`n")
}

function New-RandomSecret {
    $bytes = New-Object byte[] 64
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }

    return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function Resolve-SshCidr {
    param([string]$RequestedCidr)

    $cidr = $RequestedCidr.Trim()
    if ([string]::IsNullOrWhiteSpace($cidr)) {
        $detectedIp = $null
        try {
            $detectedIp = (Invoke-RestMethod -Uri 'https://checkip.amazonaws.com' -TimeoutSec 15 | Out-String).Trim()
        } catch {
            try {
                $detectedIp = (& curl.exe -4 -fsS --max-time 15 'https://api.ipify.org' | Out-String).Trim()
            } catch {
                $detectedIp = $null
            }
        }

        if ([string]::IsNullOrWhiteSpace($detectedIp)) {
            throw "Could not detect the public IP. Pass -SshCidr with your current public IP/32."
        }

        if ($detectedIp -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
            throw "The public IP detector returned an unexpected value. Pass -SshCidr manually."
        }
        $cidr = "$detectedIp/32"
    }

    if ($cidr -notmatch '/\d{1,3}$') {
        $cidr = "$cidr/32"
    }

    if ($cidr -eq '0.0.0.0/0') {
        Write-Notice 'SSH will be open to the entire Internet. Prefer your current IP/32.'
    }

    return $cidr
}

function Get-DeploymentAmi {
    param([string]$RequestedAmi)

    if (-not [string]::IsNullOrWhiteSpace($RequestedAmi)) {
        return $RequestedAmi.Trim()
    }

    $ami = $null
    try {
        $ami = Invoke-Aws @(
            'ec2', 'describe-images',
            '--owners', '099720109477',
            '--filters',
            'Name=architecture,Values=x86_64',
            'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*',
            'Name=state,Values=available',
            '--query', 'sort_by(Images,&CreationDate)[-1].ImageId',
            '--output', 'text'
        )
    } catch {
        Write-Notice "Could not query the Canonical AMI catalog: $($_.Exception.Message)"
    }

    if ([string]::IsNullOrWhiteSpace($ami) -or $ami -eq 'None') {
        try {
            $ami = Invoke-Aws @(
                'ec2', 'describe-images',
                '--owners', '099720109477',
                '--filters',
                'Name=architecture,Values=x86_64',
                'Name=name,Values=*ubuntu-noble-24.04-amd64-server-*',
                'Name=state,Values=available',
                '--query', 'sort_by(Images,&CreationDate)[-1].ImageId',
                '--output', 'text'
            )
        } catch {
            Write-Notice "Could not query the broad Canonical AMI catalog: $($_.Exception.Message)"
        }
    }

    if ([string]::IsNullOrWhiteSpace($ami) -or $ami -eq 'None') {
        throw 'No Ubuntu 24.04 x86_64 AMI was found. Pass an explicit -AmiId.'
    }

    return $ami.Trim()
}

function Get-DefaultNetwork {
    $vpcId = Invoke-Aws @(
        'ec2', 'describe-vpcs',
        '--filters', 'Name=is-default,Values=true',
        '--query', 'Vpcs[0].VpcId',
        '--output', 'text'
    )

    if ([string]::IsNullOrWhiteSpace($vpcId) -or $vpcId -eq 'None') {
        throw 'No default VPC was found. Create a default VPC or pass a custom network implementation.'
    }

    $subnetId = Invoke-Aws @(
        'ec2', 'describe-subnets',
        '--filters',
        "Name=vpc-id,Values=$vpcId",
        'Name=default-for-az,Values=true',
        '--query', 'Subnets[0].SubnetId',
        '--output', 'text'
    )

    if ([string]::IsNullOrWhiteSpace($subnetId) -or $subnetId -eq 'None') {
        throw 'No default subnet was found in the default VPC.'
    }

    return [pscustomobject]@{
        VpcId = $vpcId.Trim()
        SubnetId = $subnetId.Trim()
    }
}

function Get-AgrogestorInstances {
    param([Parameter(Mandatory)][string]$NamePrefix)

    $raw = Invoke-Aws @(
        'ec2', 'describe-instances',
        '--filters', 'Name=instance-state-name,Values=pending,running,stopping,stopped',
        '--output', 'json'
    )

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $response = $raw | ConvertFrom-Json
    $matches = @()

    foreach ($reservation in @($response.Reservations)) {
        foreach ($instance in @($reservation.Instances)) {
            $tags = @()
            if ($null -ne $instance.PSObject.Properties['Tags']) {
                $tags = @($instance.Tags)
            }

            $name = $null
            foreach ($tag in $tags) {
                if ($tag.Key -eq 'Name') {
                    $name = [string]$tag.Value
                    break
                }
            }

            if ([string]::IsNullOrWhiteSpace($name) -or -not $name.StartsWith($NamePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }

            $allocations = @()
            if ($null -ne $instance.PSObject.Properties['NetworkInterfaces']) {
                foreach ($networkInterface in @($instance.NetworkInterfaces)) {
                    $association = $networkInterface.Association
                    if ($null -ne $association -and -not [string]::IsNullOrWhiteSpace([string]$association.AllocationId)) {
                        $allocations += [string]$association.AllocationId
                    }
                }
            }

            $publicIp = $null
            if ($null -ne $instance.PSObject.Properties['PublicIpAddress']) {
                $publicIp = $instance.PublicIpAddress
            }

            $matches += [pscustomobject]@{
                InstanceId = [string]$instance.InstanceId
                Name = $name
                State = [string]$instance.State.Name
                PublicIp = $publicIp
                AllocationIds = @($allocations)
            }
        }
    }

    return $matches
}

function Stop-AgrogestorInstances {
    param(
        [Parameter(Mandatory)][object[]]$Instances,
        [switch]$ReleaseElasticIps
    )

    $ids = @($Instances | ForEach-Object { $_.InstanceId } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($ids.Count -eq 0) {
        return
    }

    Write-Step "Terminating previous AgroGestor instances: $($ids -join ', ')"
    $terminateArgs = @('ec2', 'terminate-instances', '--instance-ids') + $ids + @('--output', 'text')
    [void](Invoke-Aws $terminateArgs)
    $waitArgs = @('ec2', 'wait', 'instance-terminated', '--instance-ids') + $ids
    [void](Invoke-Aws $waitArgs)

    if ($ReleaseElasticIps) {
        $allocationIds = @(
            $Instances |
                ForEach-Object { @($_.AllocationIds) } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
        foreach ($allocationId in $allocationIds) {
            try {
                Write-Notice "Releasing previous Elastic IP $allocationId"
                [void](Invoke-Aws @(
                    'ec2', 'release-address',
                    '--allocation-id', $allocationId,
                    '--output', 'text'
                ))
            } catch {
                Write-Notice "Could not release Elastic IP ${allocationId}: $($_.Exception.Message)"
            }
        }
    }
}

function Ensure-SecurityGroupRule {
    param(
        [Parameter(Mandatory)][string]$GroupId,
        [Parameter(Mandatory)][int]$Port,
        [Parameter(Mandatory)][string]$Cidr
    )

    $rawRules = Invoke-Aws @(
        'ec2', 'describe-security-group-rules',
        '--filters', "Name=group-id,Values=$GroupId",
        '--output', 'json'
    )

    if ([string]::IsNullOrWhiteSpace($rawRules)) {
        $rules = @()
    } else {
        $parsedRules = $rawRules | ConvertFrom-Json
        if ($null -ne $parsedRules.PSObject.Properties['SecurityGroupRules']) {
            $rules = @($parsedRules.SecurityGroupRules)
        } else {
            $rules = @($parsedRules)
        }
    }

    foreach ($rule in $rules) {
        if ($null -eq $rule) { continue }
        if ($rule.IpProtocol -ne 'tcp') { continue }
        if ([int]$rule.FromPort -ne $Port) { continue }
        if ([int]$rule.ToPort -ne $Port) { continue }

        $ruleCidrs = @()
        if ($null -ne $rule.PSObject.Properties['CidrIpv4'] -and -not [string]::IsNullOrWhiteSpace($rule.CidrIpv4)) {
            $ruleCidrs += [string]$rule.CidrIpv4
        }
        if ($null -ne $rule.PSObject.Properties['IpRanges']) {
            foreach ($range in @($rule.IpRanges)) {
                if ($null -ne $range -and $null -ne $range.PSObject.Properties['CidrIp']) {
                    $ruleCidrs += [string]$range.CidrIp
                }
            }
        }
        if ($ruleCidrs -contains $Cidr) {
            return
        }
    }

    [void](Invoke-Aws @(
        'ec2', 'authorize-security-group-ingress',
        '--group-id', $GroupId,
        '--ip-permissions', "IpProtocol=tcp,FromPort=$Port,ToPort=$Port,IpRanges=[{CidrIp=$Cidr}]",
        '--output', 'text'
    ))
}

function New-SshKey {
    param(
        [string]$RequestedName,
        [string]$RequestedFile
    )

    $name = $RequestedName.Trim()
    $file = $RequestedFile
    $created = $false

    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = 'agrogestor-deploy'
        $file = Join-Path $RepoRoot "deploy-keys\$name.pem"
    } elseif ([string]::IsNullOrWhiteSpace($file)) {
        $file = Join-Path $RepoRoot "deploy-keys\$name.pem"
    }

    $fileFullPath = [System.IO.Path]::GetFullPath($file)
    $parent = Split-Path -Parent $fileFullPath
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    if (Test-Path -LiteralPath $fileFullPath -PathType Leaf) {
        $remoteKey = Invoke-Aws @(
            'ec2', 'describe-key-pairs',
            '--key-names', $name,
            '--query', 'KeyPairs[0].KeyName',
            '--output', 'text'
        )
        if ([string]::IsNullOrWhiteSpace($remoteKey) -or $remoteKey -eq 'None') {
            throw "The local private key exists, but AWS has no key pair named '$name'. Remove the local file and retry."
        }
    } else {
        $keyMaterial = Invoke-Aws @(
            'ec2', 'create-key-pair',
            '--key-name', $name,
            '--query', 'KeyMaterial',
            '--output', 'text'
        )

        if ([string]::IsNullOrWhiteSpace($keyMaterial) -or $keyMaterial -eq 'None') {
            throw "AWS did not return private key material for '$name'."
        }

        [System.IO.File]::WriteAllText($fileFullPath, $keyMaterial, $Utf8NoBom)
        $created = $true
        Write-Notice "Private key saved locally at $fileFullPath. Keep it private."
    }

    return [pscustomobject]@{
        Name = $name
        File = $fileFullPath
        Created = $created
    }
}

function New-DeploymentArchive {
    param(
        [Parameter(Mandatory)][string]$SourceEnvFile,
        [Parameter(Mandatory)][string]$PublicIpAddress,
        [Parameter(Mandatory)][bool]$KeepDebug
    )

    if (-not (Test-Path -LiteralPath $SourceEnvFile -PathType Leaf)) {
        throw "Environment file not found: $SourceEnvFile"
    }

    $envContent = [System.IO.File]::ReadAllText($SourceEnvFile)
    $secret = Get-EnvValue $envContent 'DJANGO_SECRET_KEY'
    if ([string]::IsNullOrWhiteSpace($secret)) {
        $secret = Get-EnvValue $envContent 'SECRET_KEY'
    }

    $needsSecret = [string]::IsNullOrWhiteSpace($secret) -or $secret.Length -lt 32 -or $secret -match '(?i)(django-insecure|change-me|your-secret|placeholder)'
    if ($needsSecret) {
        $secret = New-RandomSecret
        $envContent = Set-EnvValue $envContent 'DJANGO_SECRET_KEY' $secret
        [System.IO.File]::WriteAllText($SourceEnvFile, $envContent, $Utf8NoBom)
        Write-Notice 'Generated and saved a new DJANGO_SECRET_KEY in the local .env file.'
    }

    foreach ($requiredName in @('DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD')) {
        $value = Get-EnvValue $envContent $requiredName
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Required environment variable '$requiredName' is missing in $SourceEnvFile."
        }
    }

    $stage = Join-Path $TempRoot ("agrogestor-stage-{0}" -f [guid]::NewGuid().ToString('N'))
    $archive = Join-Path $TempRoot ("agrogestor-deploy-{0}.tar.gz" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    Copy-Item -LiteralPath (Join-Path $RepoRoot 'docker-compose.yml') -Destination $stage -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'backend') -Destination (Join-Path $stage 'backend') -Recurse -Force

    $deploymentEnv = $envContent
    $debugValue = if ($KeepDebug) { 'True' } else { 'False' }
    $deploymentEnv = Set-EnvValue $deploymentEnv 'DJANGO_SECRET_KEY' $secret
    $deploymentEnv = Set-EnvValue $deploymentEnv 'DJANGO_DEBUG' $debugValue
    $deploymentEnv = Set-EnvValue $deploymentEnv 'DJANGO_ALLOWED_HOSTS' "$PublicIpAddress,127.0.0.1,localhost"
    $deploymentEnv = Set-EnvValue $deploymentEnv 'BACKEND_URL' "http://${PublicIpAddress}:8000"
    [System.IO.File]::WriteAllText((Join-Path $stage '.env'), $deploymentEnv, $Utf8NoBom)

    $backendStage = Join-Path $stage 'backend'
    $excludedDirectories = @('__pycache__', '.pytest_cache', '.mypy_cache', 'logs', 'media', 'staticfiles', '.git')
    foreach ($directory in @(Get-ChildItem -LiteralPath $backendStage -Recurse -Force -Directory)) {
        if ($excludedDirectories -contains $directory.Name) {
            Remove-Item -LiteralPath $directory.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $excludedFiles = @(
        '*.pyc', '*.pyo', '*.db', '*.sqlite3',
        'seed_*.py', 'e2e_tests.py', 'check_*.py', 'fix_migration.py', 'supabase_init.sql'
    )
    foreach ($file in @(Get-ChildItem -LiteralPath $backendStage -Recurse -Force -File)) {
        $remove = $false
        foreach ($pattern in $excludedFiles) {
            if ($file.Name -like $pattern) {
                $remove = $true
                break
            }
        }
        if ($file.Name -eq '.env') { $remove = $true }
        if ($remove) {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    & tar -czf $archive -C $stage .
    if ($LASTEXITCODE -ne 0) {
        throw "tar failed while creating the deployment archive (exit code $LASTEXITCODE)."
    }

    return [pscustomobject]@{
        Stage = $stage
        Archive = $archive
    }
}

function New-RemoteBootstrap {
    $path = Join-Path $TempRoot ("agrogestor-remote-{0}.sh" -f [guid]::NewGuid().ToString('N'))
    $script = @'
#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR=/home/ubuntu/AgroGestor
ARCHIVE=/home/ubuntu/agrogestor-deploy.tar.gz

if ! command -v curl >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y curl
fi

if ! sudo docker info >/dev/null 2>&1; then
  for _ in $(seq 1 36); do
    if sudo docker info >/dev/null 2>&1; then
      break
    fi
    sleep 5
  done
fi

if ! sudo docker info >/dev/null 2>&1; then
  echo 'Docker did not become ready. cloud-init output:' >&2
  sudo tail -n 200 /var/log/cloud-init-output.log 2>/dev/null || true
  exit 1
fi

if sudo docker compose version >/dev/null 2>&1; then
  compose=(sudo docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  compose=(sudo docker-compose)
else
  echo 'Docker Compose v1 or v2 is not installed.' >&2
  sudo tail -n 200 /var/log/cloud-init-output.log 2>/dev/null || true
  exit 1
fi

sudo rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
tar -xzf "$ARCHIVE" -C "$APP_DIR"
chmod 600 "$APP_DIR/.env"
cd "$APP_DIR"

echo 'Starting AgroGestor containers...'
"${compose[@]}" up -d --build

for _ in $(seq 1 36); do
  if curl -fsS http://127.0.0.1:8000/api/health/ > /tmp/agrogestor-health.json; then
    cat /tmp/agrogestor-health.json
    rm -f /tmp/agrogestor-health.json "$ARCHIVE" /home/ubuntu/agrogestor-remote.sh
    exit 0
  fi
  sleep 10
done

echo 'AgroGestor did not become healthy in time.' >&2
"${compose[@]}" ps || true
"${compose[@]}" logs --tail=200 migrate backend scheduler || true
exit 1
'@
    [System.IO.File]::WriteAllText($path, $script, $Utf8NoBom)
    return $path
}

function Wait-ForSsh {
    param(
        [Parameter(Mandatory)][string]$Address,
        [Parameter(Mandatory)][string]$PrivateKey,
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )

    $sshArguments = @(
        '-i', $PrivateKey,
        '-o', 'StrictHostKeyChecking=accept-new',
        '-o', 'ConnectTimeout=10',
        "ubuntu@$Address",
        'true'
    )

    for ($elapsed = 0; $elapsed -lt $TimeoutSeconds; $elapsed += 10) {
        & ssh @sshArguments 2>$null
        if ($LASTEXITCODE -eq 0) {
            return
        }
        Start-Sleep -Seconds 10
    }

    throw "SSH did not become available on $Address within $TimeoutSeconds seconds."
}

function Invoke-Scp {
    param(
        [Parameter(Mandatory)][string]$LocalPath,
        [Parameter(Mandatory)][string]$RemotePath,
        [Parameter(Mandatory)][string]$Address,
        [Parameter(Mandatory)][string]$PrivateKey
    )

    $scpArguments = @(
        '-i', $PrivateKey,
        '-o', 'StrictHostKeyChecking=accept-new',
        '-o', 'ConnectTimeout=10',
        $LocalPath,
        "ubuntu@$Address`:$RemotePath"
    )

    & scp @scpArguments
    if ($LASTEXITCODE -ne 0) {
        throw "scp failed while uploading $LocalPath (exit code $LASTEXITCODE)."
    }
}

function Invoke-RemoteDeployment {
    param(
        [Parameter(Mandatory)][string]$Address,
        [Parameter(Mandatory)][string]$PrivateKey,
        [Parameter(Mandatory)][string]$RemoteScript
    )

    $sshArguments = @(
        '-i', $PrivateKey,
        '-o', 'StrictHostKeyChecking=accept-new',
        '-o', 'ConnectTimeout=10',
        "ubuntu@$Address",
        'chmod 700 /home/ubuntu/agrogestor-remote.sh && /home/ubuntu/agrogestor-remote.sh'
    )

    & ssh @sshArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Remote deployment failed (exit code $LASTEXITCODE)."
    }
}

function Get-InstancePublicIp {
    param([Parameter(Mandatory)][string]$Id)

    $address = Invoke-Aws @(
        'ec2', 'describe-instances',
        '--instance-ids', $Id,
        '--query', 'Reservations[0].Instances[0].PublicIpAddress',
        '--output', 'text'
    )

    if ([string]::IsNullOrWhiteSpace($address) -or $address -eq 'None') {
        throw "The instance $Id has no public IPv4 address."
    }

    return $address.Trim()
}

function Save-DeploymentInfo {
    param(
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][string]$Address,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Group
    )

    $deploymentsDir = Join-Path $RepoRoot 'deployments'
    New-Item -ItemType Directory -Path $deploymentsDir -Force | Out-Null
    $path = Join-Path $deploymentsDir 'last-ec2-deployment.json'
    $info = [ordered]@{
        profile = $script:EffectiveProfile
        region = $script:Region
        instance_id = $Instance
        public_ip = $Address
        api_url = "http://${Address}:8000/api/"
        health_url = "http://${Address}:8000/api/health/"
        ssh_user = 'ubuntu'
        key_file = $Key
        security_group_id = $Group
        created_at = (Get-Date).ToUniversalTime().ToString('o')
    }
    [System.IO.File]::WriteAllText($path, ($info | ConvertTo-Json), $Utf8NoBom)
    return $path
}

try {
    Write-Step 'Checking local prerequisites...'
    Assert-Command @('aws', 'ssh', 'scp', 'tar')

    $envSource = if ([string]::IsNullOrWhiteSpace($EnvFile)) {
        Join-Path $RepoRoot '.env'
    } else {
        [System.IO.Path]::GetFullPath($EnvFile)
    }

    if (-not (Test-Path -LiteralPath $envSource -PathType Leaf)) {
        throw "The deployment .env was not found: $envSource. Create it from .env.example first."
    }

    Write-Step "Checking AWS identity for profile '$Profile'..."
    $identityJson = Invoke-Aws @('sts', 'get-caller-identity', '--output', 'json')
    $identity = $identityJson | ConvertFrom-Json
    if ($identity.Arn -match ':root$') {
        Write-Notice 'Warning: the selected profile is the AWS root user. It has unrestricted account access.'
    }
    Write-Notice "Using AWS identity: $($identity.Arn)"
    Write-Notice 'Secret values are not displayed.'

    $oldAgrogestorInstances = @()
    if ($ReplaceExisting) {
        Write-Step 'Looking for previous AgroGestor instances...'
        $oldAgrogestorInstances = @(Get-AgrogestorInstances 'agrogestor')
        if ($oldAgrogestorInstances.Count -eq 0) {
            Write-Notice 'No previous AgroGestor instances were found.'
        } else {
            Write-Notice 'The new instance will be created and validated before these instances are terminated:'
            foreach ($old in $oldAgrogestorInstances) {
                Write-Notice "  $($old.InstanceId) | $($old.Name) | $($old.State) | $($old.PublicIp)"
            }

            if (-not $ForceReplacement) {
                $confirmation = Read-Host "Type REPLACE to continue"
                if ($confirmation -ne 'REPLACE') {
                    throw 'Replacement cancelled. No instances were terminated.'
                }
            }
        }
    }

    $sshCidr = Resolve-SshCidr $SshCidr
    $network = Get-DefaultNetwork
    $ami = Get-DeploymentAmi $AmiId

    Write-Step 'Preparing the SSH key...'
    $key = New-SshKey $KeyName $KeyFile
    if ($key.Created) {
        $createdKey = $true
    }

    if ([string]::IsNullOrWhiteSpace($securityGroupId)) {
        $sgName = 'agrogestor-api-sg'
        $existingSg = Invoke-Aws @(
            'ec2', 'describe-security-groups',
            '--filters', "Name=group-name,Values=$sgName",
            '--query', "SecurityGroups[?VpcId=='$($network.VpcId)'].GroupId",
            '--output', 'text'
        )

        if (-not [string]::IsNullOrWhiteSpace($existingSg) -and $existingSg -ne 'None') {
            $securityGroupId = $existingSg.Trim()
            Write-Notice "Reusing security group $securityGroupId."
        } else {
            Write-Step 'Creating a security group...'
            $sgJson = Invoke-Aws @(
                'ec2', 'create-security-group',
                '--group-name', $sgName,
                '--description', 'AgroGestor API HTTP on port 8000',
                '--vpc-id', $network.VpcId,
                '--tag-specifications', "ResourceType=security-group,Tags=[{Key=Name,Value=$sgName},{Key=ManagedBy,Value=deploy-ec2.ps1}]",
                '--output', 'json'
            )
            $securityGroupId = ($sgJson | ConvertFrom-Json).GroupId
            $createdSecurityGroup = $true
        }
    }

    Write-Step 'Allowing SSH from your IP and HTTP 8000 from the Internet...'
    Ensure-SecurityGroupRule $securityGroupId 22 $sshCidr
    Ensure-SecurityGroupRule $securityGroupId 8000 '0.0.0.0/0'

    Write-Step 'Launching Ubuntu EC2 with Docker UserData...'
    $userData = @'
#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io git ca-certificates curl tar
if ! apt-get install -y docker-compose-v2; then
  apt-get install -y docker-compose
fi
systemctl enable --now docker
usermod -aG docker ubuntu || true
touch /var/tmp/agrogestor-docker-ready
'@

    $instanceTagSpec = "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName},{Key=ManagedBy,Value=deploy-ec2.ps1}]"

    $publicIpArguments = if ($UseElasticIp) {
        '--no-associate-public-ip-address'
    } else {
        '--associate-public-ip-address'
    }

    $runArguments = @(
        'ec2', 'run-instances',
        '--image-id', $ami,
        '--instance-type', $InstanceType,
        '--key-name', $key.Name,
        '--security-group-ids', $securityGroupId,
        '--subnet-id', $network.SubnetId,
        '--user-data', $userData,
        '--tag-specifications', $instanceTagSpec,
        '--query', 'Instances[0].InstanceId',
        '--output', 'text'
    )
    $runArguments += $publicIpArguments
    $instanceId = (Invoke-Aws -Arguments $runArguments).Trim()
    if ([string]::IsNullOrWhiteSpace($instanceId) -or $instanceId -eq 'None') {
        throw 'EC2 did not return an instance ID.'
    }
    Write-Notice "Instance ID: $instanceId"

    Write-Step 'Waiting for EC2 and Docker...'
    [void](Invoke-Aws @('ec2', 'wait', 'instance-running', '--instance-ids', $instanceId))

    if ($UseElasticIp) {
        Write-Step 'Allocating and attaching an Elastic IP...'
        $allocationId = (Invoke-Aws @(
            'ec2', 'allocate-address',
            '--domain', 'vpc',
            '--query', 'AllocationId',
            '--output', 'text'
        )).Trim()
        [void](Invoke-Aws @(
            'ec2', 'associate-address',
            '--instance-id', $instanceId,
            '--allocation-id', $allocationId,
            '--output', 'text'
        ))
    }

    [void](Invoke-Aws @('ec2', 'wait', 'instance-status-ok', '--instance-ids', $instanceId))
    $publicIp = Get-InstancePublicIp $instanceId
    Write-Notice "Public IP: $publicIp"

    Write-Step 'Waiting for SSH...'
    Wait-ForSsh $publicIp $key.File ($WaitMinutes * 60)

    Write-Step 'Preparing a clean deployment bundle...'
    $bundle = New-DeploymentArchive $envSource $publicIp $AllowInsecureDebug.IsPresent
    $archivePath = $bundle.Archive
    $stagePath = $bundle.Stage
    $remoteScriptPath = New-RemoteBootstrap

    Write-Step 'Uploading the project and deployment environment...'
    Invoke-Scp $archivePath '/home/ubuntu/agrogestor-deploy.tar.gz' $publicIp $key.File
    Invoke-Scp $remoteScriptPath '/home/ubuntu/agrogestor-remote.sh' $publicIp $key.File

    Write-Step 'Building images and starting Docker Compose...'
    Invoke-RemoteDeployment $publicIp $key.File $remoteScriptPath

    $apiUrl = "http://${publicIp}:8000/api/"
    $healthUrl = "http://${publicIp}:8000/api/health/"
    $infoPath = Save-DeploymentInfo $instanceId $publicIp $key.File $securityGroupId

    if ($ReplaceExisting -and $oldAgrogestorInstances.Count -gt 0) {
        try {
            Stop-AgrogestorInstances -Instances $oldAgrogestorInstances -ReleaseElasticIps:$ReleaseOldElasticIps
        } catch {
            Write-Notice "The new instance is healthy, but cleanup of previous instances needs attention: $($_.Exception.Message)"
        }
    }

    Write-Host ''
    Write-Host 'Deployment completed.' -ForegroundColor Green
    Write-Host "API URL:    $apiUrl" -ForegroundColor Green
    Write-Host "Health URL: $healthUrl" -ForegroundColor Green
    Write-Host "Instance:   $instanceId"
    Write-Host "SSH:        ssh -i `"$($key.File)`" ubuntu@$publicIp"
    Write-Host "Info file:  $infoPath"
    Write-Host ''
    Write-Notice 'Port 8000 is intentionally public and traffic is plain HTTP. Use this only for a temporary test.'
} catch {
    Write-Notice $_.Exception.Message

    if (-not $KeepInstanceOnFailure -and -not [string]::IsNullOrWhiteSpace($instanceId)) {
        try {
            Write-Notice "Terminating failed instance $instanceId..."
            [void](Invoke-Aws @('ec2', 'terminate-instances', '--instance-ids', $instanceId, '--output', 'text'))
            [void](Invoke-Aws @('ec2', 'wait', 'instance-terminated', '--instance-ids', $instanceId))
        } catch {
            Write-Notice "Automatic instance cleanup failed: $($_.Exception.Message)"
        }
    }

    if (-not $KeepInstanceOnFailure) {
        if (-not [string]::IsNullOrWhiteSpace($allocationId)) {
            try {
                [void](Invoke-Aws @('ec2', 'release-address', '--allocation-id', $allocationId, '--output', 'text'))
            } catch {
                Write-Notice "Elastic IP cleanup failed: $($_.Exception.Message)"
            }
        }
        if ($createdSecurityGroup -and -not [string]::IsNullOrWhiteSpace($securityGroupId)) {
            try {
                [void](Invoke-Aws @('ec2', 'delete-security-group', '--group-id', $securityGroupId, '--output', 'text'))
            } catch {
                Write-Notice "Security group cleanup failed: $($_.Exception.Message)"
            }
        }
        if ($createdKey -and $null -ne $key) {
            try {
                [void](Invoke-Aws @('ec2', 'delete-key-pair', '--key-name', $key.Name, '--output', 'text'))
            } catch {
                Write-Notice "Key pair cleanup failed: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Notice 'The failed instance was kept for debugging. Remove it manually when finished.'
    }

    throw
} finally {
    foreach ($path in @($archivePath, $remoteScriptPath, $stagePath)) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
