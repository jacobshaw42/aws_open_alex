from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, col, udf
from pyspark.sql.types import StringType
import logging

logging.info("testing")

print("testing")

spark = (
    SparkSession
    .builder
    .appName("process_open_alex")
    .getOrCreate()
)

oa_id = udf(lambda x: x.split(".org/")[-1] if x is not None else None, StringType())

institutions_path = "s3://open-alex-js0258/institutions/"
publishers_path = "s3://open-alex-js0258/publishers/"

inst = spark.read.json(institutions_path).withColumn("openalex_institution_id", oa_id(col("id")))

institutions = inst.select(
    "openalex_institution_id",
    "display_name",
    "cited_by_count",
    "country_code",
    "country_id",
    "created_date",
    "relationship",
    "works_count"
)

institutions.show()

institutions.write.parquet("s3://open-alex-js0258/processed/institutions/", mode="overwrite")

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

associated_institutions.show()

associated_institutions.write.parquet("s3://open-alex-js0258/processed/associated_institutions/", mode="overwrite")

roles = inst.select(
    col("openalex_institution_id"),
    explode(inst.roles)
    ).select(
        col("openalex_institution_id"),
        oa_id(col("col")["id"]).alias("role_id"),
        col("col")["role"].alias("role")
        ).where(col("role")=="publisher")

roles.show()

roles.write.parquet("s3://open-alex-js0258/processed/roles/", mode="overwrite")

pubs = spark.read.json(publishers_path).withColumn("openalex_publisher_id", oa_id(col("id")))

publishers = pubs.select(
    "openalex_publisher_id",
    "cited_by_count",
    "display_name",
)

publishers.write.parquet("s3://open-alex-js0258/processed/publishers/", mode="overwrite")

pubs_roles = pubs.select(
    "openalex_publisher_id",
    explode(col("roles"))
    ).select(
        "openalex_publisher_id",
        oa_id(col("col")["id"]).alias("institution_id"),
        col("col")["role"].alias("role"),
        col("col")["works_count"].alias("works_count")
        )

pubs_roles.show()

pubs_roles.write.parquet("s3://open-alex-js0258/processed/publisher_roles/", mode="overwrite")
