@echo off
setlocal EnableDelayedExpansion
title Security Portfolio — Windows Deployment
color 0A

echo.
echo  ================================================================
echo   SECURITY PORTFOLIO — WINDOWS DEPLOYMENT
echo   No Claude needed. Runs every remaining step automatically.
echo   Pauses only when it needs your input.
echo  ================================================================
echo.
echo  Make sure you are running this from inside the security-portfolio folder.
echo  Press any key to start...
pause >nul


:: ════════════════════════════════════════════════════════════════════
:: STEP 1 — CHECK + INSTALL TOOLS
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 1 — Checking tools"

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [MISSING] Python — installing via winget...
    winget install Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
    echo [!] Restart this window then re-run.
    pause & exit /b
)
python --version & echo [OK] Python

git --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Git.Git --silent --accept-package-agreements --accept-source-agreements
    echo [!] Restart this window then re-run.
    pause & exit /b
)
git --version & echo [OK] Git

gh --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install GitHub.cli --silent --accept-package-agreements --accept-source-agreements
    echo [!] Restart this window then re-run.
    pause & exit /b
)
gh --version | findstr "gh version" & echo [OK] GitHub CLI

aws --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Amazon.AWSCLI --silent --accept-package-agreements --accept-source-agreements
    echo [!] Restart this window then re-run.
    pause & exit /b
)
aws --version & echo [OK] AWS CLI

docker --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements
    echo [!] Start Docker Desktop manually then re-run.
    pause & exit /b
)
docker --version & echo [OK] Docker

terraform --version >nul 2>&1
if %errorlevel% neq 0 (
    winget install Hashicorp.Terraform --silent --accept-package-agreements --accept-source-agreements
    echo [!] Restart this window then re-run.
    pause & exit /b
)
terraform --version | findstr "Terraform v" & echo [OK] Terraform

echo.
echo All tools ready.


:: ════════════════════════════════════════════════════════════════════
:: STEP 2 — AWS CONFIGURE
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 2 — AWS credentials"

echo STOPPING — need your AWS Free Tier IAM access keys.
echo.
echo If you don't have them:
echo   1. Go to https://console.aws.amazon.com/iam/
echo   2. Users - your user - Security credentials - Create access key
echo   3. Choose "Application running outside AWS"
echo   4. Copy the Access Key ID and Secret Access Key
echo.
echo Press any key when ready...
pause >nul

aws configure
if %errorlevel% neq 0 ( echo [ERROR] aws configure failed. & pause & exit /b 1 )

for /f %%a in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT=%%a
for /f %%r in ('aws configure get region') do set AWS_REGION=%%r
for /f %%k in ('aws configure get aws_access_key_id') do set AWS_KEY_ID=%%k
for /f %%s in ('aws configure get aws_secret_access_key') do set AWS_SECRET=%%s

echo.
echo [OK] Connected: account=%AWS_ACCOUNT%  region=%AWS_REGION%


:: ════════════════════════════════════════════════════════════════════
:: STEP 3 — GITHUB LOGIN
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 3 — GitHub login"

echo A browser window will open. Log in with your GitHub account (musa-projects).
echo.
gh auth login --web
if %errorlevel% neq 0 ( echo [ERROR] GitHub login failed. & pause & exit /b 1 )
echo [OK] GitHub authenticated as musa-projects


:: ════════════════════════════════════════════════════════════════════
:: STEP 4 — PUSH ALL 3 REPOS
:: (remotes already set on Mac — just push)
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 4 — Pushing all 3 repos to GitHub"

echo Pushing Project 2 — devsecops-pipeline...
cd project2-devsecops
git push -u origin main
if %errorlevel% neq 0 ( echo [ERROR] P2 push failed. Check git status. & pause & exit /b 1 )
echo [OK] https://github.com/musa-projects/devsecops-pipeline
cd ..

echo.
echo Pushing Project 1 — cspm-tool...
cd project1-cspm
git push -u origin main
if %errorlevel% neq 0 ( echo [ERROR] P1 push failed. & pause & exit /b 1 )
echo [OK] https://github.com/musa-projects/cspm-tool
cd ..

echo.
echo Pushing Project 3 — ir-playbook-engine...
cd project3-ir-playbook
git push -u origin main
if %errorlevel% neq 0 ( echo [ERROR] P3 push failed. & pause & exit /b 1 )
echo [OK] https://github.com/musa-projects/ir-playbook-engine
cd ..

echo.
echo All repos live:
echo   https://github.com/musa-projects/devsecops-pipeline
echo   https://github.com/musa-projects/cspm-tool
echo   https://github.com/musa-projects/ir-playbook-engine


:: ════════════════════════════════════════════════════════════════════
:: STEP 5 — CREATE ECR REPOSITORY
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 5 — Create ECR repository"

aws ecr create-repository ^
    --repository-name devsecops-demo-app ^
    --region %AWS_REGION% ^
    --image-scanning-configuration scanOnPush=true ^
    --output table 2>nul

if %errorlevel% neq 0 ( echo [!] ECR repo may already exist — fetching URI... )

for /f %%e in ('aws ecr describe-repositories --repository-names devsecops-demo-app --query "repositories[0].repositoryUri" --output text') do set ECR_URI=%%e
echo [OK] ECR: %ECR_URI%


:: ════════════════════════════════════════════════════════════════════
:: STEP 6 — LAUNCH EC2 t2.micro
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 6 — Launch EC2 t2.micro (deploy target)"

echo STOPPING — about to create an EC2 instance.
echo Cost: FREE (t2.micro = 750 hours/month free tier)
echo This is what the GitHub Actions pipeline deploys the app to.
echo Press any key to launch, or Ctrl+C to skip.
pause >nul

echo Finding latest Ubuntu 22.04 AMI...
for /f %%i in ('aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text') do set AMI_ID=%%i
echo AMI: %AMI_ID%

echo Creating SSH key pair...
aws ec2 create-key-pair --key-name portfolio-deploy-key --query KeyMaterial --output text > portfolio-deploy-key.pem 2>nul
if %errorlevel% equ 0 (
    echo [OK] Key saved: portfolio-deploy-key.pem  KEEP THIS FILE
) else (
    echo [!] Key may already exist — continuing.
)

echo Creating security group...
for /f %%g in ('aws ec2 create-security-group --group-name portfolio-sg --description "Portfolio demo" --query GroupId --output text 2^>nul') do set SG_ID=%%g
if "!SG_ID!"=="" (
    for /f %%g in ('aws ec2 describe-security-groups --filters "Name=group-name,Values=portfolio-sg" --query "SecurityGroups[0].GroupId" --output text') do set SG_ID=%%g
)
aws ec2 authorize-security-group-ingress --group-id !SG_ID! --protocol tcp --port 22 --cidr 0.0.0.0/0 >nul 2>&1
aws ec2 authorize-security-group-ingress --group-id !SG_ID! --protocol tcp --port 8080 --cidr 0.0.0.0/0 >nul 2>&1
echo [OK] Security group: !SG_ID!

echo Launching t2.micro...
for /f %%i in ('aws ec2 run-instances --image-id %AMI_ID% --instance-type t2.micro --key-name portfolio-deploy-key --security-group-ids !SG_ID! --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=portfolio-deploy}]" --query "Instances[0].InstanceId" --output text') do set INSTANCE_ID=%%i
echo [OK] Instance: %INSTANCE_ID%

echo Waiting 35 seconds for public IP...
timeout /t 35 /nobreak >nul

for /f %%h in ('aws ec2 describe-instances --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set EC2_IP=%%h
echo [OK] EC2 Public IP: %EC2_IP%
echo NOTE: EC2 needs ~2 more minutes to fully boot before the pipeline can SSH in.


:: ════════════════════════════════════════════════════════════════════
:: STEP 7 — SET ALL GITHUB ACTIONS SECRETS
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 7 — Setting GitHub Actions secrets"

cd project2-devsecops

echo Setting AWS_ACCESS_KEY_ID...
gh secret set AWS_ACCESS_KEY_ID --body "%AWS_KEY_ID%"

echo Setting AWS_SECRET_ACCESS_KEY...
gh secret set AWS_SECRET_ACCESS_KEY --body "%AWS_SECRET%"

echo Setting AWS_REGION...
gh secret set AWS_REGION --body "%AWS_REGION%"

echo Setting ECR_REGISTRY...
gh secret set ECR_REGISTRY --body "%AWS_ACCOUNT%.dkr.ecr.%AWS_REGION%.amazonaws.com"

echo Setting ECR_REPOSITORY...
gh secret set ECR_REPOSITORY --body "devsecops-demo-app"

echo Setting EC2_HOST...
gh secret set EC2_HOST --body "%EC2_IP%"

echo Setting EC2_SSH_KEY from portfolio-deploy-key.pem...
if exist ..\portfolio-deploy-key.pem (
    gh secret set EC2_SSH_KEY < ..\portfolio-deploy-key.pem
    echo [OK] EC2_SSH_KEY set
) else (
    echo [!] PEM file not found. Paste your PEM contents, then press Ctrl+Z and Enter:
    gh secret set EC2_SSH_KEY
)

echo.
echo DISCORD_WEBHOOK is optional. Skip it if you don't have one.
set /p DISCORD_URL="Paste Discord webhook URL (or press Enter to skip): "
if not "!DISCORD_URL!"=="" (
    gh secret set DISCORD_WEBHOOK --body "!DISCORD_URL!"
    echo [OK] DISCORD_WEBHOOK set
) else (
    echo [skipped] DISCORD_WEBHOOK
)

cd ..
echo.
echo All secrets set. View at:
echo https://github.com/musa-projects/devsecops-pipeline/settings/secrets/actions


:: ════════════════════════════════════════════════════════════════════
:: STEP 8 — TRIGGER PIPELINE (FAIL then PASS)
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 8 — Trigger pipeline runs"

cd project2-devsecops

echo Pushing vulnerable app branch — pipeline will FAIL (this is the demo screenshot).
git checkout -b vuln-demo 2>nul || git checkout vuln-demo
git push -u origin vuln-demo

echo.
echo ================================================================
echo  ACTION: Go here and watch the pipeline fail on gates 1-3:
echo  https://github.com/musa-projects/devsecops-pipeline/actions
echo  Take a screenshot when you see the red X on the gates.
echo  Then press any key to push the secure version.
echo ================================================================
pause >nul

echo.
echo Switching to secure app — pipeline will PASS and deploy to EC2...
git checkout main
copy app\app_secure.py app\app.py
git add app\app.py
git commit -m "fix: use secure app — all 5 gates should pass"
git push origin main

echo.
echo ================================================================
echo  ACTION: Watch the pipeline pass all 5 gates and deploy:
echo  https://github.com/musa-projects/devsecops-pipeline/actions
echo  Take a screenshot of all green checkmarks.
echo  When done, your app is live at: http://%EC2_IP%:8080
echo ================================================================
pause >nul

cd ..


:: ════════════════════════════════════════════════════════════════════
:: STEP 9 — TERRAFORM: Deploy IR Playbook Engine
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 9 — Deploy IR Playbook Engine (Terraform)"

echo STOPPING — need your Telegram bot details.
echo.
echo Get a FREE Telegram bot in 2 minutes:
echo   1. Open Telegram, search @BotFather
echo   2. Send: /newbot
echo   3. Follow prompts, copy the token it gives you
echo   4. Search @userinfobot, send any message, copy the Id number
echo.
set /p TF_TG_TOKEN="Paste Telegram Bot Token: "
set /p TF_TG_CHAT="Paste Telegram Chat ID: "

echo Writing terraform.tfvars...
(
echo aws_region         = "%AWS_REGION%"
echo project_prefix     = "ir-engine"
echo telegram_bot_token = "%TF_TG_TOKEN%"
echo telegram_chat_id   = "%TF_TG_CHAT%"
echo ec2_instance_id    = "%INSTANCE_ID%"
) > project3-ir-playbook\terraform\terraform.tfvars
echo [OK] terraform.tfvars written.

echo.
echo STOPPING — about to run terraform apply.
echo.
echo What this creates (ALL FREE TIER):
echo   - 3 Lambda functions (IR playbooks)
echo   - 3 SNS topics
echo   - 1 DynamoDB table (incident log)
echo   - 1 S3 bucket (forensic evidence)
echo   - CloudWatch alarms + EventBridge rules
echo   - IAM role for Lambda
echo.
echo Estimated cost: $0.00
echo To undo everything later: run TEARDOWN_AWS.bat
echo.
echo Press any key to apply, or Ctrl+C to cancel.
pause >nul

cd project3-ir-playbook\terraform
terraform init
terraform plan
echo.
echo Review the plan above. Press any key to apply.
pause >nul
terraform apply -auto-approve
cd ..\..
echo [OK] IR Playbook Engine deployed!


:: ════════════════════════════════════════════════════════════════════
:: STEP 10 — TEST ALL 3 IR PLAYBOOKS
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 10 — Test all 3 IR playbooks"

echo Writing test event payloads...

echo {"Records":[{"Sns":{"Message":"{\"AlarmName\":\"ir-engine-ssh-bruteforce-alarm\",\"Trigger\":{\"Dimensions\":[{\"name\":\"SourceIP\",\"value\":\"198.51.100.42\"}],\"CurrentValue\":47}}"}}]} > test_ssh.json

echo {"source":"aws.s3","detail-type":"AWS API Call via CloudTrail","detail":{"eventName":"PutBucketAcl","requestParameters":{"bucketName":"my-test-bucket-demo"},"userIdentity":{"arn":"arn:aws:iam::123456789012:user/test.user","type":"IAMUser"}}} > test_s3.json

echo {"source":"aws.iam","detail-type":"AWS API Call via CloudTrail","detail":{"eventName":"AttachUserPolicy","requestParameters":{"userName":"new.employee","policyArn":"arn:aws:iam::aws:policy/AdministratorAccess"},"userIdentity":{"arn":"arn:aws:iam::123456789012:user/admin","type":"IAMUser"}}} > test_iam.json

echo.
echo Testing Playbook 1 — SSH Brute Force...
aws lambda invoke --function-name ir-engine-ssh-bruteforce --payload file://test_ssh.json --cli-binary-format raw-in-base64-out response1.json
type response1.json
echo.

echo Testing Playbook 2 — Public S3 Remediation...
aws lambda invoke --function-name ir-engine-s3-public-remediation --payload file://test_s3.json --cli-binary-format raw-in-base64-out response2.json
type response2.json
echo.

echo Testing Playbook 3 — IAM Anomaly...
aws lambda invoke --function-name ir-engine-iam-anomaly --payload file://test_iam.json --cli-binary-format raw-in-base64-out response3.json
type response3.json
echo.

del test_ssh.json test_s3.json test_iam.json

echo ================================================================
echo  Check Telegram — you should have 3 incident alerts.
echo  Check DynamoDB incident log:
echo  https://console.aws.amazon.com/dynamodb/home#tables
echo ================================================================
pause >nul


:: ════════════════════════════════════════════════════════════════════
:: STEP 11 — SCREENSHOT CHECKLIST
:: ════════════════════════════════════════════════════════════════════
call :section "STEP 11 — Screenshot checklist"

echo PROJECT 2 — DevSecOps Pipeline:
echo   [ ] Pipeline FAILING — gates with red X (triggered above on vuln-demo branch)
echo   [ ] Pipeline PASSING — all 5 green + "Deployed successfully"
echo   [ ] GitHub Security tab showing SARIF findings
echo   [ ] App running at http://%EC2_IP%:8080
echo.
echo PROJECT 1 — CSPM Tool (run after aws configure is done):
echo   cd project1-cspm
echo   python cspm_audit.py --profile default --output terminal
echo   [ ] Terminal with colored CRITICAL/HIGH/MEDIUM table
echo   python cspm_audit.py --profile default --output pdf
echo   [ ] Generated PDF in project1-cspm/reports/
echo.
echo PROJECT 3 — IR Playbook Engine:
echo   [ ] Telegram showing 3 incident alerts with incident IDs
echo   [ ] DynamoDB table with incident log entries
echo   [ ] response1.json / response2.json / response3.json showing statusCode 200
echo.
echo YOUR GITHUB REPOS:
echo   https://github.com/musa-projects/devsecops-pipeline
echo   https://github.com/musa-projects/cspm-tool
echo   https://github.com/musa-projects/ir-playbook-engine
echo.
pause


:: ════════════════════════════════════════════════════════════════════
call :section "ALL DONE"
echo Portfolio is fully deployed and live.
echo Interview answers: _CLAUDE_CODE_INSTRUCTIONS\06_PROJECT0_AND_SHARED.md
echo When done demoing, run TEARDOWN_AWS.bat to remove all AWS resources.
pause
exit /b 0


:section
echo.
echo ----------------------------------------------------------------
echo  %~1
echo ----------------------------------------------------------------
echo.
exit /b 0
