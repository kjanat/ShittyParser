# ShittyParser

A PowerShell module for downloading, parsing, and processing chat transcripts from Notso AI's chat system.

## Overview

ShittyParser provides tools to:

1. Download chat data from the API endpoint and save it as CSV
2. Download individual chat transcripts based on URLs in the CSV file
3. Parse chat transcripts to extract messages from Users and Assistants
4. Create structured output in JSON, CSV, or PS1 formats
5. Combine multiple transcripts into a single output file

## Installation

### Option 1: Clone the Repository

```powershell
# Clone the repository
git clone 'https://github.com/kjanat/ShittyParser.git'
cd ShittyParser

# Import the module
Import-Module ./ShittyParser
```

### Option 2: Install from PowerShell Gallery

```powershell
# Not yet available on PowerShell Gallery
# Install-Module -Name ShittyParser
```

## Configuration

Create a .env file in the root directory with your API credentials:

```sh
USERNAME=yourusername
PASSWORD=yourpassword
URL=https://<host>/<customer>/chats
```

The module will search for the .env file in several locations:

- Current directory
- Root of the project
- Parent directory of the module
- Two levels up from the module directory

## Usage

### Using the Module Functions Directly

```powershell
# Import the module
Import-Module ShittyParser

# Get chat data from API and save to CSV
Get-ChatCSV -OutputFolder "outputs" -OutputFile "chats.csv"

# Download chat transcripts from URLs in the CSV
Get-Transcripts -CsvPath "outputs/chats.csv" -OutputFolder "outputs/transcripts"

# Parse chat transcripts and extract structured data
Parse-Chats -Directory "outputs/transcripts" -OutputDirectory "outputs/parsed" -SaveToFile -OutputFormat "JSON"

# Do it all in one step (download + parse into a single combined file)
Get-CombinedChats -OutputFileName "all_chats" -OutputFormat "JSON"
```

### Using the Wrapper Scripts

```powershell
# Get chat data from API and save to CSV
Get-CSV.ps1

# Download chat transcripts from URLs in the CSV
Download-Chats.ps1

# Parse chat transcripts and extract structured data
Parse-Chats.ps1 -SaveToFile -OutputFormat "JSON"

# Do it all in one step (download + parse into a single combined file)
Get-CombinedChats.ps1 -OutputFileName "all_chats"
```

## Functions

### Get-ChatCSV

Downloads chat data from the API and saves it as a CSV file.

```powershell
Get-ChatCSV -Url "https://<host>/<customer>/chats" -OutputFolder "outputs" -OutputFile "chats.csv"
```

Parameters:

- `Url`: API endpoint URL
- `OutputFolder`: Folder where the CSV file will be saved
- `OutputFile`: Name of the CSV file
- `CsvHeader`: Header string for the CSV (if API returns headerless data)
- `ReturnType`: Format to return data ("CSV" or "PSObject")
- `EnvFilePath`: Path to the .env file with credentials
- `DebugMode`: Enable detailed diagnostic information
- `TestMode`: Use test data instead of making API calls

### Get-Transcripts

Downloads chat transcripts from URLs listed in the CSV file.

```powershell
Get-Transcripts -CsvPath "outputs/chats.csv" -OutputFolder "outputs/transcripts" -Force
```

Parameters:

- `CsvPath`: Path to the CSV file with transcript URLs
- `OutputFolder`: Folder where transcript files will be saved
- `Force`: Force re-download of existing files
- `EnvFilePath`: Path to the .env file with credentials

### Parse-Chats

Parses chat transcript files to extract structured message data.

```powershell
Parse-Chats -Directory "outputs/transcripts" -OutputDirectory "outputs/parsed" -SaveToFile -OutputFormat "JSON" -CombinedOnly
```

Parameters:

- `FilePath`: Path to a single transcript file to parse
- `Directory`: Directory containing transcript files to parse
- `OutputDirectory`: Directory to save parsed output files
- `SaveToFile`: Save parsed data to files
- `OutputFormat`: Format for output files ("JSON", "CSV", or "PS1")
- `CombinedOnly`: Create only a combined file, not individual files

### Get-CombinedChats

Combines downloading and parsing in one operation, creating a single output file.

```powershell
Get-CombinedChats -OutputFileName "all_chats" -OutputFormat "JSON" -SkipDownload
```

Parameters:

- `CsvPath`: Path to the CSV file with transcript URLs
- `OutputFolder`: Folder where transcript files will be saved
- `ParsedOutputFolder`: Folder where parsed output will be saved
- `OutputFormat`: Format for output files ("JSON", "CSV", or "PS1")
- `OutputFileName`: Custom name for the output file
- `Force`: Force re-download of existing files
- `SkipDownload`: Skip downloading and only parse existing files
- `EnvFilePath`: Path to the .env file with credentials

## Output Formats

The module supports three output formats:

- **JSON**: Best for data interchange and API usage
- **CSV**: Good for spreadsheet analysis
- **PS1**: PowerShell format for direct script inclusion

## Example Output Structure

```json
[
    {
        "SessionId": "a49e5186-f5b5-4ded-99a6-d6b3a06fd610",
        "Speaker": "User",
        "Message": "Ja slaapkop"
    },
    {
        "SessionId": "a49e5186-f5b5-4ded-99a6-d6b3a06fd610",
        "Speaker": "Assistant",
        "Message": "Haha, ik ben weer helemaal wakker nu! ☀️ Wat kan ik je helpen vandaag?"
    }
]
```

## Troubleshooting

If you encounter issues with the module:

1. **API Credentials**: Ensure your .env file exists and contains the correct credentials
2. **CSV Headers**: The module automatically adds headers to CSV data if necessary
3. **Debug Mode**: Use the `-DebugMode` switch to see detailed diagnostic information
4. **Test Mode**: Use the `-TestMode` switch to generate test data without making API calls

## License

This project does not have a license yet. Feel free to use it for personal projects, but please do not redistribute without permission.

## Acknowledgments

- Created for processing Notso AI chat data
- Built with PowerShell 5.1+
