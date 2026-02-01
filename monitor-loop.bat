@echo off
REM Autonomous monitoring loop for Echoes
REM Checks for new PRs, merges them, and monitors conversations

set INTERVAL=%1
if "%INTERVAL%"=="" set INTERVAL=60
set LOG_FILE=monitor-loop.log

echo Starting Echoes autonomous monitoring loop... >> %LOG_FILE%
echo Checking every %INTERVAL% seconds >> %LOG_FILE%
echo --- >> %LOG_FILE%

:loop
set TIMESTAMP=%date% %time%

echo [%TIMESTAMP%] Pulling latest changes... >> %LOG_FILE%
git pull >nul 2>&1

echo [%TIMESTAMP%] Checking for open PRs... >> %LOG_FILE%
gh pr list --state open >nul 2>&1
if errorlevel 1 (
    echo [%TIMESTAMP%] No new PRs >> %LOG_FILE%
    goto sleep
)

echo [%TIMESTAMP%] Found open PRs, merging... >> %LOG_FILE%

REM Merge all open PRs
for /f "tokens=1" %%i in ('gh pr list --state open --json number --jq ".[].number"') do (
    echo [%TIMESTAMP%] Merging PR #%%i... >> %LOG_FILE%
    gh pr merge %%i --squash >> %LOG_FILE% 2>&1
    echo [%TIMESTAMP%] Merged PR #%%i >> %LOG_FILE%
)

git pull >nul 2>&1
echo [%TIMESTAMP%] Changes synchronized >> %LOG_FILE%

:sleep
echo [%TIMESTAMP%] Sleeping for %INTERVAL%s... >> %LOG_FILE%
echo --- >> %LOG_FILE%
timeout /t %INTERVAL% >nul
goto loop
