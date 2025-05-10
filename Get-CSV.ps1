[CmdletBinding(PositionalBinding)]
param (
	[string]$url = 'https://proto.notso.ai/jumbo/chats',
	[string]$folder = './outputs',
	[string]$outputFile = 'chats.csv',
	[string]$csvHeader = 'session_id,start_time,end_time,ip_address,country,language,messages_sent,sentiment,escalated,forwarded_hr,full_transcript,avg_response_time,tokens,tokens_eur,category,initial_msg,user_rating',
	
	[ValidateSet("csv", "psobject")]
	[string]$returnType = 'csv',
	
	[ValidateScript({ Test-Path $_ -PathType Leaf })]
	[string]$envFile = '.env'
)

function Capitalize {
	param ([string]$inputString)
	switch ($inputString) {
		{ [string]::IsNullOrEmpty($_) } {
			return $null 
  }
		default {
			return -join ($inputString.Substring(0, 1).ToUpper() + $inputString.Substring(1).ToLower())
		}
	}
}

function Import-Environment {
	param ([string]$filePath)
	if (Test-Path $filePath) {
		$envContent = Get-Content $filePath
		foreach ($line in $envContent) {
			$match = $line -match '^(?<key>[^=]+)\s?=\s?(?<value>.*)$'
			if (!$match) {
				Write-Warning "Invalid line format: $line"; continue 
   }
			[Environment]::SetEnvironmentVariable($Matches['key'].Trim(), $Matches['value'].Trim())
			Write-Debug "Set environment variable: $($Matches['key'].Trim()) = $($Matches['value'].Trim())"
		}
	} else {
		Write-Host 'No .env file found. Please create one with USERNAME and PASSWORD variables.'
		exit
	}
}

Import-Environment -filePath $envFile

# Use the username and password to authenticate
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("$($env:username):$($env:password)")))

# Make the API call to get the chat data
$csvChats = Invoke-RestMethod -Uri $url -Method Get -Headers @{ Authorization = "Basic $base64AuthInfo" }

$fullCsvRAW = "$csvHeader`n$csvChats"

# Add headers to the output file
if ($PSBoundParameters['Debug']) {
	$fullCsvRAW | Out-File -FilePath "$folder/chats_raw.csv" -Encoding utf8 -Force
	Write-Debug "Raw CSV data saved to $folder/chats_raw.csv"
}

$data = $fullCsvRAW | ConvertFrom-Csv -Delimiter ','
foreach ($row in $data) {
	$row.start_time = Get-Date $row.start_time -Format 'yyyy-MM-dd HH:mm:ss'
	$row.end_time = Get-Date $row.end_time -Format 'yyyy-MM-dd HH:mm:ss'
	$row.avg_response_time = [string]($row.avg_response_time -replace ',', '.')
	$row.tokens_eur = [string]($row.tokens_eur -replace ',', '.')
	$row.messages_sent = [int]$row.messages_sent
	$row.sentiment = Capitalize $row.sentiment
	$row.country = [string]$row.country.ToUpper()
	$row.language = Capitalize $row.language
	$row.escalated = Capitalize $row.escalated
	$row.forwarded_hr = Capitalize $row.forwarded_hr
}

switch ($returnType) {
	'csv' {
		$data | Export-Csv -Path "${folder}/${outputFile}" -NoTypeInformation -Encoding utf8 -Force
	}
	'psobject' {
		$data
	}
	Default {
		Write-Error "Invalid return type specified: $returnType"
	}
}
