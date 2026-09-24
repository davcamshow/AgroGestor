param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '..\.env'),
    [string]$BackupDirectory = (Join-Path $PSScriptRoot '..\backups'),
    [string]$PostgresImage = 'postgres:17-alpine'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedEnvFile = (Resolve-Path -LiteralPath $EnvFile).Path
New-Item -ItemType Directory -Force -Path $BackupDirectory | Out-Null
$resolvedBackupDirectory = (Resolve-Path -LiteralPath $BackupDirectory).Path

function Read-DotEnv([string]$Path) {
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) {
            continue
        }
        $separator = $trimmed.IndexOf('=')
        if ($separator -lt 1) {
            continue
        }
        $name = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1).Trim()
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $values[$name] = $value
    }
    return $values
}

$envValues = Read-DotEnv $resolvedEnvFile
$requiredNames = @('DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD')
foreach ($name in $requiredNames) {
    if ([string]::IsNullOrWhiteSpace($envValues[$name])) {
        throw "Falta la variable $name en $resolvedEnvFile."
    }
}

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker no está disponible. Inicia Docker Desktop e intenta nuevamente.'
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupName = "agrogestor_supabase_$timestamp.dump"
$backupPath = Join-Path $resolvedBackupDirectory $backupName

foreach ($name in $requiredNames) {
    Set-Item -LiteralPath "Env:$name" -Value $envValues[$name]
}
$env:PGSSLMODE = 'require'
$env:BACKUP_FILE = $backupName

try {
    & docker run --rm `
        --env DB_HOST `
        --env DB_PORT `
        --env DB_NAME `
        --env DB_USER `
        --env DB_PASSWORD `
        --env PGSSLMODE `
        --env BACKUP_FILE `
        --mount "type=bind,source=$resolvedBackupDirectory,target=/backup" `
        $PostgresImage `
        sh -c 'export PGPASSWORD="$DB_PASSWORD"; pg_dump --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" --dbname="$DB_NAME" --format=custom --no-owner --no-acl --file="/backup/$BACKUP_FILE"'
    if ($LASTEXITCODE -ne 0) {
        throw 'pg_dump falló.'
    }

    & docker run --rm `
        --env BACKUP_FILE `
        --mount "type=bind,source=$resolvedBackupDirectory,target=/backup" `
        $PostgresImage `
        sh -c 'pg_restore --list "/backup/$BACKUP_FILE" >/dev/null'
    if ($LASTEXITCODE -ne 0) {
        throw 'La validación pg_restore falló.'
    }
}
finally {
    foreach ($name in $requiredNames) {
        Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
    Remove-Item Env:PGSSLMODE -ErrorAction SilentlyContinue
    Remove-Item Env:BACKUP_FILE -ErrorAction SilentlyContinue
}

$file = Get-Item -LiteralPath $backupPath
if ($file.Length -eq 0) {
    throw 'El archivo de respaldo está vacío.'
}

$hash = (Get-FileHash -LiteralPath $backupPath -Algorithm SHA256).Hash.ToLowerInvariant()
$hashLine = "$hash  $backupName"
$hashLine | Set-Content -LiteralPath "$backupPath.sha256" -Encoding ascii

Write-Host "Respaldo creado: $backupPath"
Write-Host "Tamaño: $($file.Length) bytes"
Write-Host "SHA256: $hash"
Write-Host 'Respaldo validado: true'
