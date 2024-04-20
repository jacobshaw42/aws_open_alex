# Introduction

The [OpenAlex Dataset](https://openalex.org/) is an open source dataset that contains Science of Science data. The idea behind the dataset is to provide the ability to study and analyze the history of scientific publications. The data is provided from an API or is downloadable as compressed json, which can be more difficult and less efficient to parse. 

The data is very nested json and it has several entities that have relationships to each other. One difficult with the downloadable data is parsing it in a way that allows joining these separated, but connected entities. In this repo, we will provide the code necessary to create the AWS resource to store and process a small portion of the entities to flat parquet files for efficient and easy use. 

Due to the large size of the data and the potential costs of storing and processing that much data, we will use a small subset of the OpenAlex dataset. Just the Institution and Publisher entities. If you have the AWS CLI downloaded, you can view the size of the data and entities by using the following command

```
aws s3 ls --summarize --human-readable --no-sign-request --recursive s3://openalex/data/works/
```

# Backgound

This dataset can be interesting because of the vast size of data that is so readily available that is also very similar to modern business data. Nested documents that are stored as separate entities that may need to be processed and joined together. An example could be social network/media data. Since that is often stored as document data that could be interesting to be viewed or queried for networking purposes.

# Methodology

### AWS Cloud Compute Setup

There are a few prerequisites to install. 

1. AWS CLI Version 2

2. An AWS Account

3. If desired, a Python Virtual Environment to run a test script locally instead of on the AWS EMR Serverless resource.

The first step to reproduce this is creating a `config.sh` file to is used to setting a few important variables used in the bash scripts that run AWS CLI commands. Those variables being

1. `region`: the aws region desired to run in

2. `redshift_password`: the password for the redshift instance

3. `account_number`: the aws account number to be used

The main steps are simple, [create_resources.sh](https://github.com/jacobshaw42/aws_open_alex/blob/main/create_resources.sh) will programatically create all the resources in AWS that are required to perform the rest of the process. 

This starts with checking if the the S3 bucket is already creating and then creating it, if it is not created. Then, downloading the OpenAlex `Insitutions` and `Publishers` entities from the OpenAlex data downloads S3 bucket and uploads them to the S3 we created. It will also copy the `pyspark_jobs/aws_emr_sls_submit.sh` to the `scripts/` prefix of the S3 bucket.

Next, we will check for the `IAM` roles and policies required for the Redshift and EMR services. If they do not exist, they will be created to using json documents defining the required roles and policies from the `iam_policies/` directory.

There after, we will create the emr-serverless application and the redshift instance.

### Big Data Processing

Then, using the [aws_emr_sls_submit.sh](https://github.com/jacobshaw42/aws_open_alex/blob/main/pyspark_jobs/aws_emr_sls_submit.sh), we will submit the [scripts/parse_open_alex.py](https://github.com/jacobshaw42/aws_open_alex/blob/main/pyspark_jobs/parse_open_alex.py) to the emr-serverless application we created. 

This will create a Spark job

```Python
spark = (
    SparkSession
    .builder
    .appName("process_open_alex")
    .getOrCreate()
)
```

Loads the files on S3, because when we created the roles and policies for the emr-serverless application, we designated permissions required to access the script and data on the S3 bucket.

```Python
institutions_path = "s3://open-alex-js0258/institutions/"
publishers_path = "s3://open-alex-js0258/publishers/"

inst = spark.read.json(institutions_path).withColumn("openalex_institution_id", oa_id(col("id")))
```

The above includes a user defined function that will parse and clean the `id` column and label is the `openalex_institution_id column`. This is meant to allow for a more simple way to identify the values, then using the entire url that the column normally contains. 

The following is an example of parsing the institutions entity to obtain a new associated institutions that will explode the nested associated institutions column with the openalex id column and pull additional data to a flatter format that could be easily and efficiently imported into a relational database.

```
associated_institutions = inst.select(
    col("openalex_institution_id"),
    explode(inst.associated_institutions).alias("associated")
    ).select(
        col("openalex_institution_id"),
        col("associated")["country_code"].alias("country_code"),
        col("associated")["display_name"].alias("display_name"),
        col("associated")["relationship"].alias("relationship"),
        col("associated")["type"].alias("type")
        )

associated_institutions.write.parquet("s3://open-alex-js0258/processed/associated_institutions/", mode="overwrite")
```

Both entities used have several sub entities like the above that are parsed and written back to the S3

# Results and Discussion

The results will be the parquet files that are now flattened in a tabular manner. This can be helpful for loading data and joining these sub entities. Another option could be writing to csv, as that format is very good for loading files into relational SQL Databases. While the course did not directly address AWS, the course did address Cloud Computing. Both using the cloud providers webUI and console command line. Also, it helped identify how the cloud provider provides documentation for how to do things with their cloud.

Using these lessons and skills learned in the course were extremely important, because all of the work to setup the cloud compute resources was done using the console command line and documentation on how to us the AWS command line. For example, creating the roles and policies necessary for resources to interact was possibly the most challenging part of this portion of the project. Below, the code snippet checks for the existence of a role, because attempting to create a role that already exists would return an error. Also, we needed to save the role name and policy arn return from the output of creating those, so that they could be used when attaching them together. This is especially important for the policy arn, because this will be different every time the policy is created.

```
check_role=$(aws iam list-roles --output text --query 'Roles[?RoleName==`EMRServerlessS3RuntimeRole`].RoleName')
if [[ $check_role != "EMRServerlessS3RuntimeRole" ]]
then
    echo "creating emr role"
    EMR_ROLE_NAME=$(aws iam create-role \
        --role-name EMRServerlessS3RuntimeRole \
        --assume-role-policy-document file://iam_policies/emr_serverless_trust_policy.json \
        --output text --query Role.RoleName)
    echo "creating emr policy"
    POLICY_ARN=$(aws iam create-policy --policy-name EMRServerlessS3RuntimeRole --policy-document file://iam_policies/emr-serverless-access-policy.json --output text --query Policy.Arn)
    echo "attaching emr policy to role"
    aws iam attach-role-policy --role-name EMRServerlessS3RuntimeRole --policy-arn $POLICY_ARN
else
    echo "emr role already exists"
fi
```

Another major challenge was when first attempting the Spark job. There was a permissions issue and the logs were not very helpful at first. Initially, I thought the problem was the spark job was unable to access the S3 buckets. So, I created a simpler script that just logged a message, and the still failed with the same error message. This made me believe the permissions was with the EMR Serverless Application being unable to access the spark script. After looking through documentation more carefully and how I implemented the resources with the bash scripts and json documents for the policies and roles, I found that the issue was simply that I had the wrong S3 bucket name in the Spark job submit command. After that, The job was able to run completely 

I believe this is an exceptional example of how a simple problem can lead to a rabbit hole of looking for more complex problems that are not present. This has often been my experience, it is easy to start thinking about more complex problems, but it is always worth considering the simple ones that are easy to miss first. This troubleshooting technique can and would have saved time.

# Conclusion

