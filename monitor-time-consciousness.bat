@echo off
REM Monitor the time-consciousness-physicalism conversation for new messages

set CONVERSATION_DIR=conversations\time-consciousness-physicalism
set LOG_FILE=monitor-time-consciousness.log
set INTERVAL=%1
if "%INTERVAL%"=="" set INTERVAL=60

echo Starting monitor for time-consciousness-physicalism conversation... >> %LOG_FILE%
echo Checking every %INTERVAL% seconds >> %LOG_FILE%
echo --- >> %LOG_FILE%

:loop
git pull origin main >nul 2>&1
for /f %%i in ('dir /b %CONVERSATION_DIR%\*.md ^| find /c ".md"') do set CURRENT_COUNT=%%i

echo [%date% %time%] Checked - messages: %CURRENT_COUNT% >> %LOG_FILE%
echo [%date% %time%] Checked - messages: %CURRENT_COUNT%

timeout /t %INTERVAL% >nul
goto loop
