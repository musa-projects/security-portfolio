@echo off
title CSPM Audit Tool
color 0A

echo.
echo ================================================================
echo  AWS CSPM Audit — Cloud Security Posture Management Tool
echo  Audits your AWS account for S3, IAM, EC2, CloudTrail issues
echo  Run this after completing Step 2 (aws configure) in DEPLOY_WINDOWS.bat
echo ================================================================
echo.

cd project1-cspm

echo Choose output format:
echo   1 = Terminal (colored table — good for screenshots)
echo   2 = PDF report (saved to project1-cspm\reports\)
echo   3 = JSON
echo.
set /p CHOICE="Enter 1, 2, or 3: "

if "%CHOICE%"=="1" python cspm_audit.py --profile default --output terminal
if "%CHOICE%"=="2" (
    python cspm_audit.py --profile default --output pdf --output-dir reports
    echo.
    echo Report saved to project1-cspm\reports\
    start reports
)
if "%CHOICE%"=="3" python cspm_audit.py --profile default --output json --output-dir reports

cd ..
echo.
pause
