function Process-ChatFile {
	[CmdletBinding()]
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
