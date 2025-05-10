# Get-CombinedChats.ps1
# Wrapper script that uses the ShittyParser module function
[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	[string]$CsvPath = '.\outputs\chats.csv',
    
	[Parameter(Mandatory = $false)]
	[string]$OutputFolder = '.\outputs\transcripts',
    
	[Parameter(Mandatory = $false)]
	[string]$ParsedOutputFolder = '.\outputs\parsed',
    
	[Parameter(Mandatory = $false)]
	[ValidateSet('JSON', 'CSV', 'PS1')]
	[string]$OutputFormat = 'JSON',
    
	[Parameter(Mandatory = $false)]
	[string]$OutputFileName,
    
	[Parameter(Mandatory = $false)]
	[switch]$Force,
    
	[Parameter(Mandatory = $false)]
	[string]$EnvFilePath = '.\.env',
    
	[Parameter(Mandatory = $false)]
	[switch]$SkipDownload
)

# Import the module if it's not already loaded
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'ShittyParser'
if (-not (Get-Module -Name ShittyParser)) {
	Import-Module -Name $modulePath -Force
	Write-Verbose "Imported ShittyParser module from $modulePath"
}

# Call the module function with the provided parameters
$params = @{
	CsvPath            = $CsvPath
	OutputFolder       = $OutputFolder
	ParsedOutputFolder = $ParsedOutputFolder
	OutputFormat       = $OutputFormat
	Force              = $Force
	EnvFilePath        = $EnvFilePath
	SkipDownload       = $SkipDownload
}

# Add OutputFileName parameter if provided
if ($OutputFileName) {
	$params.Add('OutputFileName', $OutputFileName)
}

# Call the module function
Get-CombinedChats @params
