@echo off
echo ========================================
echo BurnGuard - Quick Run on Emulator
echo ========================================
echo.
echo Checking emulator connection...
D:\Env\ANDROID\platform-tools\adb.exe devices

echo.
echo Installing APK...
D:\Env\ANDROID\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk

echo.
echo Launching app...
D:\Env\ANDROID\platform-tools\adb.exe shell am start -n com.burnguard.burn_guard/.MainActivity

echo.
echo ========================================
echo App launched successfully!
echo ========================================
pause
