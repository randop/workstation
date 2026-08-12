#!/usr/bin/env bash

#================================================
# environment variables REQUIRED:
# AWSCLOUD_ACCOUNT_ID
# AWSCLOUD_ACCOUNT_EMAIL
# AWS_PROFILE
#================================================

#================================================
## BudgetAlertsManagementPolicy
## 2026-08-12 v1
# ```json
# {
# "Version": "2012-10-17",
# "Statement": [
# {
# "Sid": "AllowBudgetsManagement",
# "Effect": "Allow",
# "Action": [
# "budgets:ViewBudget",
# "budgets:ModifyBudget"
# ],
# "Resource": "arn:aws:budgets::$AWSCLOUD_ACCOUNT_ID:budget/*"
# }]
# }
# ```
#
#================================================

set -euo pipefail

aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "ZeroDollarAlert",
    "BudgetLimit": {"Amount": "0.01", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 0.01
    },
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "randolph@email.ngo"}]
  }]'

aws budgets describe-budgets \
  --account-id $(aws sts get-caller-identity --query Account --output text)
