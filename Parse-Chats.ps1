[CmdletBinding()]
param (
	[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
	[string]$FilePath,
    
	[Parameter(Mandatory = $false)]
	[string]$Directory = "$PSScriptRoot/outputs/transcripts",
    
	[Parameter(Mandatory = $false)]
	[string]$OutputDirectory = "$PSScriptRoot/outputs/parsed",
    
	[Parameter(Mandatory = $false)]
	[switch]$SaveToFile,
    
	[Parameter(Mandatory = $false)]
	[string]$OutputFormat = 'JSON' # Options: JSON, CSV, PS1
)

# Helper function to process a single chat file
function Process-ChatFile {
	param (
		[Parameter(Mandatory = $true)]
		[string]$FilePath
	)
    
	Write-Verbose "Processing file: $FilePath"
    
	# Read the file content
	$fileContent = Get-Content -Path $FilePath -Raw
    
	# Create an array to store messages
	$messages = @()
    
	# Get the file name without extension for identification
	$fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    
	# Regular expression to match User: and Assistant: patterns
	$regex = '(?<speaker>User|Assistant): (?<message>(?:.+?)(?=(\r?\n(?:User|Assistant): |\z)))'
    
	# Extract matches using regex
	$matches = [regex]::Matches($fileContent, $regex, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
	foreach ($match in $matches) {
		$speaker = $match.Groups['speaker'].Value
		$message = $match.Groups['message'].Value.Trim()
        
		# Create a custom object for each message
		$messageObject = [PSCustomObject]@{
			SessionId = $fileName
			Speaker   = $speaker
			Message   = $message
		}
        
		# Add to the messages array
		$messages += $messageObject
	}
    
	return $messages
}

# Function to save parsed data to file
function Save-ParsedData {
	param (
		[Parameter(Mandatory = $true)]
		[array]$Messages,
        
		[Parameter(Mandatory = $true)]
		[string]$FilePath,
        
		[Parameter(Mandatory = $true)]
		[string]$Format
	)
    
	# Create the output directory if it doesn't exist
	if (-not (Test-Path -Path (Split-Path -Path $FilePath -Parent))) {
		New-Item -ItemType Directory -Path (Split-Path -Path $FilePath -Parent) -Force | Out-Null
	}
    
	switch ($Format.ToUpper()) {
		'JSON' {
			$Messages | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath
			Write-Verbose "Saved JSON data to: $FilePath"
		}
		'CSV' {
			$Messages | Export-Csv -Path $FilePath -NoTypeInformation
			Write-Verbose "Saved CSV data to: $FilePath"
		}
		'PS1' {
			$output = '$chatData = @(' + [Environment]::NewLine
			foreach ($msg in $Messages) {
				$output += '    [PSCustomObject]@{' + [Environment]::NewLine
				$output += "        SessionId = '$($msg.SessionId)'" + [Environment]::NewLine
				$output += "        Speaker = '$($msg.Speaker)'" + [Environment]::NewLine
				$output += "        Message = @'" + [Environment]::NewLine
				$output += "$($msg.Message)" + [Environment]::NewLine
				$output += "'@" + [Environment]::NewLine
				$output += '    }' + [Environment]::NewLine
			}
			$output += ')' + [Environment]::NewLine
			$output | Set-Content -Path $FilePath
			Write-Verbose "Saved PS1 data to: $FilePath"
		}
		default {
			Write-Error "Unsupported output format: $Format. Use JSON, CSV, or PS1."
		}
	}
}

# Main execution logic
try {
	$allMessages = @()
    
	# Process a single file if provided
	if ($FilePath) {
		if (Test-Path -Path $FilePath -PathType Leaf) {
			$allMessages = Process-ChatFile -FilePath $FilePath
		} else {
			Write-Error "The specified file does not exist: $FilePath"
			exit 1
		}
	}
	# Process all files in the directory
	elseif (Test-Path -Path $Directory -PathType Container) {
		$files = Get-ChildItem -Path $Directory -Filter '*.txt'
        
		if ($files.Count -eq 0) {
			Write-Warning "No .txt files found in directory: $Directory"
		} else {
			Write-Verbose "Found $($files.Count) files to process"
            
			foreach ($file in $files) {
				$fileMessages = Process-ChatFile -FilePath $file.FullName
				$allMessages += $fileMessages
                
				# If saving to individual files
				if ($SaveToFile) {
					$outputFile = Join-Path -Path $OutputDirectory -ChildPath "$($file.BaseName).$($OutputFormat.ToLower())"
					Save-ParsedData -Messages $fileMessages -FilePath $outputFile -Format $OutputFormat
				}
			}
		}
	} else {
		Write-Error 'Neither a valid file path nor directory was provided.'
		exit 1
	}
    
	# Save all messages to a combined file if requested
	if ($SaveToFile -and $allMessages.Count -gt 0 -and !$FilePath) {
		$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
		$outputFile = Join-Path -Path $OutputDirectory -ChildPath "all_chats_$timestamp.$($OutputFormat.ToLower())"
		Save-ParsedData -Messages $allMessages -FilePath $outputFile -Format $OutputFormat
	}
    
	# Return all messages to the pipeline
	return $allMessages
    
} catch {
	Write-Error "An error occurred: $_"
	exit 1
}
