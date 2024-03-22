#!/usr/bin/env bash
source config.sh

# create the s3 bucket and download source data files
aws s3api create-bucket --bucket $s3name --region $region --create-bucket-configuration '{"LocationConstraint":"us-west-2"}'
aws s3 cp s3://openalex/data/institutions/ s3://$s3name/institutions/ --recursive
aws s3 cp s3://openalex/data/publishers/ s3://$s3name/publishers/ --recursive

# create and assigne iam roles and policies
echo "creating $redshift_role_name"
aws iam create-role --role-name $redshift_role_name --region $region --assume-role-policy-document file://iam_policies/redshift_trust_policy.json
POLICY_ARN=$(aws iam create-policy --policy-name $redshift_role_name --policy-document file://iam_policies/redshift_access.json --output text --query Policy.Arn)
aws iam attach-role-policy --role-name $redshift_role_name --policy-arn $POLICY_ARN

# create and assign security groups


# create redshift
#aws redshift create-cluster --cluster-identifier open-alex-js-rs --db-name open-alex-js --node-type dc2.large \
#     --number-of-nodes 1 --master-username redshift1 --master-user-password $redshift_password --iam-roles $POLICY_ARN \
