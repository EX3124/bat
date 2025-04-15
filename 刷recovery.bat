@echo off
chcp 65001
setlocal enabledelayedexpansion

REM 全局变量
set DOWNLOAD_URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip
set EXTRACT_DIR=extract

echo github.com/EX3124/bat
echo.
echo.
echo.
echo.

:DOWNLOAD
if exist %EXTRACT_DIR% (
    rmdir /S /Q %EXTRACT_DIR%
)
if exist platform-tools-latest-windows.zip (
    del platform-tools-latest-windows.zip
)

echo 下载Android SDK Platform-Tools
powershell -Command "Invoke-WebRequest -Uri %DOWNLOAD_URL% -OutFile platform-tools-latest-windows.zip"
if %ERRORLEVEL% neq 0 (
    echo 下载失败,正在重试
    goto DOWNLOAD
)

REM 解压
if not exist %EXTRACT_DIR% (
    mkdir %EXTRACT_DIR%
)
tar -xf platform-tools-latest-windows.zip -C %EXTRACT_DIR%
del platform-tools-latest-windows.zip
cls

:INPUT
echo 把文件拖到此窗口,然后按下回车
set /p FILE_PATH="已选择的文件: "
set FILE_PATH=%FILE_PATH:"=%
cls
echo 已选择的文件: %FILE_PATH%

REM 检查文件是否存在
if not exist "%FILE_PATH%" (
    echo 找不到文件,请确认它是否可用
    echo.
    goto INPUT
)

REM 去除括号
for %%f in ("%FILE_PATH%") do (
    set FILE_NAME=%%~nxf
    set NEW_FILE_NAME=%%~nxf
)
set NEW_FILE_NAME=%NEW_FILE_NAME:(=%
set NEW_FILE_NAME=%NEW_FILE_NAME:) =%
ren "%FILE_PATH%" "%NEW_FILE_NAME%"
set FILE_PATH=%~dp0%NEW_FILE_NAME%

REM 获取文件名
for %%f in ("%FILE_PATH%") do (
    set FILE_NAME=%%~nxf
    set FILE_SIZE=%%~zf
    if !FILE_SIZE! gtr 157286400 (
        echo 文件太大了,它可能不是rec
        echo.
        goto INPUT
    )
)

REM 检查文件名是否包含指定字样
set "EXTENSION=%FILE_NAME:~-3%"
if "%EXTENSION%" == "zip" (
    if not "%FILE_NAME:rec=%"=="%FILE_NAME%" (
        goto EXTRACT_ZIP
    ) else if not "%FILE_NAME:twrp=%"=="%FILE_NAME%" (
        goto EXTRACT_ZIP
    ) else if not "%FILE_NAME:orangefox=%"=="%FILE_NAME%" (
        goto EXTRACT_ZIP
    ) else (
        echo 文件名中不包含rec,twrp,orangefox,它可能不是rec
        echo.
        goto INPUT
    )
) else if "%EXTENSION%"=="img" (
    copy %FILE_PATH% %EXTRACT_DIR% >nul 2>&1
    goto CHECK_FASTBOOT
) else (
    echo 不是.zip或.img文件
    echo.
    goto INPUT
)

:EXTRACT_ZIP
if not exist %EXTRACT_DIR%\%FILE_NAME:~0,-4% (
    mkdir %EXTRACT_DIR%\%FILE_NAME:~0,-4%
)
tar -xf "%FILE_PATH%" -C %EXTRACT_DIR%\%FILE_NAME:~0,-4% >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo 解压失败,请检查文件是否损坏
    echo.
    goto INPUT
)

:CHECK_FASTBOOT
cls
echo 已选择的文件: %FILE_PATH%
set DEVICE_FOUND=false
set DEVICE_COUNT=0
for /f "tokens=1" %%i in ('%EXTRACT_DIR%\platform-tools\fastboot.exe devices') do (
    set DEVICE=%%i
    set DEVICE_FOUND=true
    set /a DEVICE_COUNT+=1
)
if "%DEVICE_FOUND%"=="false" (
    goto NO_DEVICE_FOUND
)
if %DEVICE_COUNT% gtr 1 (
    echo.
    echo 检测到多台设备,请断开它们,只留一台设备
    echo.
    goto ERETRY
) 
echo 已连接的设备: %DEVICE%
echo.

:FLASH_IMG
for /R %EXTRACT_DIR% %%i in (*.img) do (
    echo 使用img文件: %%i
    for /f "tokens=*" %%j in ('%EXTRACT_DIR%\platform-tools\fastboot.exe flash recovery %%i 2^>^&1') do (
        set "CHECK_FLASH=%%j"
        echo !CHECK_FLASH!
    )
    if "!CHECK_FLASH:Finished=!"=="!CHECK_FLASH!" (
        echo 刷入失败
        goto CHECK_FASTBOOT
    )
    %EXTRACT_DIR%\platform-tools\fastboot.exe reboot recovery >nul 2>&1
    goto CLEANUP
)

:NO_DEVICE_FOUND
echo.
echo 没有检测到设备在fastboot模式下
echo.
echo 请检查设备是否进入了fastboot模式(页面带有 蓝色或橙色 FASTBOOT 字样)
echo 如果已进入fastboot模式,请检查设备与电脑的连接,以及是否安装了小米线刷工具内的驱动
echo.

:ERETRY
set /p RETRY="重试? (y/n)"
if /I "%RETRY%"=="y" (
    goto CHECK_FASTBOOT
) else if /I "%RETRY%"=="yes" (
    goto CHECK_FASTBOOT
) else if /I "%RETRY%"=="是" (
    goto CHECK_FASTBOOT
) else (
    rmdir /s /q %EXTRACT_DIR%\%FILE_NAME:~0,-4%
    cls
    goto INPUT
)

:CLEANUP
rmdir /S /Q %EXTRACT_DIR%
echo.
echo 运行结束

endlocal
pause