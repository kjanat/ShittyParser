<#
.SYNOPSIS
	Imports environment variables from a .env file into the current session.

.DESCRIPTION
	The Import-Environment function reads a .env file and sets environment variables
	based on the key-value pairs defined in the file. It handles both relative and
	absolute file paths and searches in multiple common locations when a relative
	path is provided.

.PARAMETER FilePath
	Specifies the path to the .env file. Can be absolute or relative.
	Default value is '.env'.

.EXAMPLE
	Import-Environment
	# Searches for a .env file in common locations and imports variables

.EXAMPLE
	Import-Environment -FilePath "config/.env.development"
	# Imports environment variables from config/.env.development

.EXAMPLE
	Import-Environment -Verbose
	# Shows detailed information about which .env file is being loaded

.NOTES
	The function attempts to find the .env file in the following locations when a relative path is provided:
	- Current directory
	- Workspace root (if current directory is "outputs")
	- Module directory
	- Script directory (if called from a script)
	- Parent directory of the module
	- Two levels up from the module directory

.OUTPUTS
	[System.Boolean]
	Returns $true if the environment variables were successfully loaded, $false otherwise.
#>
function Import-Environment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FilePath = '.env'
    )

    # Resolve the file path properly based on whether it's relative or absolute
    if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
        $possibleLocations = @()

        # For relative paths, first try the current directory
        $currentDirPath = Join-Path -Path (Get-Location) -ChildPath $FilePath
        $possibleLocations += $currentDirPath

        # Then try the workspace root directory (one level up from current if in outputs folder)
        $workspaceRoot = if ((Split-Path -Leaf (Get-Location)) -eq "outputs") {
            Join-Path -Path (Split-Path -Parent (Get-Location)) -ChildPath $FilePath
        } else {
            $null
        }
        if ($workspaceRoot) { $possibleLocations += $workspaceRoot }

        # Then try relative to module directory
        $moduleDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $moduleDirPath = Join-Path -Path $moduleDir -ChildPath $FilePath
        $possibleLocations += $moduleDirPath

        # Try the script root directory if called from a script
        $scriptPath = if ($MyInvocation.PSScriptRoot) {
            Join-Path -Path $MyInvocation.PSScriptRoot -ChildPath $FilePath
        } else {
            $null
        }
        if ($scriptPath) { $possibleLocations += $scriptPath }

        # Try parent directory of module
        $parentModulePath = Join-Path -Path (Split-Path -Parent $moduleDir) -ChildPath $FilePath
        $possibleLocations += $parentModulePath

        # Try two levels up (for common project structures)
        $twoLevelsUp = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $moduleDir)) -ChildPath $FilePath
        $possibleLocations += $twoLevelsUp

        # Find the first path that exists
        $resolvedPath = $possibleLocations | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($resolvedPath) {
            Write-Verbose "Using .env file from: $resolvedPath"
        } else {
            Write-Warning "Could not find .env file at path: $FilePath"
            Write-Warning "Searched in multiple locations. Create a .env file in one of these locations:"
            $possibleLocations | ForEach-Object { Write-Warning "  - $_" }
            return $false
        }
    } else {
        # For absolute paths, use as provided
        $resolvedPath = $FilePath
        if (-not (Test-Path $resolvedPath)) {
            Write-Warning "No .env file found at specified absolute path: $resolvedPath"
            return $false
        }
    }

    Write-Verbose "Loading environment variables from: $resolvedPath"
    $envContent = Get-Content $resolvedPath
    foreach ($line in $envContent) {
        # Skip empty lines and comments
        if ($line.Trim() -eq "" -or $line.StartsWith("#")) { continue }

        # Parse key=value pairs
        $match = $line -match '^(?<key>[^=]+)\s?=\s?(?<value>.*)$'
        if (!$match) {
            Write-Warning "Invalid line format: $line"
            continue
        }

        # Set environment variable
        [Environment]::SetEnvironmentVariable($Matches['key'].Trim(),$Matches['value'].Trim())
        Write-Debug "Set environment variable: $($Matches['key'].Trim()) = $($Matches['value'].Trim())"
    }
    Write-Verbose "Environment variables loaded from $resolvedPath"
    return $true
}
