<#
.Synopsis
Activate a Python virtual environment for the current PowerShell session.

.Description
Pushes the python executable for a virtual environment to the front of the
$Env:PATH environment variable and sets the prompt to signify that you are
in a Python virtual environment. Makes use of the command line switches as
well as the `pyvenv.cfg` file values present in the virtual environment.

.Parameter VenvDir
Path to the directory that contains the virtual environment to activate. The
default value for this is the parent of the directory that the Activate.ps1
script is located within.

.Parameter Prompt
The prompt prefix to display when this virtual environment is activated. By
default, this prompt is the name of the virtual environment folder (VenvDir)
surrounded by parentheses and followed by a single space (ie. '(.venv) ').

.Example
Activate.ps1
Activates the Python virtual environment that contains the Activate.ps1 script.

.Example
Activate.ps1 -Verbose
Activates the Python virtual environment that contains the Activate.ps1 script,
and shows extra information about the activation as it executes.

.Example
Activate.ps1 -VenvDir C:\Users\MyUser\Common\.venv
Activates the Python virtual environment located in the specified location.

.Example
Activate.ps1 -Prompt "MyPython"
Activates the Python virtual environment that contains the Activate.ps1 script,
and prefixes the current prompt with the specified string (surrounded in
parentheses) while the virtual environment is active.

.Notes
On Windows, it may be required to enable this Activate.ps1 script by setting the
execution policy for the user. You can do this by issuing the following PowerShell
command:

PS C:\> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

For more information on Execution Policies: 
https://go.microsoft.com/fwlink/?LinkID=135170

#>
Param(
    [Parameter(Mandatory = $false)]
    [String]
    $VenvDir,
    [Parameter(Mandatory = $false)]
    [String]
    $Prompt
)

<# Function declarations --------------------------------------------------- #>

<#
.Synopsis
Remove all shell session elements added by the Activate script, including the
addition of the virtual environment's Python executable from the beginning of
the PATH variable.

.Parameter NonDestructive
If present, do not remove this function from the global namespace for the
session.

#>
function global:deactivate ([switch]$NonDestructive) {
    # Revert to original values

    # The prior prompt:
    if (Test-Path -Path Function:_OLD_VIRTUAL_PROMPT) {
        Copy-Item -Path Function:_OLD_VIRTUAL_PROMPT -Destination Function:prompt
        Remove-Item -Path Function:_OLD_VIRTUAL_PROMPT
    }

    # The prior PYTHONHOME:
    if (Test-Path -Path Env:_OLD_VIRTUAL_PYTHONHOME) {
        Copy-Item -Path Env:_OLD_VIRTUAL_PYTHONHOME -Destination Env:PYTHONHOME
        Remove-Item -Path Env:_OLD_VIRTUAL_PYTHONHOME
    }

    # The prior PATH:
    if (Test-Path -Path Env:_OLD_VIRTUAL_PATH) {
        Copy-Item -Path Env:_OLD_VIRTUAL_PATH -Destination Env:PATH
        Remove-Item -Path Env:_OLD_VIRTUAL_PATH
    }

    # Just remove the VIRTUAL_ENV altogether:
    if (Test-Path -Path Env:VIRTUAL_ENV) {
        Remove-Item -Path env:VIRTUAL_ENV
    }

    # Just remove VIRTUAL_ENV_PROMPT altogether.
    if (Test-Path -Path Env:VIRTUAL_ENV_PROMPT) {
        Remove-Item -Path env:VIRTUAL_ENV_PROMPT
    }

    # Just remove the _PYTHON_VENV_PROMPT_PREFIX altogether:
    if (Get-Variable -Name "_PYTHON_VENV_PROMPT_PREFIX" -ErrorAction SilentlyContinue) {
        Remove-Variable -Name _PYTHON_VENV_PROMPT_PREFIX -Scope Global -Force
    }

    # Leave deactivate function in the global namespace if requested:
    if (-not $NonDestructive) {
        Remove-Item -Path function:deactivate
    }
}

<#
.Description
Get-PyVenvConfig parses the values from the pyvenv.cfg file located in the
given folder, and returns them in a map.

For each line in the pyvenv.cfg file, if that line can be parsed into exactly
two strings separated by `=` (with any amount of whitespace surrounding the =)
then it is considered a `key = value` line. The left hand string is the key,
the right hand is the value.

If the value starts with a `'` or a `"` then the first and last character is
stripped from the value before being captured.

.Parameter ConfigDir
Path to the directory that contains the `pyvenv.cfg` file.
#>
function Get-PyVenvConfig(
    [String]
    $ConfigDir
) {
    Write-Verbose "Given ConfigDir=$ConfigDir, obtain values in pyvenv.cfg"

    # Ensure the file exists, and issue a warning if it doesn't (but still allow the function to continue).
    $pyvenvConfigPath = Join-Path -Resolve -Path $ConfigDir -ChildPath 'pyvenv.cfg' -ErrorAction Continue

    # An empty map will be returned if no config file is found.
    $pyvenvConfig = @{ }

    if ($pyvenvConfigPath) {

        Write-Verbose "File exists, parse `key = value` lines"
        $pyvenvConfigContent = Get-Content -Path $pyvenvConfigPath

        $pyvenvConfigContent | ForEach-Object {
            $keyval = $PSItem -split "\s*=\s*", 2
            if ($keyval[0] -and $keyval[1]) {
                $val = $keyval[1]

                # Remove extraneous quotations around a string value.
                if ("'""".Contains($val.Substring(0, 1))) {
                    $val = $val.Substring(1, $val.Length - 2)
                }

                $pyvenvConfig[$keyval[0]] = $val
                Write-Verbose "Adding Key: '$($keyval[0])'='$val'"
            }
        }
    }
    return $pyvenvConfig
}


<# Begin Activate script --------------------------------------------------- #>

# Determine the containing directory of this script
$VenvExecPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VenvExecDir = Get-Item -Path $VenvExecPath

Write-Verbose "Activation script is located in path: '$VenvExecPath'"
Write-Verbose "VenvExecDir Fullname: '$($VenvExecDir.FullName)"
Write-Verbose "VenvExecDir Name: '$($VenvExecDir.Name)"

# Set values required in priority: CmdLine, ConfigFile, Default
# First, get the location of the virtual environment, it might not be
# VenvExecDir if specified on the command line.
if ($VenvDir) {
    Write-Verbose "VenvDir given as parameter, using '$VenvDir' to determine values"
}
else {
    Write-Verbose "VenvDir not given as a parameter, using parent directory name as VenvDir."
    $VenvDir = $VenvExecDir.Parent.FullName.TrimEnd("\\/")
    Write-Verbose "VenvDir=$VenvDir"
}

# Next, read the `pyvenv.cfg` file to determine any required value such
# as `prompt`.
$pyvenvCfg = Get-PyVenvConfig -ConfigDir $VenvDir

# Next, set the prompt from the command line, or the config file, or
# just use the name of the virtual environment folder.
if ($Prompt) {
    Write-Verbose "Prompt specified as argument, using '$Prompt'"
}
else {
    Write-Verbose "Prompt not specified as argument to script, checking pyvenv.cfg value"
    if ($pyvenvCfg -and $pyvenvCfg['prompt']) {
        Write-Verbose "  Setting based on value in pyvenv.cfg='$($pyvenvCfg['prompt'])'"
        $Prompt = $pyvenvCfg['prompt'];
    }
    else {
        Write-Verbose "  Setting prompt based on parent's directory's name. (Is the directory name passed to venv module when creating the virtual environment)"
        Write-Verbose "  Got leaf-name of $VenvDir='$(Split-Path -Path $venvDir -Leaf)'"
        $Prompt = Split-Path -Path $venvDir -Leaf
    }
}

Write-Verbose "Prompt = '$Prompt'"
Write-Verbose "VenvDir='$VenvDir'"

# Deactivate any currently active virtual environment, but leave the
# deactivate function in place.
deactivate -nondestructive

# Now set the environment variable VIRTUAL_ENV, used by many tools to determine
# that there is an activated venv.
$env:VIRTUAL_ENV = $VenvDir

if (-not $Env:VIRTUAL_ENV_DISABLE_PROMPT) {

    Write-Verbose "Setting prompt to '$Prompt'"

    # Set the prompt to include the env name
    # Make sure _OLD_VIRTUAL_PROMPT is global
    function global:_OLD_VIRTUAL_PROMPT { "" }
    Copy-Item -Path function:prompt -Destination function:_OLD_VIRTUAL_PROMPT
    New-Variable -Name _PYTHON_VENV_PROMPT_PREFIX -Description "Python virtual environment prompt prefix" -Scope Global -Option ReadOnly -Visibility Public -Value $Prompt

    function global:prompt {
        Write-Host -NoNewline -ForegroundColor Green "($_PYTHON_VENV_PROMPT_PREFIX) "
        _OLD_VIRTUAL_PROMPT
    }
    $env:VIRTUAL_ENV_PROMPT = $Prompt
}

# Clear PYTHONHOME
if (Test-Path -Path Env:PYTHONHOME) {
    Copy-Item -Path Env:PYTHONHOME -Destination Env:_OLD_VIRTUAL_PYTHONHOME
    Remove-Item -Path Env:PYTHONHOME
}

# Add the venv to the PATH
Copy-Item -Path Env:PATH -Destination Env:_OLD_VIRTUAL_PATH
$Env:PATH = "$VenvExecDir$([System.IO.Path]::PathSeparator)$Env:PATH"

# SIG # Begin signature block
<<<<<<< HEAD
# MII0BwYJKoZIhvcNAQcCoIIz+DCCM/QCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBALKwKRFIhr2RY
# IW/WJLd9pc8a9sj/IoThKU92fTfKsKCCG9IwggXMMIIDtKADAgECAhBUmNLR1FsZ
=======
# MII0CQYJKoZIhvcNAQcCoIIz+jCCM/YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBnL745ElCYk8vk
# dBtMuQhLeWJ3ZGfzKW4DHCYzAn+QB6CCG9IwggXMMIIDtKADAgECAhBUmNLR1FsZ
>>>>>>> 04c46d2b98c3c0b212dcba6d9e0f886d36e15bb3
# lUgTecgRwIeZMA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVu
# dGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAy
# MDAeFw0yMDA0MTYxODM2MTZaFw00NTA0MTYxODQ0NDBaMHcxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jv
# c29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALORKgeD
# Bmf9np3gx8C3pOZCBH8Ppttf+9Va10Wg+3cL8IDzpm1aTXlT2KCGhFdFIMeiVPvH
# or+Kx24186IVxC9O40qFlkkN/76Z2BT2vCcH7kKbK/ULkgbk/WkTZaiRcvKYhOuD
# PQ7k13ESSCHLDe32R0m3m/nJxxe2hE//uKya13NnSYXjhr03QNAlhtTetcJtYmrV
# qXi8LW9J+eVsFBT9FMfTZRY33stuvF4pjf1imxUs1gXmuYkyM6Nix9fWUmcIxC70
# ViueC4fM7Ke0pqrrBc0ZV6U6CwQnHJFnni1iLS8evtrAIMsEGcoz+4m+mOJyoHI1
# vnnhnINv5G0Xb5DzPQCGdTiO0OBJmrvb0/gwytVXiGhNctO/bX9x2P29Da6SZEi3
# W295JrXNm5UhhNHvDzI9e1eM80UHTHzgXhgONXaLbZ7LNnSrBfjgc10yVpRnlyUK
# xjU9lJfnwUSLgP3B+PR0GeUw9gb7IVc+BhyLaxWGJ0l7gpPKWeh1R+g/OPTHU3mg
# trTiXFHvvV84wRPmeAyVWi7FQFkozA8kwOy6CXcjmTimthzax7ogttc32H83rwjj
# O3HbbnMbfZlysOSGM1l0tRYAe1BtxoYT2v3EOYI9JACaYNq6lMAFUSw0rFCZE4e7
# swWAsk0wAly4JoNdtGNz764jlU9gKL431VulAgMBAAGjVDBSMA4GA1UdDwEB/wQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTIftJqhSobyhmYBAcnz1AQ
# T2ioojAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQwFAAOCAgEAr2rd5hnn
# LZRDGU7L6VCVZKUDkQKL4jaAOxWiUsIWGbZqWl10QzD0m/9gdAmxIR6QFm3FJI9c
# Zohj9E/MffISTEAQiwGf2qnIrvKVG8+dBetJPnSgaFvlVixlHIJ+U9pW2UYXeZJF
# xBA2CFIpF8svpvJ+1Gkkih6PsHMNzBxKq7Kq7aeRYwFkIqgyuH4yKLNncy2RtNwx
# AQv3Rwqm8ddK7VZgxCwIo3tAsLx0J1KH1r6I3TeKiW5niB31yV2g/rarOoDXGpc8
# FzYiQR6sTdWD5jw4vU8w6VSp07YEwzJ2YbuwGMUrGLPAgNW3lbBeUU0i/OxYqujY
# lLSlLu2S3ucYfCFX3VVj979tzR/SpncocMfiWzpbCNJbTsgAlrPhgzavhgplXHT2
# 6ux6anSg8Evu75SjrFDyh+3XOjCDyft9V77l4/hByuVkrrOj7FjshZrM77nq81YY
# uVxzmq/FdxeDWds3GhhyVKVB0rYjdaNDmuV3fJZ5t0GNv+zcgKCf0Xd1WF81E+Al
# GmcLfc4l+gcK5GEh2NQc5QfGNpn0ltDGFf5Ozdeui53bFv0ExpK91IjmqaOqu/dk
# ODtfzAzQNb50GQOmxapMomE2gj4d8yu8l13bS3g7LfU772Aj6PXsCyM2la+YZr9T
<<<<<<< HEAD
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggb+MIIE5qADAgECAhMzAAKlFFgo
# 8MZcu1p7AAAAAqUUMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDIwHhcNMjUwMjA0MDQzOTE4WhcNMjUwMjA3
# MDQzOTE4WjB8MQswCQYDVQQGEwJVUzEPMA0GA1UECBMGT3JlZ29uMRIwEAYDVQQH
# EwlCZWF2ZXJ0b24xIzAhBgNVBAoTGlB5dGhvbiBTb2Z0d2FyZSBGb3VuZGF0aW9u
# MSMwIQYDVQQDExpQeXRob24gU29mdHdhcmUgRm91bmRhdGlvbjCCAaIwDQYJKoZI
# hvcNAQEBBQADggGPADCCAYoCggGBAM0+8Om1I2jOLEAcjJV18w+wi9VDTfS8oEaX
# kaAFVx5RpBFMUQl8rALAnyXgfRjSO4ACoyvo7v9tCNYtEzc/7eT01z/pVf/WHGw1
# iccrUMIx6nS+yWR998L9lZfBQPpyAziTWcRrnt+C1hRDb/7GqLjL6xujXhI6VWwu
# P7OGA9DcbeCGiA9LgH7C0iMxLsVcro7WG+Zbv3bFnW6bBCvjJhzsy134ZKL5WJpV
# IF8U6OHGFr612DuFZN5qX9qU/S4qibpxf4VFvm0YLPIQfvNPNYVbLGZ1fnOrglPD
# 7yoEFnNvjIF4eGlKhdaVGEOajCY6qTEyntqrDw3FkoebbSPZsO6jgTeRgikQFM4A
# eKtQ21+0ISd4yQS1qZBa6k1yGjgfv0q0MF2tLO/wDyC4JMZLBITFDOfLo1aFMFXL
# ZipHTsq21g/VlSHCQ3n+uI3F3XqtT6en5qeAMeLcJ0NflERYTn1auNghCYyDlzeV
# s9n42/3t87X17w3cHi/GUZlu+dmSiQIDAQABo4ICGTCCAhUwDAYDVR0TAQH/BAIw
# ADAOBgNVHQ8BAf8EBAMCB4AwPAYDVR0lBDUwMwYKKwYBBAGCN2EBAAYIKwYBBQUH
# AwMGGysGAQQBgjdhgqKNuwqmkohkgZH0oEWCk/3hbzAdBgNVHQ4EFgQUHg/yH95s
# crpDPlCqvm1yj6v7twwwHwYDVR0jBBgwFoAUJEWZoXeQKnzDyoOwbmQWhCr4LGcw
# ZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmllZCUyMENTJTIwQU9DJTIwQ0El
# MjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQGCCsGAQUFBzAChlhodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIw
# VmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDIuY3J0MC0GCCsGAQUFBzABhiFo
# dHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29jc3AwZgYDVR0gBF8wXTBRBgwr
# BgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMAgGBmeBDAEEATANBgkqhkiG
# 9w0BAQwFAAOCAgEAbKNGvVBi7AmP6/ArF3MEiLOizuTKcVxI9LfwZtPn0cFUaTdi
# pOrR8aROpTJtx0QMywVXEadCYbsopJSASdVCbTH+3Q65Q4ZU69phlIDwskPGl0fo
# nWjz4iU+BMaGevmlQRmPBfBUshKlb5cVz6BqXpql7dK+M8LPNHw0szLUqzMqFt/Z
# rdTdOLoabWE70/TQqEbLddoB0+osgL+4evhv6S000yanBf5tZVctd8AGQEzo/hKj
# LOBb55PwWxh5Nmz8Q8uAhU1Z+s1i7AP53zzUeaY4iwAvvXDD6f/J3MCJrA2pGwCf
# XxNCuf0cMB/+5Q998/guVhQzRIyukmgtVjWvETEA6bXo69W1r6PnG3I9bqj1kkCB
# 3Qifl/OGO4GlsLxTxxQKe6UmDDcER8YwB9+VtEIWBBT1MdBGLgc0NekxSgICsTzG
# BOa8QMozV8oelupdJ8k64OzvrWAZF5aGOquA74T1Tj+xoJz53I4nhwCPwYv60hND
# bPRUhmDyyDcGzEAAUDrDbWq8DjYKg+H/JJtNcpW86+iHBmBHAmdA3I/AhklyaKYK
# q7bInqFNYbWGLWHCSAOWhSC4sq4FCq/Bh1vaMVOKonJOeATFD+ID2FH/7287sT8y
# Pa71vDq1y1ctW/MbZ5s4N2ZarC1VVTBQ2ySKYfDlUYcx/U1crt/noma4Urcwggda
# MIIFQqADAgECAhMzAAAABJZQS9Lb7suIAAAAAAAEMA0GCSqGSIb3DQEBDAUAMGMx
# CzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xNDAy
# BgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBDb2RlIFNpZ25pbmcgUENBIDIw
# MjEwHhcNMjEwNDEzMTczMTUyWhcNMjYwNDEzMTczMTUyWjBaMQswCQYDVQQGEwJV
# UzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSswKQYDVQQDEyJNaWNy
# b3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAyMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA4c6g6DOiY6bAOwCPbBlQF2tjo3ckUZuab5ZorMnRp4rO
# mwZDiTbIpzFkZ/k8k4ivBJV1w5/b/oykI+eXAqaaxMdyAO0ModnEW7InfQ+rTkyk
# EzHxRbCNg6KDsTnYc/YdL7IIiJli8k51upaHLL7CYm9YNc0SFYvlaFj2O0HjO9y/
# NRmcWNjamZOlRjxW2cWgUsUdazSHgRCek87V2bM/17b+o8WXUW91IpggRasmiZ65
# WEFHXKbyhm2LbhBK6ZWmQoFeE+GWrKWCGK/q/4RiTaMNhHXWvWv+//I58UtOxVi3
# DaK1fQ6YLyIIGHzD4CmtcrGivxupq/crrHunGNB7//Qmul2ZP9HcOmY/aptgUnwT
# +20g/A37iDfuuVw6yS2Lo0/kp/jb+J8vE4FMqIiwxGByL482PMVBC3qd/NbFQa8M
# mj6ensU+HEqv9ar+AbcKwumbZqJJKmQrGaSNdWfk2NodgcWOmq7jyhbxwZOjnLj0
# /bwnsUNcNAe09v+qiozyQQes8A3UXPcRQb8G+c0yaO2ICifWTK7ySuyUJ88k1mtN
# 22CNftbjitiAeafoZ9Vmhn5Rfb+S/K5arVvTcLukt5PdTDQxl557EIE6A+6XFBpd
# sjOzkLzdEh7ELk8PVPMjQfPCgKtJ84c17fd2C9+pxF1lEQUFXY/YtCL+Nms9cWUC
# AwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADAd
# BgNVHQ4EFgQUJEWZoXeQKnzDyoOwbmQWhCr4LGcwVAYDVR0gBE0wSzBJBgRVHSAA
=======
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggb+MIIE5qADAgECAhMzAAM/y2Wy
# WWnFfpZcAAAAAz/LMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDEwHhcNMjUwNDA4MDEwNzI0WhcNMjUwNDEx
# MDEwNzI0WjB8MQswCQYDVQQGEwJVUzEPMA0GA1UECBMGT3JlZ29uMRIwEAYDVQQH
# EwlCZWF2ZXJ0b24xIzAhBgNVBAoTGlB5dGhvbiBTb2Z0d2FyZSBGb3VuZGF0aW9u
# MSMwIQYDVQQDExpQeXRob24gU29mdHdhcmUgRm91bmRhdGlvbjCCAaIwDQYJKoZI
# hvcNAQEBBQADggGPADCCAYoCggGBAI0elXEcbTdGLOszMU2fzimHGM9Y4EjwFgC2
# iGPdieHc0dK1DyEIdtnvjKxnG/KICC3J2MrhePGzMEkie3yQjx05B5leG0q8YoGU
# m9z9K67V6k3DSXX0vQe9FbaNVuyXed31MEf/qek7Zo4ELxu8n/LO3ibURBLRHNoW
# Dz9zr4DcU+hha0bdIL6SnKMLwHqRj59gtFFEPqXcOVO7kobkzQS3O1T5KNL/zGuW
# UGQln7fS4YI9bj24bfrSeG/QzLgChVYScxnUgjAANfT1+SnSxrT4/esMtfbcvfID
# BIvOWk+FPPj9IQWsAMEG/LLG4cF/pQ/TozUXKx362GJBbe6paTM/RCUTcffd83h2
# bXo9vXO/roZYk6H0ecd2h2FFzLUQn/0i4RQQSOp6zt1eDf28h6F8ev+YYKcChph8
# iRt32bJPcLQVbUzhehzT4C0pz6oAqPz8s0BGvlj1G6r4CY1Cs2YiMU09/Fl64pWf
# IsA/ReaYj6yNsgQZNUcvzobK2mTxMwIDAQABo4ICGTCCAhUwDAYDVR0TAQH/BAIw
# ADAOBgNVHQ8BAf8EBAMCB4AwPAYDVR0lBDUwMwYKKwYBBAGCN2EBAAYIKwYBBQUH
# AwMGGysGAQQBgjdhgqKNuwqmkohkgZH0oEWCk/3hbzAdBgNVHQ4EFgQU4Y4Xr/Xn
# zEXblXrNC0ZLdaPEJYUwHwYDVR0jBBgwFoAU6IPEM9fcnwycdpoKptTfh6ZeWO4w
# ZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmllZCUyMENTJTIwQU9DJTIwQ0El
# MjAwMS5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQGCCsGAQUFBzAChlhodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIw
# VmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDEuY3J0MC0GCCsGAQUFBzABhiFo
# dHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29jc3AwZgYDVR0gBF8wXTBRBgwr
# BgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMAgGBmeBDAEEATANBgkqhkiG
# 9w0BAQwFAAOCAgEAKTeVGPXsDKqQLe1OuKx6K6q711FPxNQyLOOqeenH8zybHwNo
# k05cMk39HQ7u+R9BQIL0bWexb7wa3XeKaX06p7aY/OQs+ycvUi/fC6RGlaLWmQ9D
# YhZn2TBz5znimvSf3P+aidCuXeDU5c8GpBFog6fjEa/k+n7TILi0spuYZ4yC9R48
# R63/VvpLi2SqxfJbx5n92bY6driNzAntjoravF25BSejXVrdzefbnqbQnZPB39g8
# XHygGPb0912fIuNKPLQa/uCnmYdXJnPb0ZgMxxA8fyxvL2Q30Qf5xpFDssPDElvD
# DoAbvR24CWvuHbu+CMMr2SJUpX4RRvDioO7JeB6wZb+64MXyPUSSf6QwkKNsHPIa
# e9tSfREh86sYn5bOA0Wd+Igk0RpA5jDRTu3GgPOPWbm1PU+VoeqThtHt6R3l17pr
# aQ5wIuuLXgxi1K4ZWgtvXw8BtIXfZz24qCtoo0+3kEGUpEHBgkF1SClbRb8uAzx+
# 0ROGniLPJRU20Xfn7CgipeKLcNn33JPFwQHk1zpbGS0090mi0erOQCz0S47YdHmm
# RJcbkNIL9DeNAglTZ/TFxrYUM1NRS1Cp4e63MgBKcWh9VJNokInzzmS+bofZz+u1
# mm8YNtiJjdT8fmizXdUEk68EXQhOs0+HBNvc9nMRK6R28MZu/J+PaUcPL84wggda
# MIIFQqADAgECAhMzAAAABzeMW6HZW4zUAAAAAAAHMA0GCSqGSIb3DQEBDAUAMGMx
# CzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xNDAy
# BgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBDb2RlIFNpZ25pbmcgUENBIDIw
# MjEwHhcNMjEwNDEzMTczMTU0WhcNMjYwNDEzMTczMTU0WjBaMQswCQYDVQQGEwJV
# UzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSswKQYDVQQDEyJNaWNy
# b3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAxMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAt/fAAygHxbo+jxA04hNI8bz+EqbWvSu9dRgAawjCZau1
# Y54IQal5ArpJWi8cIj0WA+mpwix8iTRguq9JELZvTMo2Z1U6AtE1Tn3mvq3mywZ9
# SexVd+rPOTr+uda6GVgwLA80LhRf82AvrSwxmZpCH/laT08dn7+Gt0cXYVNKJORm
# 1hSrAjjDQiZ1Jiq/SqiDoHN6PGmT5hXKs22E79MeFWYB4y0UlNqW0Z2LPNua8k0r
# bERdiNS+nTP/xsESZUnrbmyXZaHvcyEKYK85WBz3Sr6Et8Vlbdid/pjBpcHI+Hyt
# oaUAGE6rSWqmh7/aEZeDDUkz9uMKOGasIgYnenUk5E0b2U//bQqDv3qdhj9UJYWA
# DNYC/3i3ixcW1VELaU+wTqXTxLAFelCi/lRHSjaWipDeE/TbBb0zTCiLnc9nmOjZ
# PKlutMNho91wxo4itcJoIk2bPot9t+AV+UwNaDRIbcEaQaBycl9pcYwWmf0bJ4IF
# n/CmYMVG1ekCBxByyRNkFkHmuMXLX6PMXcveE46jMr9syC3M8JHRddR4zVjd/FxB
# nS5HOro3pg6StuEPshrp7I/Kk1cTG8yOWl8aqf6OJeAVyG4lyJ9V+ZxClYmaU5yv
# tKYKk1FLBnEBfDWw+UAzQV0vcLp6AVx2Fc8n0vpoyudr3SwZmckJuz7R+S79BzMC
# AwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADAd
# BgNVHQ4EFgQU6IPEM9fcnwycdpoKptTfh6ZeWO4wVAYDVR0gBE0wSzBJBgRVHSAA
>>>>>>> 04c46d2b98c3c0b212dcba6d9e0f886d36e15bb3
# MEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# RG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAS
# BgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaAFNlBKbAPD2Ns72nX9c0pnqRI
# ajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDb2RlJTIwU2ln
# bmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEFBQcBAQSBoTCBnjBtBggrBgEF
# BQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNy
# b3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUyMFNpZ25pbmclMjBQQ0ElMjAy
# MDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29uZW9jc3AubWljcm9zb2Z0LmNv
<<<<<<< HEAD
# bS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQBnLThdlbMNIokdKtzSa8io+pEO95Cc
# 3VOyY/hQsIIcdMyk2hJOzLt/M1WXfQyElDk/QtyLzX63TdOb5J+nO8t0pzzwi7ZY
# vMiNqKvAQO50sMOJn3T3hCPppxNNhoGFVxz2UyiQ4b2vOrcsLK9TOEFXWbUMJObR
# 9PM0wZsABIhu4k6VVLxEDe0GSeQX/ZE7PHfTg44Luft4IKqYmnv1Cuosp3glFYsV
# egLnMWZUZ8UtO9F8QCiAouJYhL5OlCksgDb9ve/HQhLFnelfg6dQubIFsqB9IlCo
# nYKJZ/HaMZvYtA7y9EORK4cxlvTetCXAHayiSXH0ueE/T92wVG0csv5VdUyj6yVr
# m22vlKYAkXINKvDOB8+s4h+TgShlUa2ACu2FWn7JzlTSbpk0IE8REuYmkuyE/BTk
# k93WDMx7PwLnn4J+5fkvbjjQ08OewfpMhh8SuPdQKqmZ40I4W2UyJKMMTbet16JF
# imSqDChgnCB6lwlpe0gfbo97U7prpbfBKp6B2k2f7Y+TjWrQYN+OdcPOyQAdxGGP
# BwJSaJG3ohdklCxgAJ5anCxeYl7SjQ5Eua6atjIeVhN0KfPLFPpYz5CQU+JC2H79
# x4d/O6YOFR9aYe54/CGup7dRUIfLSv1/j0DPc6Elf3YyWxloWj8yeY3kHrZFaAlR
# MwhAXyPQ3rEX9zCCB54wggWGoAMCAQICEzMAAAAHh6M0o3uljhwAAAAAAAcwDQYJ
=======
# bS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQB3/utLItkwLTp4Nfh99vrbpSsL8NwP
# Ij2+TBnZGL3C8etTGYs+HZUxNG+rNeZa+Rzu9oEcAZJDiGjEWytzMavD6Bih3nEW
# FsIW4aGh4gB4n/pRPeeVrK4i1LG7jJ3kPLRhNOHZiLUQtmrF4V6IxtUFjvBnijaZ
# 9oIxsSSQP8iHMjP92pjQrHBFWHGDbkmx+yO6Ian3QN3YmbdfewzSvnQmKbkiTibJ
# gcJ1L0TZ7BwmsDvm+0XRsPOfFgnzhLVqZdEyWww10bflOeBKqkb3SaCNQTz8nsha
# UZhrxVU5qNgYjaaDQQm+P2SEpBF7RolEC3lllfuL4AOGCtoNdPOWrx9vBZTXAVdT
# E2r0IDk8+5y1kLGTLKzmNFn6kVCc5BddM7xoDWQ4aUoCRXcsBeRhsclk7kVXP+zJ
# GPOXwjUJbnz2Kt9iF/8B6FDO4blGuGrogMpyXkuwCC2Z4XcfyMjPDhqZYAPGGTUI
# NMtFbau5RtGG1DOWE9edCahtuPMDgByfPixvhy3sn7zUHgIC/YsOTMxVuMQi/bga
# memo/VNKZrsZaS0nzmOxKpg9qDefj5fJ9gIHXcp2F0OHcVwe3KnEXa8kqzMDfrRl
# /wwKrNSFn3p7g0b44Ad1ONDmWt61MLQvF54LG62i6ffhTCeoFT9Z9pbUo2gxlyTF
# g7Bm0fgOlnRfGDCCB54wggWGoAMCAQICEzMAAAAHh6M0o3uljhwAAAAAAAcwDQYJ
>>>>>>> 04c46d2b98c3c0b212dcba6d9e0f886d36e15bb3
# KoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5IFZlcmlmaWNh
# dGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4XDTIxMDQwMTIw
# MDUyMFoXDTM2MDQwMTIwMTUyMFowYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZlcmlm
# aWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBALLwwK8ZiCji3VR6TElsaQhVCbRS/3pK+MHrJSj3Zxd3KU3rlfL3
# qrZilYKJNqztA9OQacr1AwoNcHbKBLbsQAhBnIB34zxf52bDpIO3NJlfIaTE/xrw
# eLoQ71lzCHkD7A4As1Bs076Iu+mA6cQzsYYH/Cbl1icwQ6C65rU4V9NQhNUwgrx9
# rGQ//h890Q8JdjLLw0nV+ayQ2Fbkd242o9kH82RZsH3HEyqjAB5a8+Ae2nPIPc8s
# ZU6ZE7iRrRZywRmrKDp5+TcmJX9MRff241UaOBs4NmHOyke8oU1TYrkxh+YeHgfW
# o5tTgkoSMoayqoDpHOLJs+qG8Tvh8SnifW2Jj3+ii11TS8/FGngEaNAWrbyfNrC6
# 9oKpRQXY9bGH6jn9NEJv9weFxhTwyvx9OJLXmRGbAUXN1U9nf4lXezky6Uh/cgjk
# Vd6CGUAf0K+Jw+GE/5VpIVbcNr9rNE50Sbmy/4RTCEGvOq3GhjITbCa4crCzTTHg
# YYjHs1NbOc6brH+eKpWLtr+bGecy9CrwQyx7S/BfYJ+ozst7+yZtG2wR461uckFu
# 0t+gCwLdN0A6cFtSRtR8bvxVFyWwTtgMMFRuBa3vmUOTnfKLsLefRaQcVTgRnzeL
# zdpt32cdYKp+dhr2ogc+qM6K4CBI5/j4VFyC4QFeUP2YAidLtvpXRRo3AgMBAAGj
# ggI1MIICMTAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0O
# BBYEFNlBKbAPD2Ns72nX9c0pnqRIajDmMFQGA1UdIARNMEswSQYEVR0gADBBMD8G
# CCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
# UmVwb3NpdG9yeS5odG0wGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwDwYDVR0T
# AQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSobyhmYBAcnz1AQT2ioojCBhAYD
# VR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJpZmljYXRpb24lMjBSb290JTIw
# Q2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIwLmNybDCBwwYIKwYBBQUHAQEE
# gbYwgbMwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIw
# Um9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcnQwLQYIKwYB
# BQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1pY3Jvc29mdC5jb20vb2NzcDANBgkqhkiG
# 9w0BAQwFAAOCAgEAfyUqnv7Uq+rdZgrbVyNMul5skONbhls5fccPlmIbzi+OwVdP
# Q4H55v7VOInnmezQEeW4LqK0wja+fBznANbXLB0KrdMCbHQpbLvG6UA/Xv2pfpVI
# E1CRFfNF4XKO8XYEa3oW8oVH+KZHgIQRIwAbyFKQ9iyj4aOWeAzwk+f9E5StNp5T
# 8FG7/VEURIVWArbAzPt9ThVN3w1fAZkF7+YU9kbq1bCR2YD+MtunSQ1Rft6XG7b4
# e0ejRA7mB2IoX5hNh3UEauY0byxNRG+fT2MCEhQl9g2i2fs6VOG19CNep7SquKaB
# jhWmirYyANb0RJSLWjinMLXNOAga10n8i9jqeprzSMU5ODmrMCJE12xS/NWShg/t
# uLjAsKP6SzYZ+1Ry358ZTFcx0FS/mx2vSoU8s8HRvy+rnXqyUJ9HBqS0DErVLjQw
# K8VtsBdekBmdTbQVoCgPCqr+PDPB3xajYnzevs7eidBsM71PINK2BoE2UfMwxCCX
# 3mccFgx6UsQeRSdVVVNSyALQe6PT12418xon2iDGE81OGCreLzDcMAZnrUAx4XQL
# Uz6ZTl65yPUiOh3k7Yww94lDf+8oG2oZmDh5O1Qe38E+M3vhKwmzIeoB1dVLlz4i
<<<<<<< HEAD
# 3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4DT2uhJ04ji+tHD6n58vhavFIrmcxgheL
# MIIXhwIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBBT0Mg
# Q0EgMDICEzMAAqUUWCjwxly7WnsAAAACpRQwDQYJYIZIAWUDBAIBBQCggcgwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEICpXe3RS3b2coD0CJveEHlglqtPUYZ2FqSrO
# UfP6C6Y4MFwGCisGAQQBgjcCAQwxTjBMoEaARABCAHUAaQBsAHQAOgAgAFIAZQBs
# AGUAYQBzAGUAXwB2ADMALgAxADMALgAyAF8AMgAwADIANQAwADIAMAA0AC4AMAAx
# oQKAADANBgkqhkiG9w0BAQEFAASCAYCPj4herupzAUBE52C7eFs2h6dKXOeZJ9zi
# 6ck4qwWgN7i6tR9S8+BRsVkzo+gbyc45/D0DKtq6GVHVBC7LnxVNn/FUCWko8qNV
# m22kt9K2YXab34WHPpbB6yOSTSpTNrhqll/dPmkcVxzilb68qDk/QlYgHyWK8RcW
# iq1OhzZXeTj9M1F65a+UyCVj2/ZUXApjvU08gKfVEHFWWF2p2QbvnO3/VYZkVo+L
# TJ4P7zuMPdF6bNS1ukgZrbvhf8Qn+OTaE6UrDklRP54yknSaQKL7qoRP4jPT7R1/
# DuGZ6dN0FmX+XOre5qlH78NAy/SPMz4YXGRikqlyj5EC1ZAgI2YW7xqgJlKXatDQ
# YxkZxaH3qLPOoH3IRmQE+Eq1qF2HJQpZfzPXcL6Tt3Btk74YROnQBCCS6k8yrVV+
# zdTSx1a5vJ1+woRN3MQo4TVxPc5Nlmrjg5f9Hgt8+Ij21vK6JYeg7Q7X5DKITvX4
# vS0bTghb2a/T5+GlJtBy4NflT3vPTD+hghSgMIIUnAYKKwYBBAGCNwMDATGCFIww
# ghSIBgkqhkiG9w0BBwKgghR5MIIUdQIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBYQYL
# KoZIhvcNAQkQAQSgggFQBIIBTDCCAUgCAQEGCisGAQQBhFkKAwEwMTANBglghkgB
# ZQMEAgEFAAQg8ai6AGFvVnqzsLdxANmZV8nKleKlAhmr7yueFQnfvocCBmebw28m
# YhgTMjAyNTAyMDQxNjM1NDYuNDU1WjAEgAIB9KCB4KSB3TCB2jELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTQ2Mi05
# NkYwLTQ0MkUxNTAzBgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3Rh
# bXBpbmcgQXV0aG9yaXR5oIIPIDCCB4IwggVqoAMCAQICEzMAAAAF5c8P/2YuyYcA
# AAAAAAUwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5
# IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4X
# DTIwMTExOTIwMzIzMVoXDTM1MTExOTIwNDIzMVowYTELMAkGA1UEBhMCVVMxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCefOdSY/3gxZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eR
# wV1wb3+yq0OXDEqhUhxqoNv6iYWKjkMcLhEFxvJAeNcLAyT+XdM5i2CgGPGcb95W
# JLiw7HzLiBKrxmDj1EQB/mG5eEiRBEp7dDGzxKCnTYocDOcRr9KxqHydajmEkzXH
# OeRGwU+7qt8Md5l4bVZrXAhK+WSk5CihNQsWbzT1nRliVDwunuLkX1hyIWXIArCf
# rKM3+RHh+Sq5RZ8aYyik2r8HxT+l2hmRllBvE2Wok6IEaAJanHr24qoqFM9WLeBU
# Sudz+qL51HwDYyIDPSQ3SeHtKog0ZubDk4hELQSxnfVYXdTGncaBnB60QrEuazvc
# ob9n4yR65pUNBCF5qeA4QwYnilBkfnmeAjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8
# YBozrEaXnsSL3kdTD01X+4LfIWOuFzTzuoslBrBILfHNj8RfOxPgjuwNvE6YzauX
# i4orp4Sm6tF245DaFOSYbWFK5ZgG6cUY2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv3
# 5Nf6xN6FrA6jF9447+NHvCjeWLCQZ3M8lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr
# 3D9RPHCMS6Ckg8wggTrtIVnY8yjbvGOUsAdZbeXUIQAWMs0d3cRDv09SvwVRd61e
# vQIDAQABo4ICGzCCAhcwDgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEA
# MB0GA1UdDgQWBBRraSg6NS9IY0DPe9ivSek+2T3bITBUBgNVHSAETTBLMEkGBFUd
# IAAwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsG
# AQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgw
# FoAUyH7SaoUqG8oZmAQHJ89QEE9oqKIwgYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElkZW50
# aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9y
# aXR5JTIwMjAyMC5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQl
# MjBJZGVudGl0eSUyMFZlcmlmaWNhdGlvbiUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUy
# MEF1dGhvcml0eSUyMDIwMjAuY3J0MA0GCSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21
# WhV150x4aPpO4dhEmSUVpbixNDmv6TvuIHv1xIs174bNGO/ilWMm+Jx5boAXrJxa
# gRhHQtiFprSjMktTliL4sKZyt2i+SXncM23gRezzsoOiBhv14YSd1Klnlkzvgs29
# XNjT+c8hIfPRe9rvVCMPiH7zPZcw5nNjthDQ+zD563I1nUJ6y59TbXWsuyUsqw7w
# XZoGzZwijWT5oc6GvD3HDokJY401uhnj3ubBhbkR83RbfMvmzdp3he2bvIUztSOu
# FzRqrLfEvsPkVHYnvH1wtYyrt5vShiKheGpXa2AWpsod4OJyT4/y0dggWi8g/tgb
# hmQlZqDUf3UqUQsZaLdIu/XSjgoZqDjamzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPS
# wym0Ukr4o5sCcMUcSy6TEP7uMV8RX0eH/4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2
# IWG+7zyjTDfkmQ1snFOTgyEX8qBpefQbF0fx6URrYiarjmBprwP6ZObwtZXJ23jK
# 3Fg/9uqM3j0P01nzVygTppBabzxPAh/hHhhls6kwo3QLJ6No803jUsZcd4JQxiYH
# Hc+Q/wAMcPUnYKv/q2O444LO1+n6j01z5mggCSlRwD9faBIySAcA9S8h22hIAcRQ
# qIGEjolCK9F6nK9ZyX4lhthsGHumaABdWzCCB5YwggV+oAMCAQICEzMAAABK/bhV
# x2KqyYkAAAAAAEowDQYJKoZIhvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1
# YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjAwHhcNMjQxMTI2MTg0ODU1WhcN
# MjUxMTE5MTg0ODU1WjCB2jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEmMCQG
# A1UECxMdVGhhbGVzIFRTUyBFU046RTQ2Mi05NkYwLTQ0MkUxNTAzBgNVBAMTLE1p
# Y3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5MIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA6DkQYZ6zYlw1AbxFkFNwc0V0BaXC
# Co1/+d01YKizalK9bX8fGrIUSVf75pYJOrhYmofIMh7wBv8j+kIplOKYixrtVq+a
# QwAezI0wBFdFFeOyNCIynTQwz343z5IWVZ0/7cOXT1IDk9fIsI51kZKHa4SPf9rF
# mH9XtH1/P1ExueAGskBF/AvI1Ol2Vv2W9EDke8csxcPgXTkDNG9I5ljEjM9pZUzf
# 9kgw8Po8CVpD1/OFb468jcaWpsi/ydqboa3KJnPoyUlnq+cmgp6fkpqYmPM3EhAr
# 1aAqbMnkiUrD4Q15DTv0XoZOi1zjXRhF5xxXKLr1m5k5xZlHp7mnPimiG67T7/e5
# DuFFt7XbAsOCW8N1Zq5jdNeLrMLtBvkRyKlkTSsp6nJQXR4Rf2e87TrveQiJjLsW
# +ZQ46KXdcDI1WoaxI0JzypicOQBbcU98823p/TArYdVpIYuYlXq0923cf9+im62B
# VFG9eXhm+601RsXdWlH7QUMZzbD233aAP8LiB0pDrkK/ybUpYs6DokAJ9r0am4NF
# Xu7LC+DfIFveRIZOCBaHGt4SJ3G2VgkFIoALFcThj+ro7oX+BT3sr0L57Lzi/QmU
# 2UkTCwV1qKM6+aqbzhV4BxsxRjfQdetqzFvxI4IHf0IBuPoYYMiJ4AXTa2moymfu
# ejK2NZgL75mWwisCAwEAAaOCAcswggHHMB0GA1UdDgQWBBQXdNaJti4We46ErU/T
# NnIOeWGVejAfBgNVHSMEGDAWgBRraSg6NS9IY0DPe9ivSek+2T3bITBsBgNVHR8E
# ZTBjMGGgX6BdhltodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9N
# aWNyb3NvZnQlMjBQdWJsaWMlMjBSU0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIw
# MjAuY3JsMHkGCCsGAQUFBwEBBG0wazBpBggrBgEFBQcwAoZdaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBQdWJsaWMlMjBS
# U0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIwMjAuY3J0MAwGA1UdEwEB/wQCMAAw
# FgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQDAgeAMGYGA1UdIARf
# MF0wUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAIBgZngQwBBAIw
# DQYJKoZIhvcNAQEMBQADggIBADApzTDXWbyj/r85v6Az19sJPtwKdE5ukA0FrPxJ
# ffIDQ0WJLW1G7zXIXIJY3S5dCHbvXr5bDrmL67MlnU0M0RIapm5xpS8ejuWdRplH
# qkRiwhB5hm+7nEdxm+YdKCcoIPxbGqI1t8E0S0Zt7uw1/9LzRUarduTHQ0PKyZQn
# uYkHLGx83/+RR40w1gemiIFtC/UfvNY9URHCfB6bWp90qi3TjWLMO03FwcpuvZ15
# RubMVH/eH3WavJjLB4rDWd7NzeSAkiTqCEUAFNqrGFbnjOviBMUbKkAa/mFj9m1D
# k6Zx4SbXtT5wCodX3k30m0cSB2nClULbR4YyWO5/MoSlTwnMPvFXMOWUkzd/SARb
# w7XVF6WLtgZHVBKAyZ4MFKwrKCP8hXdozdkeOX3Ru12+wewRk8Ano/f9zrm4G/B/
# wO6u7smB3eR8OerqioPt73ufFMWsSCwXhSGz8xpjq6DKiG39sDRPF2CHnsBIJmv7
# dPMgYCKxskb7GiIkHbqa79vIAqQs9nY4s7XhR8NKRAKVIYj9/8XkeY5S1G0YQhCw
# QlRUtvHZMY0pYmOXBfWpjQG+ZaIwfd07tB0hprJBh5zJLIussfsIP3tGr4o64tqR
# a8+OItP3mLWCdslKcBY5HIzHC2b0NnasAY1bqzfTfotsflhrV+pXSyN3As36dKMT
# qpGGMYID1DCCA9ACAQEweDBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBU
# aW1lc3RhbXBpbmcgQ0EgMjAyMAITMwAAAEr9uFXHYqrJiQAAAAAASjANBglghkgB
# ZQMEAgEFAKCCAS0wGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3
# DQEJBDEiBCAMyT4mvyAv7GV8s5QY2US1E/TcXy2hIqp1nkQphkbfmjCB3QYLKoZI
# hvcNAQkQAi8xgc0wgcowgccwgaAEIGZ7KbWlzY0AQkdLdW/gAxiyl7PEf9Wpsv+x
# de8uw+EKMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAASv24VcdiqsmJAAAAAABKMCIEIBmGpH4uivN8
# AnEjrbX0572hbxxUOiKHuioQW9FVeHwGMA0GCSqGSIb3DQEBCwUABIICAGPMANAQ
# vohEYnZViRq+KKmikfVI4d5MvmBRjO7z2ZN1upkNeJX4/im3R0mhfmAcU/kudNwU
# WAQM5seYEyAK6z93scr1mrGHbS0zBzilK5xEnyM7gEa4RnlkUCMY19uRHHI53B5D
# cW4k/DK2WjNel8K8Akbmqx8fJYK9c/dFzBDeHx2sxbkZE1HOMEisp/bEcC23rjxW
# SpjQaXbRP1ASeaYHLPIb2BSmgltn7r9Rg6bkj6/DCPNhvMwiYu+8YX5c9IBkMOYV
# cO67Fxt2B+En4klZIbcmLqkqj8xsLlh7VZu8fAE8lNJmAX5qbb52DMopAE9Pzhvm
# bsPKaPyX27HVURVY2otp70BchVAAn7pOm7/YTelC71RZZKDOH2KNXrLsjGHfLyWi
# QXqV8YfzlQyh3uJMFhymOZ8hoRQDdlbbuZk93HkGDhL0Ms8ZwSVmEHM5G04rnMpV
# OLqe9/BOyFRIY/6ooC1nreZpsHzuBQPc6EUpYYF6iEy+xVqWGfGBdspx0jAeAXmi
# JXpq03Uik5Uh9bT5pVdWuSXK5w4Gph5QZ5fbSyjycImaxXJNGH+sXgeKCAm0C4Mk
# 9FfM0CFyZlO1mIX9awNl3im6t67LANWY541my0/G7xJrIouZKQxCAMN6PwK2fg4O
# UV0xmime1zq72dOFBL8tXb9UY049wGEUtvsh
=======
# 3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4DT2uhJ04ji+tHD6n58vhavFIrmcxgheN
# MIIXiQIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBBT0Mg
# Q0EgMDECEzMAAz/LZbJZacV+llwAAAADP8swDQYJYIZIAWUDBAIBBQCggcowGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIGcBno/ti9PCrR9sXrajsTvlHQvGxbk63JiI
# URJByQuGMF4GCisGAQQBgjcCAQwxUDBOoEiARgBCAHUAaQBsAHQAOgAgAFIAZQBs
# AGUAYQBzAGUAXwB2ADMALgAxADIALgAxADAAXwAyADAAMgA1ADAANAAwADgALgAw
# ADKhAoAAMA0GCSqGSIb3DQEBAQUABIIBgE9xMVem4h5iAbvBzmB1pTdA4LYNkvd/
# hSbYmJRt5oJqBR0RGbUmcfYAgTlhdb/S84aGvI3N62I8qeMApnH89q+UF0i8p6+U
# Qza6Mu1cAHCq0NkHH6+N8g7nIfe5Cn+BBCBJ6kuYfQm9bx1JwEm5/yVCwG9I6+XV
# 3WonOeA8djuZFfB9OIW6N9ubX7X+nYqWaeT6w6/lDs8mL+s0Fumy4mJ8B15pd9mr
# N6dIRFokzhuALq6G0USKFzYf3qJQ4GyCos/Luez3cr8sE/78ds6vah5IlLP6qXMM
# ETwAdoymIYSm3Dly3lflodd4d7/nkMhfHITOxSUDoBbCP6MO1rhChX591rJy/omK
# 0RdM9ZpMl6VXHhzZ+lB8U/6j7xJGlxJSJHet7HFEuTnJEjY9dDy2bUgzk0vK1Rs2
# l7VLOP3X87p9iVz5vDAOQB0fcsMDJvhIzJlmIb5z2uZ6hqD4UZdTDMLIBWe9H7Kv
# rhmGDPHPRboFKtTrKoKcWaf4fJJ2NUtYlKGCFKAwghScBgorBgEEAYI3AwMBMYIU
# jDCCFIgGCSqGSIb3DQEHAqCCFHkwghR1AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFh
# BgsqhkiG9w0BCRABBKCCAVAEggFMMIIBSAIBAQYKKwYBBAGEWQoDATAxMA0GCWCG
# SAFlAwQCAQUABCAY3nVyqXzzboHwsVGd+j5FjG9eaMv+O3mJKpX+3EJ43AIGZ9gU
# uyvYGBMyMDI1MDQwODEyNDEyMi40MTNaMASAAgH0oIHgpIHdMIHaMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQg
# QW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjozREE1
# LTk2M0ItRTFGNDE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBT
# dGFtcGluZyBBdXRob3JpdHmggg8gMIIHgjCCBWqgAwIBAgITMwAAAAXlzw//Zi7J
# hwAAAAAABTANBgkqhkiG9w0BAQwFADB3MQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMUgwRgYDVQQDEz9NaWNyb3NvZnQgSWRlbnRp
# dHkgVmVyaWZpY2F0aW9uIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMjAw
# HhcNMjAxMTE5MjAzMjMxWhcNMzUxMTE5MjA0MjMxWjBhMQswCQYDVQQGEwJVUzEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUHVibGljIFJTQSBUaW1lc3RhbXBpbmcgQ0EgMjAyMDCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAJ5851Jj/eDFnwV9Y7UGIqMcHtfnlzPREwW9ZUZH
# d5HBXXBvf7KrQ5cMSqFSHGqg2/qJhYqOQxwuEQXG8kB41wsDJP5d0zmLYKAY8Zxv
# 3lYkuLDsfMuIEqvGYOPURAH+Ybl4SJEESnt0MbPEoKdNihwM5xGv0rGofJ1qOYST
# Ncc55EbBT7uq3wx3mXhtVmtcCEr5ZKTkKKE1CxZvNPWdGWJUPC6e4uRfWHIhZcgC
# sJ+sozf5EeH5KrlFnxpjKKTavwfFP6XaGZGWUG8TZaiTogRoAlqcevbiqioUz1Yt
# 4FRK53P6ovnUfANjIgM9JDdJ4e0qiDRm5sOTiEQtBLGd9Vhd1MadxoGcHrRCsS5r
# O9yhv2fjJHrmlQ0EIXmp4DhDBieKUGR+eZ4CNE3ctW4uvSDQVeSp9h1SaPV8UWEf
# yTxgGjOsRpeexIveR1MPTVf7gt8hY64XNPO6iyUGsEgt8c2PxF87E+CO7A28TpjN
# q5eLiiunhKbq0XbjkNoU5JhtYUrlmAbpxRjb9tSreDdtACpm3rkpxp7AQndnI0Sh
# u/fk1/rE3oWsDqMX3jjv40e8KN5YsJBnczyWB4JyeeFMW3JBfdeAKhzohFe8U5w9
# WuvcP1E8cIxLoKSDzCCBOu0hWdjzKNu8Y5SwB1lt5dQhABYyzR3dxEO/T1K/BVF3
# rV69AgMBAAGjggIbMIICFzAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFGtpKDo1L0hjQM972K9J6T7ZPdshMFQGA1UdIARNMEswSQYE
# VR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJ
# KwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSME
# GDAWgBTIftJqhSobyhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRl
# bnRpdHklMjBWZXJpZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRo
# b3JpdHklMjAyMDIwLmNybDCBlAYIKwYBBQUHAQEEgYcwgYQwgYEGCCsGAQUFBzAC
# hnVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29m
# dCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRl
# JTIwQXV0aG9yaXR5JTIwMjAyMC5jcnQwDQYJKoZIhvcNAQEMBQADggIBAF+Idsd+
# bbVaFXXnTHho+k7h2ESZJRWluLE0Oa/pO+4ge/XEizXvhs0Y7+KVYyb4nHlugBes
# nFqBGEdC2IWmtKMyS1OWIviwpnK3aL5JedwzbeBF7POyg6IGG/XhhJ3UqWeWTO+C
# zb1c2NP5zyEh89F72u9UIw+IfvM9lzDmc2O2END7MPnrcjWdQnrLn1Ntday7JSyr
# DvBdmgbNnCKNZPmhzoa8PccOiQljjTW6GePe5sGFuRHzdFt8y+bN2neF7Zu8hTO1
# I64XNGqst8S+w+RUdie8fXC1jKu3m9KGIqF4aldrYBamyh3g4nJPj/LR2CBaLyD+
# 2BuGZCVmoNR/dSpRCxlot0i79dKOChmoONqbMI8m04uLaEHAv4qwKHQ1vBzbV/nG
# 89LDKbRSSvijmwJwxRxLLpMQ/u4xXxFfR4f/gksSkbJp7oqLwliDm/h+w0aJ/U5c
# cnYhYb7vPKNMN+SZDWycU5ODIRfyoGl59BsXR/HpRGtiJquOYGmvA/pk5vC1lcnb
# eMrcWD/26ozePQ/TWfNXKBOmkFpvPE8CH+EeGGWzqTCjdAsno2jzTeNSxlx3glDG
# Jgcdz5D/AAxw9Sdgq/+rY7jjgs7X6fqPTXPmaCAJKVHAP19oEjJIBwD1LyHbaEgB
# xFCogYSOiUIr0Xqcr1nJfiWG2GwYe6ZoAF1bMIIHljCCBX6gAwIBAgITMwAAAEYX
# 5HV6yv3a5QAAAAAARjANBgkqhkiG9w0BAQwFADBhMQswCQYDVQQGEwJVUzEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQg
# UHVibGljIFJTQSBUaW1lc3RhbXBpbmcgQ0EgMjAyMDAeFw0yNDExMjYxODQ4NDla
# Fw0yNTExMTkxODQ4NDlaMIHaMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYw
# JAYDVQQLEx1UaGFsZXMgVFNTIEVTTjozREE1LTk2M0ItRTFGNDE1MDMGA1UEAxMs
# TWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFtcGluZyBBdXRob3JpdHkwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCwlXzoj/MNL1BfnV+gg4d0fZum
# 1HdUJidSNTcDzpHJvmIBqH566zBYcV0TyN7+3qOnJjpoTx6JBMgNYnL5BmTX9Hrm
# X0WdNMLf74u7NtBSuAD2sf6n2qUUrz7i8f7r0JiZixKJnkvA/1akLHppQMDCug1o
# C0AYjd753b5vy1vWdrHXE9hL71BZe5DCq5/4LBny8aOQZlzvjewgONkiZm+Sfctk
# Jjh9LxdkDlq5EvGE6YU0uC37XF7qkHvIksD2+XgBP0lEMfmPJo2fI9FwIA9YMX7K
# IINEM5OY6nkvKryM9s5bK6LV4z48NYpiI1xvH15YDps+19nHCtKMVTZdB4cYhA0d
# VqJ7dAu4VcxUwD1AEcMxWbIOR1z6OFkVY9GX5oH8k17d9t35PWfn0XuxW4SG/rim
# gtFgpE/shRsy5nMCbHyeCdW0He1plrYQqTsSHP2n/lz2DCgIlnx+uvPLVf5+JG/1
# d1i/LdwbC2WH6UEEJyZIl3a0YwM4rdzoR+P4dO9I/2oWOxXCYqFytYdCy9ljELUw
# byLjrjRddteR8QTxrCfadKpKfFY6Ak/HNZPUHaAPak3baOIvV7Q8axo3DWQy2ib3
# zXV6hMPNt1v90pv+q9daQdwUzUrgcbwThdrRhWHwlRIVg2sR668HPn4/8l9ikGok
# rL6gAmVxNswEZ9awCwIDAQABo4IByzCCAccwHQYDVR0OBBYEFBE20NSvdrC6Z6cm
# 6RPGP8YbqIrxMB8GA1UdIwQYMBaAFGtpKDo1L0hjQM972K9J6T7ZPdshMGwGA1Ud
# HwRlMGMwYaBfoF2GW2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3Js
# L01pY3Jvc29mdCUyMFB1YmxpYyUyMFJTQSUyMFRpbWVzdGFtcGluZyUyMENBJTIw
# MjAyMC5jcmwweQYIKwYBBQUHAQEEbTBrMGkGCCsGAQUFBzAChl1odHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFB1YmxpYyUy
# MFJTQSUyMFRpbWVzdGFtcGluZyUyMENBJTIwMjAyMC5jcnQwDAYDVR0TAQH/BAIw
# ADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwZgYDVR0g
# BF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMAgGBmeBDAEE
# AjANBgkqhkiG9w0BAQwFAAOCAgEAFIW5L+gGzX4gyHorS33YKXuK9iC91iZTpm30
# x/EdHG6U8NAu2qityxjZVq6MDq300gspG0ntzLYqVhjfku7iNzE78k6tNgFCr9wv
# GkIHeK+Q2RAO9/s5R8rhNC+lywOB+6K5Zi0kfO0agVXf7Nk2O6F6D9AEzNLijG+c
# Oe5Ef2F5l4ZsVSkLFCI5jELC+r4KnNZjunc+qvjSz2DkNsXfrjFhyk+K7v7U7+JF
# Z8kZ58yFuxEX0cxDKpJLxiNh/ODCOL2UxYkhyfI3AR0EhfxX9QZHVgxyZwnavR35
# FxqLSiGTeAJsK7YN3bIxyuP6eCcnkX8TMdpu9kPD97sHnM7po0UQDrjaN7etviLD
# xnax2nemdvJW3BewOLFrD1nSnd7ZHdPGPB3oWTCaK9/3XwQERLi3Xj+HZc89RP50
# Nt7h7+3G6oq2kXYNidI9iWd+gL+lvkQZH9YTIfBCLWjvuXvUUUU+AvFI00Utqrvd
# rIdqCFaqE9HHQgSfXeQ53xLWdMCztUP/YnMXiJxNBkc6UE2px/o6+/LXJDIpwIXR
# 4HSodLfkfsNQl6FFrJ1xsOYGSHvcFkH8389RmUvrjr1NBbdesc4Bu4kox+3cabOZ
# c1zm89G+1RRL2tReFzSMlYSGO3iKn3GGXmQiRmFlBb3CpbUVQz+fgxVMfeL0j4Lm
# KQfT1jIxggPUMIID0AIBATB4MGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNB
# IFRpbWVzdGFtcGluZyBDQSAyMDIwAhMzAAAARhfkdXrK/drlAAAAAABGMA0GCWCG
# SAFlAwQCAQUAoIIBLTAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZI
# hvcNAQkEMSIEIHgwQkiMhul6IrfEKmPaCFR+R91oZOlPqVgP/9PPcfn+MIHdBgsq
# hkiG9w0BCRACLzGBzTCByjCBxzCBoAQgEid2SJpUPj5xQm73M4vqDmVh1QR6TiuT
# UVkL3P8Wis4wfDBlpGMwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZXN0YW1waW5nIENBIDIwMjACEzMAAABGF+R1esr92uUAAAAAAEYwIgQgVp6I1YBM
# Mni0rCuD57vEK/tzWZypHqWFikWLFVY11RwwDQYJKoZIhvcNAQELBQAEggIAnRBH
# voM5+wbJp+aOwrrL8fi8Rv/eFV820Nhr+jMny73UscN60OWdcdcZDbjDlnDX1KEP
# sNcEOFvaruHHrF4kDK8N0yemElNz63IgqhUoGoXXQKT2RgVg7T/kiQJH7zuaEjgB
# YNniAZdXXJJ1C+uv2ZQzkGIEVIEA6pB5/xo4kFhrfkOrdGzqL8HXT/RZQDMn5Uzk
# W+Sl2JmsyYBS4sgI9Ay3qT5nv+frzngbWlqx1dre21uj37Fgk5mWHJEdmY1nqTTd
# 25j6oDLGPC8AS9wtgZBXggemKAXwyeOFFahXUFN7X7cbwTALy5aWjE/rqp+N5J7M
# +YApl3aknUZ13KTXz9pfAF0uhmZimngvBHjijyctleF8HUP2RNAhS/l68OqW7oKi
# Dqvb7tSHJbcnYkxo7dUq6ppfN51ah61ZsyMVG6SaH015+5QO1k50ohXcFff2GOuZ
# d3Z9JOoAjIkeiVTNeRlPDlHtS0CSYu4ZKsWsst+0VY2R9rJBeoii9Xa0oiIggkYL
# 1pHAPH0B1uLlvFcI6B+fAXe0OiCJodbO5lk8ZpvCG5WWYbjzp2c3B8PZGSBgEpSf
# KYlVavvBAvaJCORUO7j8PyzzDINuzQorP9+i399ORjOnqeC92Cb0V12LcoqqtJaf
# 7oSB86VOI0lfHnPUlLWvoiLHrFR5PsYkltOuPqU=
>>>>>>> 04c46d2b98c3c0b212dcba6d9e0f886d36e15bb3
# SIG # End signature block
