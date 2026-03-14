Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$sourceFile = "C:\Users\Theme\OneDrive\Documentos\projects\gu i\NativefierGUI.ps1"
$outputExe  = "C:\Users\Theme\OneDrive\Documentos\projects\gu i\NativefierGUI.exe"

Write-Host ""
Write-Host "  NativefierGUI EXE Builder" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $sourceFile)) {
    Write-Host "  ERROR: NativefierGUI.ps1 not found at:" -ForegroundColor Red
    Write-Host "  $sourceFile" -ForegroundColor DarkGray
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  [1/3] Installing ps2exe..." -ForegroundColor Yellow

try {
    Install-Module ps2exe -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
    Write-Host "        Done" -ForegroundColor Green
} catch {
    Write-Host "        WARNING: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

try {
    Import-Module ps2exe -Force -ErrorAction Stop
    Write-Host "        Imported OK" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Could not import ps2exe" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkGray
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "  [2/3] Compiling..." -ForegroundColor Yellow
Write-Host "        $sourceFile" -ForegroundColor DarkGray
Write-Host "     -> $outputExe"  -ForegroundColor DarkGray
Write-Host ""

try {
    Invoke-ps2exe `
        -InputFile  $sourceFile `
        -OutputFile $outputExe `
        -NoConsole `
        -Title       "NativefierGUI" `
        -Description "Convert websites to desktop apps" `
        -Company     "NativefierGUI" `
        -Version     "2.0.0.0" `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "  [3/3] SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  EXE is here:" -ForegroundColor Cyan
    Write-Host "  $outputExe" -ForegroundColor White
    Write-Host ""

    Start-Process explorer.exe -ArgumentList "/select,`"$outputExe`""

} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Trying fallback command..." -ForegroundColor Yellow

    try {
        ps2exe `
            -InputFile  $sourceFile `
            -OutputFile $outputExe `
            -NoConsole

        Write-Host "  Fallback worked!" -ForegroundColor Green
        Start-Process explorer.exe -ArgumentList "/select,`"$outputExe`""

    } catch {
        Write-Host "  Fallback also failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Try running this manually in PowerShell:" -ForegroundColor Yellow
        Write-Host "  Import-Module ps2exe" -ForegroundColor White
        Write-Host "  Invoke-ps2exe -InputFile '$sourceFile' -OutputFile '$outputExe' -NoConsole" -ForegroundColor White
    }
}

Write-Host ""
Read-Host "Press Enter to exit"