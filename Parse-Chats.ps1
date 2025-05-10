# Parse-Chats.ps1
# Wrapper script that uses the ShittyParser module function
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Directory = ".\outputs\transcripts",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = ".\outputs\parsed",
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveToFile,
    
    [Parameter(Mandatory = $false)]
	[ValidateSet('JSON', 'CSV', 'PS1')]
	[string]$OutputFormat = 'JSON',
    
	[Parameter(Mandatory = $false)]
	[switch]$CombinedOnly
)

# Import the module if it's not already loaded
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'ShittyParser'
if (-not (Get-Module -Name ShittyParser)) {
	Import-Module -Name $modulePath -Force
	Write-Verbose "Imported ShittyParser module from $modulePath"
}

# Call the module function with the provided parameters
$parseParams = @{
	Directory       = $Directory
	OutputDirectory = $OutputDirectory
	SaveToFile      = $SaveToFile
	OutputFormat    = $OutputFormat
	CombinedOnly    = $CombinedOnly
}

# Add FilePath parameter if provided
if ($FilePath) {
	$parseParams.Add('FilePath', $FilePath)
}

# Call the module function
Parse-Chats @parseParams
