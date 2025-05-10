<#
.SYNOPSIS
	Converts chat transcripts from text files into structured formats.

.DESCRIPTION
	The ConvertFrom-ChatTranscript function parses chat conversation text files and converts them into structured data in JSON, CSV, or PS1 formats.
	It can process individual files or all text files in a directory. The function also supports saving the parsed data to files or returning it to the pipeline.

.PARAMETER FilePath
	The path to a single chat transcript file to parse. If specified, Directory parameter is ignored.

.PARAMETER Directory
	The directory containing chat transcript files to process. Default value is '.\outputs\transcripts'.
	Only used if FilePath is not specified.

.PARAMETER OutputDirectory
	The directory where parsed output files will be saved. Default value is '.\outputs\parsed'.
	The directory will be created if it doesn't exist.

.PARAMETER SaveToFile
	Switch parameter that indicates whether to save the parsed data to files.

.PARAMETER OutputFormat
	The format to use for the output files. Valid values are 'JSON', 'CSV', and 'PS1'.
	Default value is 'JSON'.

.PARAMETER CombinedOnly
	Switch parameter that, when used with SaveToFile, only saves a single combined file of all parsed chats
	rather than individual files for each input transcript.

.EXAMPLE
	ConvertFrom-ChatTranscript -FilePath ".\mychat.txt" -SaveToFile -OutputFormat "JSON"

	Parses the chat transcript from "mychat.txt" and saves the results to a JSON file in the default output directory.

.EXAMPLE
	ConvertFrom-ChatTranscript -Directory ".\chats" -SaveToFile -OutputFormat "CSV" -CombinedOnly

	Parses all .txt files in the ".\chats" directory and saves the combined results to a single CSV file.

.EXAMPLE
	$parsedData = ConvertFrom-ChatTranscript -Directory ".\chats"

	Parses all .txt files in the ".\chats" directory and returns the structured data to the pipeline without saving to a file.

.NOTES
	Requires the ConvertFrom-ChatFile and Save-ParsedData helper functions.
	An alias 'Parse-Chats' is also provided for backward compatibility.

.OUTPUTS
	System.Array
	Returns an array of message objects, each containing parsed chat data.
	Returns $false if an error occurs.
#>
function ConvertFrom-ChatTranscript {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
		[string]$FilePath,

		[Parameter(Mandatory = $false)]
		[string]$Directory = '.\outputs\transcripts',

		[Parameter(Mandatory = $false)]
		[string]$OutputDirectory = '.\outputs\parsed',

		[Parameter(Mandatory = $false)]
		[switch]$SaveToFile,

		[Parameter(Mandatory = $false)]
		[ValidateSet('JSON', 'CSV', 'PS1')]
		[string]$OutputFormat = 'JSON',

		[Parameter(Mandatory = $false)]
		[switch]$CombinedOnly
	)

	# Main execution logic
	try {
		$allMessages = @()

		# Process a single file if provided
		if ($FilePath) {
			if (Test-Path -Path $FilePath -PathType Leaf) {
				$allMessages = ConvertFrom-ChatFile -FilePath $FilePath
			} else {
				Write-Error "The specified file does not exist: $FilePath"
				return $false
			}
		}
		# Process all files in the directory
		elseif (Test-Path -Path $Directory -PathType Container) {
			$files = Get-ChildItem -Path $Directory -Filter '*.txt'

			if ($files.Count -eq 0) {
				Write-Warning "No .txt files found in directory: $Directory"
				return $false
			} else {
				Write-Verbose "Found $($files.Count) files to process"

				foreach ($file in $files) {
					$fileMessages = ConvertFrom-ChatFile -FilePath $file.FullName
					$allMessages += $fileMessages

					# If saving to individual files and CombinedOnly is not specified
					if ($SaveToFile -and -not $CombinedOnly) {
						$outputFile = Join-Path -Path $OutputDirectory -ChildPath "$($file.BaseName).$($OutputFormat.ToLower())"
						Save-ParsedData -Messages $fileMessages -FilePath $outputFile -Format $OutputFormat
					}
				}
			}
		} else {
			Write-Error 'Neither a valid file path nor directory was provided.'
			return $false
		}

		# Save all messages to a combined file if requested
		if ($SaveToFile -and $allMessages.Count -gt 0 -and -not $FilePath) {
			$timestamp = Get-Date -Format 'yyyy-MM-ddTHH.mm.ss'
			$outputFile = Join-Path -Path $OutputDirectory -ChildPath "all_chats_$timestamp.$($OutputFormat.ToLower())"
			Save-ParsedData -Messages $allMessages -FilePath $outputFile -Format $OutputFormat
			Write-Host "All messages saved to: $outputFile" -ForegroundColor Green
		}

		# Return all messages to the pipeline
		return $allMessages

	} catch {
		Write-Error "An error occurred: $_"
		return $false
	}
}

# Add an alias for backward compatibility with existing scripts
Set-Alias -Name 'Parse-Chats' -Value ConvertFrom-ChatTranscript
