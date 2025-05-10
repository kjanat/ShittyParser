<#
.SYNOPSIS
	Converts a chat file with User and Assistant messages into structured PowerShell objects.

.DESCRIPTION
	The ConvertFrom-ChatFile function parses a text file containing a conversation between User and Assistant,
	extracting each message and returning them as structured objects with session identification.
	The file is expected to follow a format where each message starts with "User: " or "Assistant: ".

.PARAMETER FilePath
	The path to the chat file to be processed. This parameter is mandatory.

.EXAMPLE
	ConvertFrom-ChatFile -FilePath "C:\Chats\conversation.txt"

	Processes the conversation.txt file and returns an array of message objects.

.EXAMPLE
	Get-ChildItem -Path "C:\Chats" -Filter "*.txt" | ForEach-Object { ConvertFrom-ChatFile -FilePath $_.FullName }

	Processes all .txt files in the C:\Chats directory and returns message objects from each file.

.OUTPUTS
	System.Management.Automation.PSCustomObject[]
	Returns an array of custom objects with SessionId, Speaker, and Message properties.

.NOTES
	The function uses regex pattern matching to identify messages in the conversation.
	The file name (without extension) is used as the SessionId for all messages in that file.
#>
function ConvertFrom-ChatFile {
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
	$regexmatches = [regex]::Matches($fileContent, $regex, [System.Text.RegularExpressions.RegexOptions]::Singleline)

	foreach ($match in $regexmatches) {
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
