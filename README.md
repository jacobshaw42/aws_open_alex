# Introduction

The [OpenAlex Dataset](https://openalex.org/) is an open source dataset that contains Science of Science data. The idea behind the dataset is to provide the ability to study and analyze the history of scientific publications. The data is provided from an API or is downloadable as compressed json, which can be more difficult and less efficient to parse. 

The data is very nested json and it has several entities that have relationships to each other. One difficult with the downloadable data is parsing it in a way that allows joining these separated, but connected entities. In this repo, we will provide the code necessary to create the AWS resource to store and process a small portion of the entities to flat parquet files for efficient and easy use.

# Backgound

This dataset can be interesting because of the vast size of data that is so readily available that is also very similar to modern business data. Nested documents that are stored as separate entities that may need to be processed and joined together.

# Methodology

There are a few prerequisites to install. 

1. AWS CLI Version 2

2. An AWS Account

3. If desired, a Python Virtual Environment to run a test script locally instead of on the AWS EMR Serverless resource.

The first step to reproduce this is creating a `config.sh` file to is used to setting a few important variables used in the bash scripts that run AWS CLI commands. Those variables being

1. `region`: the aws region desired to run in

2. `redshift_password`: the password for the redshift instance

3. `account_number`: the aws account number to be used

The main steps are simple, `create_resources.sh` will programatically create all the resources in AWS that are required to perform the rest of the process. 

This starts with checking if the the S3 bucket is already creating and then creating it, if it is not created. Then, downloading the OpenAlex `Insitutions` and `Publishers` entities from the OpenAlex data downloads S3 bucket and uploads them to the S3 we created. It will also copy the `pyspark_jobs/aws_emr_sls_submit.sh` to the `scripts/` prefix of the S3 bucket.

Next, we will check for the `IAM` roles and policies required for the Redshift and EMR services. If they do not exist, they will be created to using json documents defining the required roles and policies from the `iam_policies/` directory.

There after, we will create the emr-serverless application and the redshift instance.

Then, using the `aws_emr_sls_submit.sh`, we will submit the `scripts/parse_open_alex.py` to the emr-serverless application we created. 

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
