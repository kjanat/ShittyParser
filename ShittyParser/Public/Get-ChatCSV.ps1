<#
.SYNOPSIS
	Retrieves chat data from an API or generates test data and exports it to a CSV file.

.DESCRIPTION
	The Get-ChatCSV function retrieves chat data from a specified API endpoint or generates test data when the API is unavailable. 
	It processes the data, formats it according to requirements, and can either return it as PowerShell objects or export it to a CSV file.
	
	The function handles authentication using credentials from environment variables, processes the API response,
	and applies formatting to ensure consistency in the output.

.PARAMETER Url
	The URL of the API endpoint to fetch chat data from.
	Default: 'https://proto.notso.ai/jumbo/chats'

.PARAMETER OutputFolder
	The folder where the CSV output file will be saved.
	Default: '.\outputs'

.PARAMETER OutputFile
	The filename for the CSV output.
	Default: 'chats.csv'

.PARAMETER CsvHeader
	The header string to use for the CSV file.
	Default: 'session_id,start_time,end_time,ip_address,country,language,messages_sent,sentiment,escalated,forwarded_hr,full_transcript,avg_response_time,tokens,tokens_eur,category,initial_msg,user_rating'

.PARAMETER ReturnType
	Specifies the return type of the function.
	Valid values: 'CSV', 'PSObject'
	Default: 'CSV'

.PARAMETER EnvFilePath
	Path to the .env file containing authentication credentials.
	Default: '.env'

.PARAMETER DebugMode
	When specified, enables additional debug output during execution.

.PARAMETER TestMode
	When specified, uses test data instead of calling the API.

.PARAMETER ForceTestMode
	When specified, forces the use of test data even if API credentials are available.

.EXAMPLE
	Get-ChatCSV
	Retrieves chat data from the default API URL and saves it to '.\outputs\chats.csv'.

.EXAMPLE
	Get-ChatCSV -ReturnType PSObject
	Retrieves chat data and returns it as PowerShell objects instead of saving to CSV.

.EXAMPLE
	Get-ChatCSV -TestMode -OutputFile 'test_chats.csv'
	Generates test data and saves it to '.\outputs\test_chats.csv'.

.EXAMPLE
	Get-ChatCSV -Url 'https://myapi.example.com/chats' -EnvFilePath 'production.env'
	Retrieves chat data from a custom API URL using credentials from 'production.env'.

.NOTES
	Requires the Import-Environment function to load environment variables from the .env file.
	Authentication uses Basic Auth with username and password from environment variables.
	If API access fails, test data will be used instead.

.OUTPUTS
	When ReturnType is 'CSV': The path to the created CSV file.
	When ReturnType is 'PSObject': An array of PSCustomObjects containing the processed chat data.
	If an error occurs and TestMode is not enabled: $false
#>
function Get-ChatCSV {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[string]$Url = 'https://proto.notso.ai/jumbo/chats',

		[Parameter(Mandatory = $false)]
		[string]$OutputFolder = '.\outputs',

		[Parameter(Mandatory = $false)]
		[string]$OutputFile = 'chats.csv',

		[Parameter(Mandatory = $false)]
		[string]$CsvHeader = 'session_id,start_time,end_time,ip_address,country,language,messages_sent,sentiment,escalated,forwarded_hr,full_transcript,avg_response_time,tokens,tokens_eur,category,initial_msg,user_rating',

		[Parameter(Mandatory = $false)]
		[ValidateSet('CSV', 'PSObject')]
		[string]$ReturnType = 'CSV',

		[Parameter(Mandatory = $false)]
		[ValidateScript({ Test-Path $_ -PathType Leaf })]
		[string]$EnvFilePath = '.env',

		[Parameter(Mandatory = $false)]
		[switch]$DebugMode,

		[Parameter(Mandatory = $false)]
		[switch]$TestMode,

		[Parameter(Mandatory = $false)]
		[switch]$ForceTestMode
	)

	# Helper function to capitalize strings
	function Capitalize {
		param ([string]$InputString)
		switch ($InputString) {
			{ [string]::IsNullOrEmpty($_) } {
				return $null
			}
			default {
				return -join ($InputString.Substring(0, 1).ToUpper() + $InputString.Substring(1).ToLower())
			}
		}
	}

	# Helper function to create test data if API is unavailable
	function Get-TestData {
		Write-Host 'Generating test data...' -ForegroundColor Yellow
		$testData = @(
			[PSCustomObject]@{
				id                = 'session_001'
				start_time        = '2025-05-10 10:00:00'
				end_time          = '2025-05-10 10:15:30'
				ip_address        = '192.168.1.1'
				country           = 'Netherlands'
				language          = 'Dutch'
				messages_sent     = 12
				sentiment         = 'positive'
				escalated         = $false
				forwarded_hr      = $false
				full_transcript   = 'https://proto.notso.ai/jumbo/transcripts/a49e5186-f5b5-4ded-99a6-d6b3a06fd610.txt'
				avg_response_time = 2.75
				tokens            = 356
				category          = 'General'
				initial_msg       = 'Hallo, ik heb een vraag'
				user_rating       = 4.5
			},
			[PSCustomObject]@{
				id                = 'session_002'
				start_time        = '2025-05-10 11:30:00'
				end_time          = '2025-05-10 11:45:15'
				ip_address        = '192.168.1.2'
				country           = 'Netherlands'
				language          = 'English'
				messages_sent     = 8
				sentiment         = 'neutral'
				escalated         = $true
				forwarded_hr      = $false
				full_transcript   = 'https://proto.notso.ai/jumbo/transcripts/b49e5186-f5b5-4ded-99a6-d6b3a06fd611.txt'
				avg_response_time = 3.2
				tokens            = 284
				category          = 'IT Support'
				initial_msg       = 'I need help with my account'
				user_rating       = 3.0
			}
		)
		return $testData
	}

	# Determine output path
	$outputPath = Join-Path -Path $OutputFolder -ChildPath $OutputFile

	# Create output folder if it doesn't exist
	if (-not (Test-Path $OutputFolder)) {
		Write-Host "Creating output folder: $OutputFolder"
		New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
	}

	# Set initial state for API access
	$useTestData = $TestMode -or $ForceTestMode
	$apiResponse = $null

	if (-not $useTestData) {
		# Try to load environment variables
		$envLoaded = Import-Environment -FilePath $EnvFilePath

		if ($envLoaded) {
			# Get credentials from environment variables
			$username = [Environment]::GetEnvironmentVariable('USERNAME')
			$password = [Environment]::GetEnvironmentVariable('PASSWORD')

			# Check if credentials are available
			if ([string]::IsNullOrEmpty($username) -or [string]::IsNullOrEmpty($password)) {
				Write-Warning 'Username or password not found in environment variables. Using test data instead.'
				$useTestData = $true
			} else {
				# Try to make the API call
				try {
					# Create authentication header
					$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}")))

					Write-Host "Fetching chat data from $Url..."
					$rawResponse = Invoke-RestMethod -Uri $Url -Method Get -Headers @{
						Authorization = "Basic $base64AuthInfo"
					}

					if ($DebugMode) {
						Write-Host 'API response received:'
						Write-Host "  Type: $($rawResponse.GetType().FullName)"
						Write-Host "  Is Array: $($rawResponse -is [Array])"
						Write-Host "  Length: $(if ($rawResponse -is [string]) { $rawResponse.Length } else { $rawResponse.Count })"
					}

					# Handle the response as CSV instead of JSON
					if ($rawResponse -is [string]) {
						try {
							Write-Host 'Response is a string. Processing as CSV...'

							# Create a temporary file to store the CSV data
							$tempFile = [System.IO.Path]::GetTempFileName()

							# Add the header first, then the CSV content
							$CsvHeader | Out-File -FilePath $tempFile -Encoding utf8
							$rawResponse | Out-File -FilePath $tempFile -Encoding utf8 -Append

							# Import the CSV file
							$apiResponse = Import-Csv -Path $tempFile

							# Clean up the temp file
							Remove-Item -Path $tempFile -Force

							if ($DebugMode) {
								Write-Host 'After CSV parsing:'
								Write-Host "  Type: $($apiResponse.GetType().FullName)"
								Write-Host "  Is Array: $($apiResponse -is [Array])"
								Write-Host "  Count: $($apiResponse.Count)"
								if ($apiResponse -is [Array] -and $apiResponse.Count -gt 0) {
									Write-Host '  First item properties:'
									$apiResponse[0] | Get-Member -MemberType Properties | ForEach-Object { Write-Host "    $($_.Name)" }
								} elseif ($apiResponse -isnot [Array]) {
									Write-Host '  Properties:'
									$apiResponse | Get-Member -MemberType Properties | ForEach-Object { Write-Host "    $($_.Name)" }
								}
							}
						} catch {
							Write-Warning "Failed to parse response as CSV: $_"
							$useTestData = $true
						}
					} else {
						# Response was already parsed properly
						$apiResponse = $rawResponse
					}

					# Check if the API response is empty or invalid
					if ($null -eq $apiResponse -or ($apiResponse -is [Array] -and $apiResponse.Count -eq 0)) {
						Write-Warning 'API returned empty response. Using test data instead.'
						$useTestData = $true
					}
				} catch {
					Write-Warning "Error accessing API: $_"
					Write-Warning 'Using test data instead.'
					$useTestData = $true
				}
			}
		} else {
			Write-Warning 'Failed to load environment variables. Using test data instead.'
			$useTestData = $true
		}
	}

	# Process the data
	try {
		if ($useTestData) {
			$response = Get-TestData
			Write-Host "Using test data with $($response.Count) records."
		} else {
			$response = $apiResponse
			Write-Host "Using API data with $($response.Count) records."
		}

		if ($null -eq $response) {
			Write-Warning 'No data available. Creating empty record.'
			$processedChats = @()
		} elseif ($response -is [Array]) {
			Write-Host "Processing $($response.Count) chat records..."
			$processedChats = foreach ($chat in $response) {
				[PSCustomObject]@{
					session_id        = $chat.session_id
					start_time        = (Get-Date $chat.start_time).ToString('yyyy-MM-dd HH:mm:ss')
					end_time          = (Get-Date $chat.end_time).ToString('yyyy-MM-dd HH:mm:ss')
					ip_address        = $chat.ip_address
					country           = $chat.country.ToUpper()
					language          = Capitalize -InputString $chat.language
					messages_sent     = $chat.messages_sent
					sentiment         = Capitalize -InputString $chat.sentiment
					escalated         = if ($chat.escalated) {
						'Yes'
					} else {
						'No'
					}
					forwarded_hr      = if ($chat.forwarded_hr) {
						'Yes'
					} else {
						'No'
					}
					full_transcript   = $chat.full_transcript
					avg_response_time = if ($null -eq $chat.avg_response_time) {
						0
					} else {
						[math]::Round($chat.avg_response_time, 2)
					}
					tokens            = $chat.tokens
					tokens_eur        = $chat.tokens_eur #[math]::Round($chat.tokens * 0.0003, 3)
					category          = $chat.category
					initial_msg       = $chat.initial_msg
					user_rating       = $chat.user_rating
				}
			}
		} else {
			Write-Host 'Processing single chat record...'
			$processedChats = @([PSCustomObject]@{
					session_id        = $response.id
					start_time        = $response.start_time
					end_time          = $response.end_time
					ip_address        = $response.ip_address
					country           = $response.country
					language          = $response.language
					messages_sent     = $response.messages_sent
					sentiment         = Capitalize -InputString $response.sentiment
					escalated         = if ($response.escalated) {
						'Yes'
					} else {
						'No'
					}
					forwarded_hr      = if ($response.forwarded_hr) {
						'Yes'
					} else {
						'No'
					}
					full_transcript   = $response.full_transcript
					avg_response_time = if ($null -eq $response.avg_response_time) {
						0
					} else {
						[math]::Round($response.avg_response_time, 2)
					}
					tokens            = $response.tokens
					tokens_eur        = if ($null -eq $response.tokens) {
						0
					} else {
						[math]::Round($response.tokens * 0.0003, 3)
					}
					category          = $response.category
					initial_msg       = $response.initial_msg
					user_rating       = $response.user_rating
				})
		}

		# Always ensure we have at least one record for the CSV
		if ($processedChats.Count -eq 0) {
			Write-Warning 'No records processed. Creating sample record to avoid empty CSV.'
			$processedChats = @([PSCustomObject]@{
					session_id        = 'sample_001'
					start_time        = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
					end_time          = (Get-Date).AddMinutes(15).ToString('yyyy-MM-dd HH:mm:ss')
					ip_address        = '127.0.0.1'
					country           = 'Sample'
					language          = 'English'
					messages_sent     = 5
					sentiment         = 'Neutral'
					escalated         = 'No'
					forwarded_hr      = 'No'
					full_transcript   = 'https://example.com/transcript_sample.txt'
					avg_response_time = 2.5
					tokens            = 150
					tokens_eur        = 0.045
					category          = 'Sample'
					initial_msg       = 'This is a sample message'
					user_rating       = 3.5
				})
		}

		# Write to CSV file
		if ($ReturnType -eq 'CSV') {
			try {
				# Create direct CSV using Export-Csv
				Write-Host "Creating CSV file at $outputPath..."

				# Create custom columns for direct export
				$customOutput = $processedChats | Select-Object @{Name = 'session_id'; Expression = { $_.session_id } },
				@{Name = 'start_time'; Expression = { $_.start_time } },
				@{Name = 'end_time'; Expression = { $_.end_time } },
				@{Name = 'ip_address'; Expression = { $_.ip_address } },
				@{Name = 'country'; Expression = { $_.country } },
				@{Name = 'language'; Expression = { $_.language } },
				@{Name = 'messages_sent'; Expression = { $_.messages_sent } },
				@{Name = 'sentiment'; Expression = { $_.sentiment } },
				@{Name = 'escalated'; Expression = { $_.escalated } },
				@{Name = 'forwarded_hr'; Expression = { $_.forwarded_hr } },
				@{Name = 'full_transcript'; Expression = { $_.full_transcript } },
				@{Name = 'avg_response_time'; Expression = { $_.avg_response_time } },
				@{Name = 'tokens'; Expression = { $_.tokens } },
				@{Name = 'tokens_eur'; Expression = { $_.tokens_eur } },
				@{Name = 'category'; Expression = { $_.category } },
				@{Name = 'initial_msg'; Expression = { $_.initial_msg } },
				@{Name = 'user_rating'; Expression = { $_.user_rating } }

				# Export directly to CSV
				$customOutput | Export-Csv -Path $outputPath -NoTypeInformation

				Write-Host "Chat data saved to $outputPath" -ForegroundColor Green

				# Validate the file was created and has content
				if (Test-Path $outputPath) {
					$lines = (Get-Content $outputPath).Count
					Write-Host "CSV file contains $lines lines (including header)" -ForegroundColor Green

					if ($lines -le 1) {
						Write-Warning 'CSV file contains only a header. No data rows were written.'
					}
				} else {
					Write-Error 'Failed to create CSV file.'
				}
			} catch {
				Write-Error "Error writing to CSV: $_"
				return $false
			}
		}

		# Return the processed data
		if ($ReturnType -eq 'PSObject') {
			return $processedChats
		} else {
			return $outputPath
		}
	} catch {
		Write-Error "Error processing chat data: $_"

		if ($DebugMode) {
			Write-Host 'Exception details:'
			Write-Host "  Type: $($_.Exception.GetType().FullName)"
			Write-Host "  Message: $($_.Exception.Message)"
			if ($_.Exception.InnerException) {
				Write-Host "  Inner Exception: $($_.Exception.InnerException.Message)"
			}
		}

		# Always return test data if there's an error and we're in test mode
		if ($TestMode -or $ForceTestMode) {
			Write-Host 'Returning test data due to error in processing.' -ForegroundColor Yellow
			return (Get-TestData | Select-Object * | Export-Csv -Path $outputPath -NoTypeInformation)
		}

		return $false
	}
}
