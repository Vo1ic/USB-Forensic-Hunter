@echo off
:: ============================================================
:: Name:        USB Forensic Hunter
:: Version:     9.0 
:: Author:      Vo1ic
:: ============================================================

:: --- 1. ADMIN CHECK ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Admin rights required. Relaunching...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: --- 2. SETUP CONSOLE ---
:: Вмикаємо UTF-8
chcp 65001 > nul
title USB Forensic Hunter v9.0
color B
cls

:MENU
cls
echo ============================================================
echo               USB FORENSIC HUNTER v9.0
echo ============================================================
echo.
echo    [1] SIMPLE REPORT
echo        (Category, Name, ID)
echo.
echo    [2] DEEP FORENSIC SCAN
echo        (Manufacturer, Driver, Port, Config, Dates)
echo.
echo    [0] EXIT
echo.
echo ============================================================

:: --- FIX: Очищаємо змінну перед вводом ---
set "mode="
set /p mode="Select Mode (0-2): "

:: Перевірка на пустий ввід (просто Enter)
if not defined mode goto MENU

if "%mode%"=="0" exit
if "%mode%"=="1" set "PS_MODE=Simple"
if "%mode%"=="2" set "PS_MODE=Deep"

:: Якщо ввели щось, чого немає в меню (наприклад "5"), повертаємось
if not defined PS_MODE goto MENU

cls
echo ============================================================
echo          RUNNING: %PS_MODE% USB SCAN...
echo ============================================================
echo.

:: --- 3. BUILD POWERSHELL SCRIPT ---
set "PS_FILE=%TEMP%\usb_scan_v9.ps1"
if exist "%PS_FILE%" del "%PS_FILE%"

:: --- FIX: Змушуємо консоль PowerShell розуміти UTF-8 на вивід ---
echo [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 >> "%PS_FILE%"

echo $ScanMode = '%PS_MODE%' >> "%PS_FILE%"
echo $ErrorActionPreference = 'SilentlyContinue' >> "%PS_FILE%"
echo $report = @() >> "%PS_FILE%"
echo $root = 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB' >> "%PS_FILE%"
echo $devices = Get-ChildItem -Path $root -ErrorAction SilentlyContinue >> "%PS_FILE%"
echo foreach ($dev in $devices) { >> "%PS_FILE%"
echo     try { >> "%PS_FILE%"
echo         $instances = Get-ChildItem -Path $dev.PSPath -ErrorAction Stop >> "%PS_FILE%"
echo         foreach ($inst in $instances) { >> "%PS_FILE%"
echo             try { >> "%PS_FILE%"
echo                 $props = Get-ItemProperty -Path $inst.PSPath -ErrorAction SilentlyContinue >> "%PS_FILE%"
echo                 $name = $props.FriendlyName >> "%PS_FILE%"
echo                 if (!$name) { $name = $props.DeviceDesc } >> "%PS_FILE%"
echo                 if (!$name) { $name = "Unknown Device" } >> "%PS_FILE%"
echo                 if ($ScanMode -eq 'Simple') { >> "%PS_FILE%"
echo                     $report += [PSCustomObject]@{ >> "%PS_FILE%"
echo                         'Category'    = $props.Class >> "%PS_FILE%"
echo                         'Device Name' = $name >> "%PS_FILE%"
echo                         'Hardware ID' = $dev.PSChildName >> "%PS_FILE%"
echo                     } >> "%PS_FILE%"
echo                 } >> "%PS_FILE%"
echo                 if ($ScanMode -eq 'Deep') { >> "%PS_FILE%"
echo                     $mfg = $props.Mfg >> "%PS_FILE%"
echo                     if (!$mfg) { $mfg = 'N/A' } >> "%PS_FILE%"
echo                     $service = $props.Service >> "%PS_FILE%"
echo                     if (!$service) { $service = 'N/A' } >> "%PS_FILE%"
echo                     $loc = $props.LocationInformation >> "%PS_FILE%"
echo                     if (!$loc) { $loc = 'N/A' } >> "%PS_FILE%"
echo                     $report += [PSCustomObject]@{ >> "%PS_FILE%"
echo                         'Class'       = $props.Class >> "%PS_FILE%"
echo                         'Device Name' = $name >> "%PS_FILE%"
echo                         'Manufacturer'= $mfg >> "%PS_FILE%"
echo                         'Driver'      = $service >> "%PS_FILE%"
echo                         'Location'    = $loc >> "%PS_FILE%"
echo                     } >> "%PS_FILE%"
echo                 } >> "%PS_FILE%"
echo             } catch {} >> "%PS_FILE%"
echo         } >> "%PS_FILE%"
echo     } catch {} >> "%PS_FILE%"
echo } >> "%PS_FILE%"
echo $report ^| Sort-Object 'Class' ^| Format-Table -AutoSize >> "%PS_FILE%"

:: --- 4. EXECUTE ---
if exist "%PS_FILE%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%"
) else (
    echo [ERROR] Failed to generate script.
)

:: Clean up
if exist "%PS_FILE%" del "%PS_FILE%"

echo.
echo ============================================================
echo Scan Complete.
echo Press any key to return to menu...
pause > nul
goto MENU
