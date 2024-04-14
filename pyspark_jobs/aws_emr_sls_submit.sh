#!/usr/bin/env bash
source config.sh

echo "getting policy"
EMR_ROLE_ARN=$(aws iam list-roles \
                --query 'Roles[?RoleName==`EMRServerlessS3RuntimeRole`].Arn' \
                --output text)
echo "using execution role $EMR_ROLE_ARN"

emr_serverless_app_id=$(aws emr-serverless list-applications --output text --query 'applications[?name==`open-alex-js`].id')
if [[ $emr_serverless_app_id != "" ]]
then
    echo "submitting job"
    aws emr-serverless start-job-run \
        --application-id $emr_serverless_app_id \
        --execution-role-arn $EMR_ROLE_ARN \
        --name open-alex-parse \
        --job-driver '{
            "sparkSubmit": {
            "entryPoint": "s3://open-alex-js0258/scripts/parse_open_alex.py",
            "sparkSubmitParameters": "--conf spark.executor.cores=1 --conf spark.executor.memory=4g --conf spark.driver.cores=1 --conf spark.driver.memory=4g --conf spark.executor.instances=1"
            }
        }'
else
    echo "no emr serverless applicaiton to run job on"
fi