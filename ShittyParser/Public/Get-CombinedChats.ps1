function Get-CombinedChats {
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
    
	# Main script execution
	try {
		# Load environment variables
		if (-not (Import-Environment -FilePath $EnvFilePath)) {
			Write-Error 'Failed to load environment variables.'
			return $false
		}
        
		# Create output directories if they don't exist
		if (-not (Test-Path $ParsedOutputFolder)) {
			Write-Host "Creating parsed output folder: $ParsedOutputFolder"
			New-Item -ItemType Directory -Path $ParsedOutputFolder -Force | Out-Null
		}
        
		# Download transcripts if not skipped
		if (-not $SkipDownload) {
			$downloadResult = Get-Transcripts -CsvPath $CsvPath -OutputFolder $OutputFolder -Force:$Force -EnvFilePath $EnvFilePath
			if (-not $downloadResult) {
				Write-Warning 'Transcript download process had issues. Continuing with parsing...'
			}
		} else {
			Write-Host 'Skipping download process as requested.' -ForegroundColor Yellow
		}
        
		# Parse the transcripts into a single file
		$parseParams = @{
			Directory       = $OutputFolder 
			OutputDirectory = $ParsedOutputFolder
			SaveToFile      = $true
			OutputFormat    = $OutputFormat
			CombinedOnly    = $true
		}
        
		$parsedMessages = Parse-Chats @parseParams
        
		if ($parsedMessages.Count -gt 0) {
			# If a custom filename is specified, rename the generated file
			if (-not [string]::IsNullOrEmpty($OutputFileName)) {
				$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
				$generatedFile = Join-Path -Path $ParsedOutputFolder -ChildPath "all_chats_$timestamp.$($OutputFormat.ToLower())"
				$desiredFile = Join-Path -Path $ParsedOutputFolder -ChildPath "$OutputFileName.$($OutputFormat.ToLower())"
                
				if (Test-Path $generatedFile) {
					Move-Item -Path $generatedFile -Destination $desiredFile -Force
					Write-Host "Renamed output file to: $desiredFile" -ForegroundColor Green
				}
			}
            
			Write-Host "`nProcess completed successfully!" -ForegroundColor Green
			Write-Host "Total messages parsed: $($parsedMessages.Count)" -ForegroundColor Green
			return $parsedMessages
		} else {
			Write-Warning 'Process completed but no messages were parsed.'
			return $false
		}
        
	} catch {
		Write-Error "An error occurred in Get-CombinedChats: $_"
		return $false
	}
}
