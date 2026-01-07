$ErrorActionPreference = "Continue"

# List of files to update
$files = @(
    "lib\screens\founder_home_screen.dart",
    "lib\screens\finder_home_screen.dart",
    "lib\screens\notifications_screen.dart",
    "lib\screens\chat_screen.dart",
    "lib\screens\chat_list_screen.dart",
    "lib\screens\founder_requests_screen.dart",
    "lib\screens\finder_status_screen.dart"
)

foreach ($file in $files) {
    $path = "c:\Users\Glen Umadhay\OneDrive\Desktop\LostAndFoundFlutter\$file"
    
    if (Test-Path $path) {
        $content = Get-Content $path -Raw -Encoding UTF8
        $originalContent = $content
        
        # Replace Provider.of<FirebaseDatabaseService> with Provider.of<FirebaseDatabaseService>
        $content = $content -replace 'Provider\.of<DatabaseService>', 'Provider.of<FirebaseDatabaseService>'
        
        if ($content -ne $originalContent) {
            Set-Content -Path $path -Value $content -NoNewline -Encoding UTF8
            Write-Host "Updated: $file"
        } else {
            Write-Host "No changes needed: $file"
        }
    } else {
        Write-Host "File not found: $file"
    }
}

Write-Host "`nAll files updated!"
