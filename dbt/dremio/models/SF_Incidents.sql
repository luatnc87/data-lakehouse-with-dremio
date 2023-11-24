{{
  config(
    materialized = "table"
  )
}}

SELECT *
FROM (
    SELECT * FROM "mysql-local".dremio."SF_incidents2016"
)
UNION ALL (
    SELECT * FROM "Samples"."samples.dremio.com"."SF_incidents2016.json"
)