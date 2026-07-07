# ==========================================
# TOOTH FAIRY - Local Development Launcher
# ==========================================

Write-Host "Starting TOOTH FAIRY Backend Microservices..." -ForegroundColor Cyan

$backendDir = Join-Path $PSScriptRoot "backend"
Set-Location $backendDir

if (-Not (Test-Path "venv\Scripts\python.exe")) {
    Write-Host "Virtual environment not found! Please run the setup first." -ForegroundColor Red
    exit 1
}

# Start the FastAPI server using Uvicorn
& .\venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
