# Get-CSV.ps1
# Wrapper script that uses the ShittyParser module function
[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	[string]$Url = 'https://proto.notso.ai/jumbo/chats',
    
	[Parameter(Mandatory = $false)]
	[string]$OutputFolder = '.\outputs',
    
	[Parameter(Mandatory = $false)]
	[string]$OutputFile = 'chats.csv',
    
	[Parameter(Mandatory = $false)]
	[string]$CsvHeader = 'session_id,start_time,end_time,ip_address,country,language,messages_sent,sentiment,escalated,forwarded_hr,full_transcript,avg_response_time,tokens,tokens_eur,category,initial_msg,user_rating',
    
	[Parameter(Mandatory = $false)]
	[ValidateSet('CSV', 'PSObject')]
	[string]$ReturnType = 'CSV',
    
	[Parameter(Mandatory = $false)]
	[string]$EnvFilePath = '.\.env'
)

# Import the module if it's not already loaded
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'ShittyParser'
if (-not (Get-Module -Name ShittyParser)) {
	Import-Module -Name $modulePath -Force
	Write-Verbose "Imported ShittyParser module from $modulePath"
}

# Call the module function with the provided parameters
$params = @{
	Url          = $Url
	OutputFolder = $OutputFolder
	OutputFile   = $OutputFile
	CsvHeader    = $CsvHeader
	ReturnType   = $ReturnType
	EnvFilePath  = $EnvFilePath
}

# Call the module function
Get-ChatCSV @params
