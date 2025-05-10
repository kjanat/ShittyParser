function Get-Transcripts {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[string]$CsvPath = '.\outputs\chats.csv',

		[Parameter(Mandatory = $false)]
		[string]$OutputFolder = '.\outputs\transcripts',

		[Parameter(Mandatory = $false)]
		[switch]$Force,

		[Parameter(Mandatory = $false)]
		[ValidateScript({ Test-Path $_ -PathType Leaf })]
		[string]$EnvFilePath = '.\.env'
	)

	# Load environment variables
	if (-not (Import-Environment -FilePath $EnvFilePath)) {
		Write-Error 'Failed to load environment variables.'
		return $false
	}

	# Check if CSV file exists
	if (-not (Test-Path $CsvPath)) {
		Write-Error "CSV file not found at path: $CsvPath"
		return $false
	}

	# Create output folder if it doesn't exist
	if (-not (Test-Path $OutputFolder)) {
		Write-Host "Creating output folder: $OutputFolder"
		New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
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
		$chats = Import-Csv -Path $CsvPath
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
		$outputPath = Join-Path -Path $OutputFolder -ChildPath $fileName

		# Skip if file exists and not forcing download
		if ((Test-Path $outputPath) -and -not $Force) {
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
