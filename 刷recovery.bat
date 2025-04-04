@echo off
chcp 65001
setlocal enabledelayedexpansion

REM 全局变量
set DOWNLOAD_URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip
set FILE_NAME=platform-tools-latest-windows.zip
set EXTRACT_DIR=extract

echo github.com/EX3124/bat
echo.
echo.
echo.
echo.

:DOWNLOAD
echo 删除之前的文件
if exist %EXTRACT_DIR% (
    rmdir /S /Q %EXTRACT_DIR%
)
if exist %FILE_NAME% (
    del %FILE_NAME%
)

echo 下载最新的Android SDK Platform-Tools
powershell -Command "Invoke-WebRequest -Uri %DOWNLOAD_URL% -OutFile %FILE_NAME%"
if %ERRORLEVEL% neq 0 (
    echo 下载失败,重试
    goto DOWNLOAD
)

REM 解压
if not exist %EXTRACT_DIR% (
    mkdir %EXTRACT_DIR%
)
tar -xf %FILE_NAME% -C %EXTRACT_DIR%
del %FILE_NAME%

:INPUT
set /p FILE_PATH="输入文件路径(或把文件拖到此窗口),接受zip和img: "
set FILE_PATH=%FILE_PATH:"=%

REM 检查文件是否存在
if not exist "%FILE_PATH%" (
    echo 找不到文件,请确认它是否可用
    goto INPUT
)

REM 获取文件名并去除括号
for %%f in ("%FILE_PATH%") do (
    set FILE_NAME=%%~nxf
    set NEW_FILE_NAME=%%~nxf
)
set NEW_FILE_NAME=%NEW_FILE_NAME:(=%
set NEW_FILE_NAME=%NEW_FILE_NAME:) =%
ren "%FILE_PATH%" "%NEW_FILE_NAME%"
set FILE_PATH=%~dp0%NEW_FILE_NAME%

REM 获取文件名
for %%f in ("%FILE_PATH%") do set FILE_NAME=%%~nxf
echo %FILE_NAME%

REM 检查文件名是否包含指定字样
set "EXTENSION=%FILE_NAME:~-3%"
if "%EXTENSION%" == "zip" (
    if not "%FILE_NAME:rec=%"=="%FILE_NAME%" (
        tar -xf "%FILE_PATH%" -C %EXTRACT_DIR%
        goto CHECK_FASTBOOT
    ) else if not "%FILE_NAME:twrp=%"=="%FILE_NAME%" (
        tar -xf "%FILE_PATH%" -C %EXTRACT_DIR%
        goto CHECK_FASTBOOT
    ) else if not "%FILE_NAME:orangefox=%"=="%FILE_NAME%" (
        tar -xf "%FILE_PATH%" -C %EXTRACT_DIR%
        goto CHECK_FASTBOOT
    ) else (
        echo 文件名中不包含rec,twrp,orangefox,它可能不是rec
        goto INPUT
    )
) else if "%EXTENSION%"=="img" (
    copy %FILE_PATH% %EXTRACT_DIR% >nul 2>&1
    goto CHECK_FASTBOOT
) else (
    echo 不是.zip或.img文件
    goto INPUT
)

:CHECK_FASTBOOT
echo 检查设备是否处于fastboot模式
set DEVICE_FOUND=false
for /f "tokens=1" %%i in ('%EXTRACT_DIR%\platform-tools\fastboot.exe devices') do (
    set DEVICE=%%i
    set DEVICE_FOUND=true
)
if "%DEVICE_FOUND%"=="false" (
    goto NO_DEVICE_FOUND
)
echo sn: %DEVICE% 

:FLASH_IMG
REM 遍历解压目录中的 img 文件并刷写 recovery
for /R %EXTRACT_DIR% %%i in (*.img) do (
    echo Flashing %%i
    for /f "tokens=*" %%j in ('%EXTRACT_DIR%\platform-tools\fastboot.exe flash recovery %%i 2^>^&1') do (
        set "CHECK_FLASH=%%j"
        echo !CHECK_FLASH!
    )
    if "!CHECK_FLASH:Finished=!"=="!CHECK_FLASH!" (
        goto CHECK_FASTBOOT
    )
    goto CLEANUP
)

:NO_DEVICE_FOUND
echo 没有检测到有设备在fastboot模式下,请检查手机与电脑的连接,以及是否安装了驱动

set /p RETRY="重试? (y/n)"
if /I "%RETRY%"=="y" (
    goto CHECK_FASTBOOT
) else if /I "%RETRY%"=="yes" (
    goto CHECK_FASTBOOT
) else if /I "%RETRY%"=="是" (
    goto CHECK_FASTBOOT
) else (
    goto INPUT
)

:CLEANUP
echo 清理文件
rmdir /S /Q %EXTRACT_DIR%

echo 脚本结束

endlocal
pause