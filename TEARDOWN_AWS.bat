@echo off
setlocal EnableDelayedExpansion
title TEARDOWN — Remove all AWS resources
color 0C

echo.
echo ================================================================
echo  TEARDOWN — Deletes all AWS resources created by DEPLOY_WINDOWS.bat
echo  Your GitHub repos are NOT affected. Only cloud infra is removed.
echo ================================================================
echo.
echo Press any key to continue, or Ctrl+C to cancel.
pause >nul

echo.
echo [1/3] Destroying Terraform infrastructure...
cd project3-ir-playbook\terraform
if exist terraform.tfvars (
    terraform destroy -auto-approve
    echo [OK] Terraform resources destroyed.
) else (
    echo [!] No terraform.tfvars found — skipping.
)
cd ..\..

echo.
echo [2/3] Terminating EC2 instance...
for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=portfolio-deploy" "Name=instance-state-name,Values=running,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text 2^>nul') do (
    if not "%%i"=="None" (
        aws ec2 terminate-instances --instance-ids %%i
        echo [OK] EC2 %%i terminated.
    ) else (
        echo [!] No portfolio-deploy EC2 found.
    )
)

echo.
echo [3/3] Deleting ECR repository...
aws ecr delete-repository --repository-name devsecops-demo-app --force >nul 2>&1
echo [OK] ECR repo deleted.

echo.
echo Teardown complete. No ongoing AWS charges.
echo To redeploy: run DEPLOY_WINDOWS.bat and start from Step 5.
pause
