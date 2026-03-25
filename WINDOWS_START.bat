@echo off
setlocal EnableDelayedExpansion
title Security Portfolio — Windows Setup
color 0A

echo.
echo ================================================================
echo  SECURITY PORTFOLIO — WINDOWS SETUP
echo  This clones your repos, then runs the full deployment.
echo  Double-click this once on your Windows PC. That is all.
echo ================================================================
echo.
pause


:: ════════════════════════════════════════════════════════════
:: STEP 1 — INSTALL TOOLS
:: ════════════════════════════════════════════════════════════
call :section "STEP 1 — Installing tools"

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [MISSING] Python — installing...
    winget install Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
    echo [!] Close and reopen this window, then re-run.
    pause & exit /b
)
python --version & echo [OK] Python

git --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Git.Git --silent --accept-package-agreements --accept-source-agreements
    echo [!] Close and reopen this window, then re-run.
    pause & exit /b
)
echo [OK] Git

gh --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install GitHub.cli --silent --accept-package-agreements --accept-source-agreements
    echo [!] Close and reopen this window, then re-run.
    pause & exit /b
)
echo [OK] GitHub CLI

aws --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Amazon.AWSCLI --silent --accept-package-agreements --accept-source-agreements
    echo [!] Close and reopen this window, then re-run.
    pause & exit /b
)
echo [OK] AWS CLI

docker --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements
    echo [!] Start Docker Desktop manually then re-run.
    pause & exit /b
)
echo [OK] Docker

terraform --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Hashicorp.Terraform --silent --accept-package-agreements --accept-source-agreements
    echo [!] Close and reopen this window, then re-run.
    pause & exit /b
)
echo [OK] Terraform

echo.
echo All tools ready.


:: ════════════════════════════════════════════════════════════
:: STEP 2 — GITHUB LOGIN
:: ════════════════════════════════════════════════════════════
call :section "STEP 2 — GitHub login"

echo A browser window will open. Log in with your GitHub account (musa-projects).
echo.
gh auth login --web
if %errorlevel% neq 0 ( echo [ERROR] GitHub login failed. & pause & exit /b 1 )
echo [OK] GitHub authenticated


:: ════════════════════════════════════════════════════════════
:: STEP 3 — CLONE ALL 3 REPOS
:: ════════════════════════════════════════════════════════════
call :section "STEP 3 — Cloning repos from GitHub"

echo Cloning Project 2 — devsecops-pipeline...
gh repo clone musa-projects/devsecops-pipeline project2-devsecops
echo [OK] project2-devsecops/

echo.
echo Cloning Project 1 — cspm-tool...
gh repo clone musa-projects/cspm-tool project1-cspm
echo [OK] project1-cspm/

echo.
echo Cloning Project 3 — ir-playbook-engine...
gh repo clone musa-projects/ir-playbook-engine project3-ir-playbook
echo [OK] project3-ir-playbook/

echo.
echo All repos cloned. Handing off to DEPLOY_WINDOWS.bat...
echo.
timeout /t 3 /nobreak >nul


:: ════════════════════════════════════════════════════════════
:: STEP 4 — HAND OFF TO DEPLOY_WINDOWS.bat
:: ════════════════════════════════════════════════════════════
call DEPLOY_WINDOWS.bat

exit /b 0


:section
echo.
echo ----------------------------------------------------------------
echo  %~1
echo ----------------------------------------------------------------
echo.
exit /b 0
