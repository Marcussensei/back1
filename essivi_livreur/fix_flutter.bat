@echo off
REM Script pour fixer les problèmes Flutter sur Windows
REM Tue les processus bloqués et nettoie le cache

echo ======================================
echo  FLUTTER FIX - Windows Build Issue
echo ======================================
echo.

echo [1/4] Killing Flutter/Dart processes...
taskkill /IM dart.exe /F 2>nul || echo  (No dart.exe running)
taskkill /IM chrome.exe /F 2>nul || echo  (No chrome.exe running)
taskkill /IM edge.exe /F 2>nul || echo  (No edge.exe running)
timeout /t 2 /nobreak

echo.
echo [2/4] Cleaning Flutter build...
flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed
    exit /b 1
)

echo.
echo [3/4] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed
    exit /b 1
)

echo.
echo [4/4] Ready to run!
echo ======================================
echo.
echo Next: flutter run -d chrome
echo ======================================
