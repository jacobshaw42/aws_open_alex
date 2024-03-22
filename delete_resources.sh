#!/usr/bin/env bash
source config.sh

# delete s3
check_s3=$(aws s3api list-buckets --output text --query 'Buckets[?Name==`open-alex-js0258`].Name')
if [[ $check_s3 == $s3name ]] 
then
    aws s3 rm s3://open-alex-js0258/ --recursive
    aws s3api delete-bucket --bucket open-alex-js0258
else
    echo "S3 Bucket $s3name does not exist"
fi

# delete roles and policies
check_role=$(aws iam list-roles --output text --query 'Roles[?RoleName==`AmazonRedshift-CommandsAccessRole`].RoleName')
if [[ $check_role == $redshift_role_name ]]
then
    POLICY_ARN=$(aws iam list-policies --output text --query 'Policies[?PolicyName==`AmazonRedshift-CommandsAccessRole`].Arn')
    aws iam detach-role-policy --role-name AmazonRedshift-CommandsAccessRole --policy-arn $POLICY_ARN
    aws iam delete-policy --policy-arn $POLICY_ARN
    aws iam delete-role --role-name AmazonRedshift-CommandsAccessRole
else
    echo "Role does not exist"
fi

# delete redshift
redshift_check=$(aws redshift describe-clusters --output text --query 'Clusters')
if [[ $redshift_check != "" ]]
then
    aws redshift delete-cluster --cluster-identifier open-alex-js-rs
else
    echo "No redshift clusters"
fi