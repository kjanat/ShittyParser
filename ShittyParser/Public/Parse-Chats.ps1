function Parse-Chats {
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
				$allMessages = Process-ChatFile -FilePath $FilePath
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
					$fileMessages = Process-ChatFile -FilePath $file.FullName
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
			$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
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
