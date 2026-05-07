# Define the script function
function GetFileNames {
    param (
        [string]$FolderPath = $PWD.Path # Default to the working directory if no path is specified
    )

    # Check if the folder exists
    if (!(Test-Path -Path $FolderPath)) {
        Write-Host "Error: Folder path '$FolderPath' does not exist." -ForegroundColor Red
        return
    }

    # Define the output file path within the specified folder
    $OutputFilePath = Join-Path -Path $FolderPath -ChildPath "file_list.txt"

    # Get all file names in the folder (no subdirectories)
    $FileNames = Get-ChildItem -Path $FolderPath -File | Select-Object -ExpandProperty Name

    # Write the file names to the output file
    $FileNames | Out-File -FilePath $OutputFilePath -Encoding UTF8

    # Confirmation message
    Write-Host "File names have been successfully written to $OutputFilePath" -ForegroundColor Green
}

GetFileNames