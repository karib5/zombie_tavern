Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       ZOMBIE TAVERN GIT RESET" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

git status --short

Write-Host ""
$confirm = Read-Host "WARNING: Delete ALL uncommitted changes and untracked files? Type YES"

if ($confirm -ne "YES") {
    Write-Host ""
    Write-Host "Reset cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Resetting tracked files..." -ForegroundColor Yellow
git restore .

Write-Host "Removing untracked files..." -ForegroundColor Yellow
git clean -fd

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "       PROJECT RESET COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

git status

Read-Host "Press Enter to close"