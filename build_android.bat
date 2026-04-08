@echo off
echo ========================================
echo BurnGuard Android Build Script
echo ========================================
echo.

echo [1/3] Cleaning previous build...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Building APK...
echo Note: First build may take 5-10 minutes due to Gradle download
echo Please wait...
call flutter build apk --debug --verbose

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Build Successful!
    echo APK location: build\app\outputs\flutter-apk\app-debug.apk
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Build Failed!
    echo Please check the error messages above.
    echo ========================================
)

pause
