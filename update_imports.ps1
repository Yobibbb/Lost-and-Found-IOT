# Update all screen files to use FirebaseDatabaseService
$screenFiles = Get-ChildItem -Path "lib\screens" -Filter *.dart

foreach ($file in $screenFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "import '../services/database_service.dart';", "import '../services/firebase_database_service.dart';"
    $content = $content -replace "Provider\.of<DatabaseService>", "Provider.of<FirebaseDatabaseService>"
    Set-Content -Path $file.FullName -Value $content -NoNewline
}

Write-Host "Updated all screen files to use FirebaseDatabaseService"
