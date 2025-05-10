<#
.SYNOPSIS
	Combines and processes chat transcripts from multiple sources.

.DESCRIPTION
	The Get-CombinedChats function downloads chat transcripts from sources specified in a CSV file,
	parses them into a unified format, and saves the combined result to a file.
	It can output in JSON, CSV, or PS1 formats.

.PARAMETER CsvPath
	The path to the CSV file containing chat source information.
	Default is '.\outputs\chats.csv'.

.PARAMETER OutputFolder
	The folder where individual chat transcripts will be downloaded.
	Default is '.\outputs\transcripts'.

.PARAMETER ParsedOutputFolder
	The folder where the combined parsed output will be saved.
	Default is '.\outputs\parsed'.

.PARAMETER OutputFormat
	The format for the output file. Valid options are 'JSON', 'CSV', or 'PS1'.
	Default is 'JSON'.

.PARAMETER OutputFileName
	Optional custom name for the output file (without extension).
	If not specified, a default name with timestamp will be used.

.PARAMETER Force
	If specified, overwrites existing transcript files during download.

.PARAMETER EnvFilePath
	The path to the environment file containing necessary credentials and settings.
	Default is '.\.env'. Must be a valid file path.

.PARAMETER SkipDownload
	If specified, skips the download process and only parses existing transcript files.

.EXAMPLE
	Get-CombinedChats -OutputFormat JSON -OutputFileName "my_chats"

	Downloads transcripts from sources in the default CSV file and combines them into
	a single JSON file named my_chats.json in the default parsed output folder.

.EXAMPLE
	Get-CombinedChats -CsvPath "C:\Data\sources.csv" -SkipDownload -OutputFormat CSV

	Parses existing transcripts without downloading new ones, and outputs as CSV.

.OUTPUTS
	System.Object[]
	Returns an array of parsed chat messages on success, or $false on failure.

.NOTES
	This function depends on Import-Environment, Get-Transcripts, and ConvertFrom-ChatTranscript functions.
#>
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
		[ValidateScript({ Test-Path $_ -PathType Leaf })]
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

		# Use new function name ConvertFrom-ChatTranscript instead of Parse-Chats
		$parsedMessages = ConvertFrom-ChatTranscript @parseParams

		if ($parsedMessages.Count -gt 0) {
			# If a custom filename is specified, rename the generated file
			if (-not [string]::IsNullOrEmpty($OutputFileName)) {
				$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
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
