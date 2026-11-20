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
# META           "id": "329c4b9a-a960-4e82-bd4e-88ed46cadff0"
# META         },
# META         {
# META           "id": "65d2627a-9e4f-4063-b7ff-748fee4dc732"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = spark.sql("SELECT * FROM B_Lakehouse.dbo.WB_USGDP_raw")
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
