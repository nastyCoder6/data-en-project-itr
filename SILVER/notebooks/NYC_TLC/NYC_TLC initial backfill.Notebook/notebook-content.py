# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "65d2627a-9e4f-4063-b7ff-748fee4dc732",
# META       "default_lakehouse_name": "B_Lakehouse",
# META       "default_lakehouse_workspace_id": "eaae3c98-2b09-40ae-a50e-1ebe083859a5",
# META       "known_lakehouses": [
# META         {
# META           "id": "65d2627a-9e4f-4063-b7ff-748fee4dc732"
# META         },
# META         {
# META           "id": "329c4b9a-a960-4e82-bd4e-88ed46cadff0"
# META         }
# META       ]
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Merging NYC-TLC parquet files

# MARKDOWN ********************

# ### Setting up the env and schema standardization:

# CELL ********************

import re
from pyspark.sql.types import *
from pyspark.sql import functions as sf

taxi_file_path = "Files/NYC_TLC/yellow_cabs/"
schema = StructType(
    [StructField('VendorID', LongType(), True), 
    StructField('tpep_pickup_datetime', TimestampNTZType(), True), 
    StructField('tpep_dropoff_datetime', TimestampNTZType(), True), 
    StructField('passenger_count', DoubleType(), True), 
    StructField('trip_distance', DoubleType(), True), 
    StructField('RatecodeID', LongType(), True), 
    StructField('store_and_fwd_flag', StringType(), True), 
    StructField('PULocationID', LongType(), True), 
    StructField('DOLocationID', LongType(), True), 
    StructField('payment_type', LongType(), True), 
    StructField('fare_amount', DoubleType(), True), 
    StructField('extra', DoubleType(), True), 
    StructField('mta_tax', DoubleType(), True), 
    StructField('tip_amount', DoubleType(), True), 
    StructField('tolls_amount', DoubleType(), True), 
    StructField('improvement_surcharge', DoubleType(), True), 
    StructField('total_amount', DoubleType(), True), 
    StructField('congestion_surcharge', DoubleType(), True), 
    StructField('airport_fee', DoubleType(), True), 
    StructField('cbd_congestion_fee', DoubleType(), True)])

b_lakehouse_taxi = "abfss://Itransition@onelake.dfs.fabric.microsoft.com/B_Lakehouse.Lakehouse/Files/NYC_TLC/yellow_cabs/"
files_list = mssparkutils.fs.ls(b_lakehouse_taxi)

final_file_list = [file.name for file in files_list if re.search("201[6-9]|202.", file.name)]


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ### The actual file merging:

# CELL ********************

for file in final_file_list:
    try:
        df_raw = spark.read.parquet(f"{taxi_file_path}{file}")
        
        raw_cols_lower = [c.lower() for c in df_raw.columns]
        df_raw = df_raw.select([sf.col(c).alias(c.lower()) for c in df_raw.columns])
        
        final_expressions = []
        for column in schema:
            target_name = column.name
            target_type = column.dataType
            
            if target_name.lower() in raw_cols_lower:
                expr = sf.col(target_name.lower()).cast(target_type).alias(target_name)
            else:
                expr = sf.lit(None).cast(target_type).alias(target_name)
                
            final_expressions.append(expr)

        df_standardized = df_raw.select(*final_expressions)

        (
            df_standardized.write
            .format('delta')
            .mode("append")
            .option("mergeSchema", "true")
            .saveAsTable("S_Lakehouse.NYC_TLC.merged_raw")
        )
        
        print(f"Successfully saved file: {file}")
        
    except Exception as e:
        print(f"Error on {file}: {str(e)}")
        break

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## Filtering

# CELL ********************

df = spark.sql("SELECT * FROM S_Lakehouse.NYC_TLC.merged_raw")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = df.withColumns({"tpep_pickup_datetime": sf.col("tpep_pickup_datetime").cast(TimestampType()), "tpep_dropoff_datetime" : sf.col("tpep_dropoff_datetime").cast(TimestampType())})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_filtered = df.filter(
    (sf.year("tpep_pickup_datetime") >= 2016) & 
    (sf.year("tpep_pickup_datetime") <= 2026) & 
    (sf.col("trip_distance") >= 0) &
    (sf.col("trip_distance") < 100) &
    (sf.col("tpep_pickup_datetime") <= sf.col("tpep_dropoff_datetime")) &
    (sf.col("total_amount") >= 0) &
    (sf.col("total_amount") < 900))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ### Sanitizing

# CELL ********************

df_sanitized = df_filtered.withColumn("passenger_count", sf.when((sf.col("passenger_count") <= 6) & (sf.col("passenger_count") >= 0), sf.col("passenger_count")).otherwise(sf.lit(None)))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_dedup = df_sanitized.dropDuplicates()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ### Enriching

# CELL ********************

df_final = (df_dedup.withColumn("trip_dur_minutes", sf.round((sf.col("tpep_dropoff_datetime") - sf.col("tpep_pickup_datetime")).cast("long")/60, 2))
            .withColumn("date_key", sf.date_format(sf.col("tpep_pickup_datetime"), "yyyyMMdd"))
            .withColumn("pickup_date", sf.to_date(sf.col("tpep_pickup_datetime")))
            .withColumn("pickup_year", sf.year(sf.col("tpep_pickup_datetime")))
            .withColumn("pickup_hour", sf.hour(sf.col("tpep_pickup_datetime")))
            .withColumn("part_of_day", 
                sf.when(sf.col("pickup_hour").between(5,11), "Morning")
                  .when(sf.col("pickup_hour").between(12,16), "Afternoon")
                  .when(sf.col("pickup_hour").between(17,20), "Evening")
                  .otherwise("Night"))
        )

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_final.write.format("delta").mode("overwrite").saveAsTable("S_Lakehouse.NYC_TLC.taxi_clean")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
