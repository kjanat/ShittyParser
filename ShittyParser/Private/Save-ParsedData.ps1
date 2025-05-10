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
