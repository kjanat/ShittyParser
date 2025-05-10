<#
.SYNOPSIS
	Saves parsed message data to a file in various formats.

.DESCRIPTION
	The Save-ParsedData function saves an array of message objects to a specified file
	using one of three supported formats: JSON, CSV, or PS1. It automatically creates
	the output directory if it does not exist.

.PARAMETER Messages
	An array of message objects to be saved. Each message is expected to have at least
	SessionId, Speaker, and Message properties.

.PARAMETER FilePath
	The full path where the output file should be saved.

.PARAMETER Format
	The format to use when saving the data. Supported formats are:
	- JSON: Saves data as a JSON file
	- CSV: Saves data as a CSV file
	- PS1: Saves data as a PowerShell script with an array of PSCustomObjects

.EXAMPLE
	Save-ParsedData -Messages $chatMessages -FilePath "C:\Output\chat_data.json" -Format "JSON"

.EXAMPLE
	Save-ParsedData -Messages $chatMessages -FilePath "C:\Output\chat_data.csv" -Format "CSV" -Verbose

.OUTPUTS
	System.Boolean
	Returns $true if the operation was successful, $false otherwise.

.NOTES
	The PS1 format uses PowerShell's here-string format (@') to preserve multi-line messages.
#>
function Save-ParsedData {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[array]$Messages,

		[Parameter(Mandatory = $true)]
		[string]$FilePath,

		[Parameter(Mandatory = $true)]
		[ValidateSet('JSON', 'CSV', 'PS1')]
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
			return $false
		}
	}

	return $true
}
