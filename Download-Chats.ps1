[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	[string]$CsvPath = './outputs/chats.csv',

	[Parameter(Mandatory = $false)]
	[string]$OutputFolder = './outputs/transcripts',

	[Parameter(Mandatory = $false)]
	[string]$ParsedOutputFolder = './outputs/parsed',

	[Parameter(Mandatory = $false)]
	[string]$ParsedOutputFormat = 'JSON',

	[Parameter(Mandatory = $false)]
	[switch]$Force,

	[Parameter(Mandatory = $false)]
	[switch]$Parse,

	[Parameter(Mandatory = $false)]
	[string]$EnvFilePath = './.env'
)

function Import-Environment {
	param ([string]$filePath)

	if (Test-Path $filePath) {
		$envContent = Get-Content $filePath
		foreach ($line in $envContent) {
			if ($line.Trim() -eq '' -or $line.StartsWith('#')) {
				continue
			}

			$match = $line -match '^(?<key>[^=]+)\s?=\s?(?<value>.*)$'
			if (!$match) {
				Write-Warning "Invalid line format: $line"
				continue
			}

			[Environment]::SetEnvironmentVariable($Matches['key'].Trim(), $Matches['value'].Trim())
			Write-Debug "Set environment variable: $($Matches['key'].Trim()) = $($Matches['value'].Trim())"
		}
		Write-Verbose "Environment variables loaded from $filePath"
	} else {
		Write-Warning "No .env file found at $filePath. No authentication credentials loaded."
	}
}

function Get-Transcripts {
	[CmdletBinding()]
	param (
		[string]$csvPath,
		[string]$outputFolder,
		[switch]$force
	)

	# Check if CSV file exists
	if (-not (Test-Path $csvPath)) {
		Write-Error "CSV file not found at path: $csvPath"
		return $false
	}

	# Create output folder if it doesn't exist
	if (-not (Test-Path $outputFolder)) {
		Write-Host "Creating output folder: $outputFolder"
		New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
	}

	# Get authentication credentials
	$username = [Environment]::GetEnvironmentVariable('USERNAME')
	$password = [Environment]::GetEnvironmentVariable('PASSWORD')

	# Check if credentials are available
	if ([string]::IsNullOrEmpty($username) -or [string]::IsNullOrEmpty($password)) {
		Write-Error 'Username or password not found in environment variables'
		return $false
	}

	# Create authentication header
	$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}")))
	$authHeader = @{ Authorization = "Basic $base64AuthInfo" }

	# Import CSV file
	try {
		$chats = Import-Csv -Path $csvPath
		Write-Host "Found $($chats.Count) chat entries in CSV"
	} catch {
		Write-Error "Failed to import CSV: $_"
		return $false
	}

	# Initialize counters
	$downloaded = 0
	$skipped = 0
	$failed = 0
	$total = $chats.Count

	# Progress bar setup
	$progressParams = @{
		Activity        = 'Downloading chat transcripts'
		Status          = 'Processing chats'
		PercentComplete = 0
	}

	# Process each chat entry
	for ($i = 0; $i -lt $chats.Count; $i++) {
		$chat = $chats[$i]

		# Update progress
		$progressParams.PercentComplete = ($i / $total * 100)
		$progressParams.Status = "Processing $($i+1) of $total"
		Write-Progress @progressParams

		# Get the transcript URL
		$transcriptUrl = $chat.full_transcript

		# Skip if URL is empty
		if ([string]::IsNullOrEmpty($transcriptUrl)) {
			Write-Verbose "Skipping entry with session ID $($chat.session_id) - No transcript URL"
			$skipped++
			continue
		}

		# Extract filename from URL
		$fileName = $transcriptUrl.Split('/')[-1]
		$outputPath = Join-Path -Path $outputFolder -ChildPath $fileName

		# Skip if file exists and not forcing download
		if ((Test-Path $outputPath) -and -not $force) {
			Write-Verbose "Skipping $fileName - File already exists (use -Force to override)"
			$skipped++
			continue
		}

		Write-Host "Downloading transcript for session $($chat.session_id)" -NoNewline

		try {
			# Download the transcript
			Invoke-RestMethod -Uri $transcriptUrl -Headers $authHeader -OutFile $outputPath
			Write-Host ' - Success' -ForegroundColor Green
			$downloaded++
		} catch {
			Write-Host ' - Failed' -ForegroundColor Red
			Write-Warning "Failed to download $transcriptUrl. Error: $_"
			$failed++
		}
	}

	# Clear progress bar
	Write-Progress -Activity 'Downloading chat transcripts' -Completed

	# Print summary
	Write-Host "`nDownload Summary:"
	Write-Host '----------------'
	Write-Host "Total chat entries: $total"
	Write-Host "Successfully downloaded: $downloaded" -ForegroundColor Green
	Write-Host "Skipped (already exists or no URL): $skipped" -ForegroundColor Yellow
	Write-Host "Failed downloads: $failed" -ForegroundColor Red

	return $true
}

# Main script execution
try {
	# Load environment variables
	Import-Environment -filePath $EnvFilePath

	# Download transcripts
	$downloadResult = Get-Transcripts -csvPath $CsvPath -outputFolder $OutputFolder -force:$Force

	# Parse transcripts if requested
	if ($Parse -and $downloadResult) {
		Write-Host "`nParsing downloaded transcripts..."

		# Call Parse-Chats.ps1 script
		$parseScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'Parse-Chats.ps1'

		if (Test-Path $parseScriptPath) {
			& $parseScriptPath -Directory $OutputFolder -OutputDirectory $ParsedOutputFolder -SaveToFile -OutputFormat $ParsedOutputFormat -Verbose
		} else {
			Write-Error "Parse-Chats.ps1 script not found at $parseScriptPath"
		}
	}

} catch {
	Write-Error "An error occurred in the main script: $_"
	exit 1
}
