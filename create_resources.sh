#!/usr/bin/env bash
source config.sh

# create the s3 bucket and download source data files
check_s3=$(aws s3api list-buckets --output text --query 'Buckets[?Name==`open-alex-js0258`].Name')
if [[ $check_s3 != $s3name ]] 
then
    aws s3api create-bucket --bucket $s3name --region $region --create-bucket-configuration '{"LocationConstraint":"us-west-2"}'
    #aws s3 cp s3://openalex/data/institutions/ s3://$s3name/institutions/ --recursive
    aws s3 cp s3://openalex/data/institutions/ tmp_data/institutions/ --recursive
    aws s3 cp s3://openalex/data/publishers/ tmp_data/publishers/ --recursive
    gunzip tmp_data/institutions/*/*.gz
    gunzip tmp_data/publishers/*/*.gz
    aws s3 cp tmp_data/institutions/  s3://$s3name/institutions/ --recursive --exclude "*" --include "*part*"
    aws s3 cp tmp_data/publishers/ s3://$s3name/publishers/ --recursive --exclude "*" --include "*part*"
    rm -r tmp_data/institutions/updated_date\=202*
    rm -r tmp_data/publishers/updated_date\=202*
else
    echo "S3 Bucket $s3name already exists"
fi

# create and assigne iam roles and policies
echo "creating $redshift_role_name"
check_role=$(aws iam list-roles --output text --query 'Roles[?RoleName==`AmazonRedshift-CommandsAccessRole`].RoleName')
if [[ $check_role != $redshift_role_name ]]
then
    echo "creating redshift role"
    ROLE_NAME=$(aws iam create-role --role-name $redshift_role_name --region $region --assume-role-policy-document file://iam_policies/redshift_trust_policy.json --output text --query Role.RoleName)
    echo "creating redshift policy"
    POLICY_ARN=$(aws iam create-policy --policy-name $redshift_role_name --policy-document file://iam_policies/redshift_access.json --output text --query Policy.Arn)
    echo "attaching redshift policy to role"
    aws iam attach-role-policy --role-name $redshift_role_name --policy-arn $POLICY_ARN
else
    echo "Roles already created"
fi

# create and assign security groups

echo "now let's create the redshift instance"

# create redshift
# aws redshift create-cluster --cluster-identifier open-alex-js-rs --db-name open-alex-js --node-type dc2.large \
#      --number-of-nodes 1 --master-username redshift1 --master-user-password $redshift_password --default-iam-role-arn $POLICY_ARN \
