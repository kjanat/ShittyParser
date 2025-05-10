# Download-Chats.ps1
# Wrapper script that uses the ShittyParser module functions
[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	[string]$CsvPath = '.\outputs\chats.csv',
    
	[Parameter(Mandatory = $false)]
	[string]$OutputFolder = '.\outputs\transcripts',
    
	[Parameter(Mandatory = $false)]
	[string]$ParsedOutputFolder = '.\outputs\parsed',
    
	[Parameter(Mandatory = $false)]
	[string]$ParsedOutputFormat = 'JSON',
    
	[Parameter(Mandatory = $false)]
	[switch]$Force,
    
	[Parameter(Mandatory = $false)]
	[switch]$Parse,
    
	[Parameter(Mandatory = $false)]
	[switch]$CombinedOnly,
    
	[Parameter(Mandatory = $false)]
	[string]$EnvFilePath = '.\.env'
)

# Import the module if it's not already loaded
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'ShittyParser'
if (-not (Get-Module -Name ShittyParser)) {
	Import-Module -Name $modulePath -Force
	Write-Verbose "Imported ShittyParser module from $modulePath"
}

# Execute the Get-Transcripts function
$result = Get-Transcripts -CsvPath $CsvPath -OutputFolder $OutputFolder -Force:$Force -EnvFilePath $EnvFilePath

# If parsing is requested, do that too
if ($Parse -and $result) {
	Write-Host "`nParsing downloaded transcripts..."
    
	$parseParams = @{
		Directory       = $OutputFolder
		OutputDirectory = $ParsedOutputFolder
		SaveToFile      = $true
		OutputFormat    = $ParsedOutputFormat
	}
    
	# Add CombinedOnly parameter if specified
	if ($CombinedOnly) {
		$parseParams.Add('CombinedOnly', $true)
	}
    
	$parseResult = Parse-Chats @parseParams
    
    # If CombinedOnly, display a message about what was created
    if ($CombinedOnly -and $parseResult) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $combinedFilePath = Join-Path -Path $ParsedOutputFolder -ChildPath "all_chats_$timestamp.$($ParsedOutputFormat.ToLower())"
        Write-Host "`nCreated combined file only: $combinedFilePath" -ForegroundColor Green
    }
}
