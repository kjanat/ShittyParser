function Import-Environment {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$FilePath
	)
    
	if (Test-Path $FilePath) {
		$envContent = Get-Content $FilePath
		foreach ($line in $envContent) {
			# Skip empty lines and comments
			if ($line.Trim() -eq '' -or $line.StartsWith('#')) {
				continue 
			}
            
			# Parse key=value pairs
			$match = $line -match '^(?<key>[^=]+)\s?=\s?(?<value>.*)$'
			if (!$match) { 
				Write-Warning "Invalid line format: $line"
				continue 
			}
            
			# Set environment variable
			[Environment]::SetEnvironmentVariable($Matches['key'].Trim(), $Matches['value'].Trim())
			Write-Debug "Set environment variable: $($Matches['key'].Trim()) = $($Matches['value'].Trim())"
		}
		Write-Verbose "Environment variables loaded from $FilePath"
		return $true
	} else {
		Write-Warning "No .env file found at $FilePath. No authentication credentials loaded."
		return $false
	}
}
