# 🛡️ Security Engineering Portfolio

A four-project security portfolio covering the full security engineering lifecycle — built entirely with open-source tools and AWS Free Tier.

## Projects

| Folder | Project | What It Demonstrates |
|--------|---------|----------------------|
| `project2-devsecops/` | DevSecOps CI/CD Pipeline | 5 security gates blocking deployment on findings |
| `project1-cspm/` | CSPM Audit Tool | Cloud misconfiguration detection across S3/IAM/EC2 |
| `project3-ir-playbook/` | IR Playbook Engine | Automated incident response in <30 seconds |
| `project0-voip-lab/` | VoIP Security Lab | Network attack detection with 3 detection layers |

## Coverage

```
Prevention  →  CSPM Tool (finds misconfigs) + DevSecOps Pipeline (blocks vulns)
Detection   →  VoIP Lab (network attacks) + CloudWatch Alarms (cloud events)
Response    →  Fail2ban (VoIP lab) + IR Playbook Engine (serverless auto-response)
```

## For Claude Code

**Read `_CLAUDE_CODE_INSTRUCTIONS/00_MASTER_INDEX.md` first, every session.**

## Tech Stack

Python · AWS (Lambda, EC2, S3, CloudWatch, IAM, ECR, DynamoDB) · Docker · Terraform · GitHub Actions · boto3 · ReportLab · Rich · Semgrep · Trivy · Gitleaks · Checkov · Asterisk · Grafana · Prometheus

## Zero Budget

Everything in this portfolio uses free tiers or open-source tools only. No paid SaaS, no paid APIs.
