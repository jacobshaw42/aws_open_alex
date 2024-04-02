from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, col, udf
from pyspark.sql.types import StringType

spark = SparkSession.builder.appName("process_open_alex").getOrCreate()

oa_id = udf(lambda x: x.split(".org/")[-1] if x is not None else None, StringType())

institutions_path = "../tmp_data/institutions"
publishers_path = "../tmp_data/publishers"

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

roles = inst.select(
    col("openalex_institution_id"),
    explode(inst.roles)
    ).select(
        col("openalex_institution_id"),
        oa_id(col("col")["id"]).alias("role_id"),
        col("col")["role"].alias("role")
        ).where(col("role")=="publisher")

roles.show()


pubs = spark.read.json(publishers_path).withColumn("openalex_publisher_id", oa_id(col("id")))

publishers = pubs.select(
    "openalex_publisher_id",
    "cited_by_count",
    "display_name",
)

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