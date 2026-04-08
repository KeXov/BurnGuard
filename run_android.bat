@echo off
echo ========================================
echo BurnGuard Quick Run Script
echo ========================================
echo.
echo Starting app on emulator...
echo Note: First run will download Gradle dependencies (may take 5-10 minutes)
echo.
call flutter run -d emulator-5554

pause
