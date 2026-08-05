# SQL Acceptance Tests

## Expected row counts

### `ThaiWaterLab`

```sql
USE ThaiWaterLab;

SELECT 'rainfall_15min' AS object_name, COUNT_BIG(*) AS row_count
FROM fact.rainfall_15min
UNION ALL
SELECT 'water_level_hourly', COUNT_BIG(*)
FROM fact.water_level_hourly
UNION ALL
SELECT 'joined_report', COUNT_BIG(*)
FROM rpt.vw_hourly_situation;
```

Expected: 161,280 / 40,320 / 40,320

### `ThaiWaterLiteral`

```sql
USE ThaiWaterLiteral;

SELECT 'rainfall_15min' AS object_name, COUNT_BIG(*) AS row_count
FROM dbo.rainfall_15min
UNION ALL
SELECT 'water_level_hourly', COUNT_BIG(*)
FROM dbo.water_level_hourly
UNION ALL
SELECT 'joined_report', COUNT_BIG(*)
FROM dbo.vw_hourly_situation;
```

Expected: 40,320 / 10,080 / 10,080

## Cardinality guard

Query ต้องคืนศูนย์แถว:

```sql
SELECT station_code, report_hour, COUNT_BIG(*) AS row_count
FROM rpt.vw_hourly_situation
GROUP BY station_code, report_hour
HAVING COUNT_BIG(*) <> 1;
```

## Required data-quality cases

Query แต่ละรายการต้องมีอย่างน้อยหนึ่งแถว:

```sql
SELECT TOP (1) * FROM fact.rainfall_15min WHERE rainfall_mm IS NULL;
SELECT TOP (1) * FROM fact.rainfall_15min WHERE quality_code = 'S';
SELECT TOP (1) * FROM fact.water_level_hourly WHERE vertical_datum <> 'MSL1915';
SELECT TOP (1) * FROM rpt.vw_hourly_situation WHERE is_complete = 0;
```

## Regenerate literal dump

```bash
python3 scripts/generate_literal_sql.py
```

หลัง generate จำนวน literal tuple และ expected counts ต้องไม่เปลี่ยน

