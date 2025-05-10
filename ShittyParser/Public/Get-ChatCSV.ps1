function Get-ChatCSV {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Url = "https://proto.notso.ai/jumbo/chats",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".\outputs",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFile = "chats.csv",
        
        [Parameter(Mandatory = $false)]
        [string]$CsvHeader = "session_id,start_time,end_time,ip_address,country,language,messages_sent,sentiment,escalated,forwarded_hr,full_transcript,avg_response_time,tokens,tokens_eur,category,initial_msg,user_rating",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("CSV", "PSObject")]
        [string]$ReturnType = "CSV",
        
        [Parameter(Mandatory = $false)]
        [string]$EnvFilePath = ".\.env"
    )
    
    # Helper function to capitalize strings
    function Capitalize {
        param ([string]$InputString)
        switch ($InputString) {
            { [string]::IsNullOrEmpty($_) } { return $null }
            default { return -join ($InputString.Substring(0, 1).ToUpper() + $InputString.Substring(1).ToLower()) }
        }
    }
    
    # Load environment variables
    if (-not (Import-Environment -FilePath $EnvFilePath)) {
        Write-Error "Failed to load environment variables."
        return $false
    }
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path $OutputFolder)) {
        Write-Host "Creating output folder: $OutputFolder"
        New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    }
    
    # Get credentials from environment variables
    $username = [Environment]::GetEnvironmentVariable("USERNAME")
    $password = [Environment]::GetEnvironmentVariable("PASSWORD")
    
    # Check if credentials are available
    if ([string]::IsNullOrEmpty($username) -or [string]::IsNullOrEmpty($password)) {
        Write-Error "Username or password not found in environment variables"
        return $false
    }
    
    # Create authentication header
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}")))
    $authHeader = @{ 
        Authorization = "Basic $base64AuthInfo"
        Accept = "application/json"
    }
    
    Write-Host "Fetching chat data from $Url..."
    
    try {
        # Make the API call to get chat data
        $response = Invoke-RestMethod -Uri $Url -Headers $authHeader -Method Get
        
        if ($response) {
            Write-Host "Retrieved $($response.Count) chat records"
            
            # Process the chat data
            $processedChats = foreach ($chat in $response) {
                # Map and transform properties as needed
                [PSCustomObject]@{
                    session_id = $chat.id
                    start_time = $chat.start_time
                    end_time = $chat.end_time
                    ip_address = $chat.ip_address
                    country = $chat.country
                    language = $chat.language
                    messages_sent = $chat.messages_sent
                    sentiment = Capitalize -InputString $chat.sentiment
                    escalated = if ($chat.escalated) { "Yes" } else { "No" }
                    forwarded_hr = if ($chat.forwarded_hr) { "Yes" } else { "No" }
                    full_transcript = $chat.full_transcript
                    avg_response_time = [math]::Round($chat.avg_response_time, 2)
                    tokens = $chat.tokens
                    tokens_eur = [math]::Round($chat.tokens * 0.0003, 3) # Example calculation
                    category = $chat.category
                    initial_msg = $chat.initial_msg
                    user_rating = $chat.user_rating
                }
            }
            
            # Determine output path
            $outputPath = Join-Path -Path $OutputFolder -ChildPath $OutputFile
            
            # Write to CSV file
            if ($ReturnType -eq "CSV") {
                # Create the output directory if it doesn't exist
                $outputDir = Split-Path -Path $outputPath -Parent
                if (-not (Test-Path -Path $outputDir)) {
                    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
                }
                
                # Write header and content to CSV
                Set-Content -Path $outputPath -Value $CsvHeader
                $processedChats | ForEach-Object {
                    $line = "$($_.session_id),$($_.start_time),$($_.end_time),$($_.ip_address),$($_.country),$($_.language),$($_.messages_sent),$($_.sentiment),$($_.escalated),$($_.forwarded_hr),$($_.full_transcript),$($_.avg_response_time),$($_.tokens),$($_.tokens_eur),$($_.category),$($_.initial_msg),$($_.user_rating)"
                    Add-Content -Path $outputPath -Value $line
                }
                
                Write-Host "Chat data saved to $outputPath" -ForegroundColor Green
            }
            
            # Return the processed data
            if ($ReturnType -eq "PSObject") {
                return $processedChats
            } else {
                return $outputPath
            }
        } else {
            Write-Warning "No chat data was returned from the API"
            return $false
        }
    }
    catch {
        Write-Error "Error fetching chat data: $_"
        return $false
    }
}
