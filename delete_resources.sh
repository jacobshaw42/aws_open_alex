#!/usr/bin/env bash
source config.sh

# delete s3
aws s3 rm s3://open-alex-js0258/ --recursive
aws s3api delete-bucket --bucket open-alex-js0258

# delete roles and policies
POLICY_ARN=$(aws iam list-policies --output text --query 'Policies[?PolicyName==`AmazonRedshift-CommandsAccessRole`].Arn')
aws iam detach-role-policy --role-name AmazonRedshift-CommandsAccessRole --policy-arn $POLICY_ARN
aws iam delete-policy --policy-arn $POLICY_ARN
aws iam delete-role --role-name AmazonRedshift-CommandsAccessRole

# delete redshift
aws redshift delete-cluster --cluster-identifier open-alex-js-rs