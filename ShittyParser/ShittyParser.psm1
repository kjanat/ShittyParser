#Requires -Version 5.1

# Get all script files
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)

# Import all private functions
foreach ($file in $Private) {
	try {
		. $file.FullName
		Write-Verbose "Imported private function $($file.BaseName)"
	} catch {
		Write-Error "Failed to import private function $($file.BaseName): $_"
	}
}

# Import all public functions and export them
foreach ($file in $Public) {
	try {
		. $file.FullName
		Write-Verbose "Imported public function $($file.BaseName)"
		# Export the function using its file name (without extension)
		Export-ModuleMember -Function $file.BaseName
	} catch {
		Write-Error "Failed to import public function $($file.BaseName): $_"
	}
}

# Export any aliases that may have been defined
Export-ModuleMember -Alias *
