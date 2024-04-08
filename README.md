# TODO
# use https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/getting-started.html#gs-prerequisites to createemr spark job

## Purpose

This Repo will create a set of resources on AWS for processing and storing the [OpenAlex Dataset](https://openalex.org/)

## Parts

1. `create_resources.sh` will create the AWS resources and download the data to the S3 buckets

2. `delete_resources.sh` will delete all data and resources on AWS

3. `iam_polices/` contains a collection of policies and permissions for the AWS Resources

4. `config.sh` This is a file that should be at the first level of the repo and contain the following linux variable assignments

   1. `region` being the preferred region of the AWS resources
   2. `s3name` being the name you want your s3 bucket to be
   3. `redshift_role_name` being the name of the redshift role you intend to have
   4. `redshift_password` the password for the redshift admin
   5. `account_number` the number of the AWS account
