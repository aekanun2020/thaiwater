# SQL Acceptance Tests — `thaiwater`

ทุก query ในไฟล์นี้รันกับฐานที่ติดตั้งจริงได้โดยตรง

```sql
USE thaiwater;
```

## Expected row counts

```sql
SELECT 'rainfall_15min' object_name, COUNT_BIG(*) row_count FROM dbo.rainfall_15min
UNION ALL SELECT 'water_level_hourly', COUNT_BIG(*) FROM dbo.water_level_hourly
UNION ALL SELECT 'vw_hourly_situation', COUNT_BIG(*) FROM dbo.vw_hourly_situation;
```

Expected: `40,320 / 10,080 / 10,080`

## Master-data counts

```sql
SELECT 'agency' object_name, COUNT_BIG(*) row_count FROM dbo.agency
UNION ALL SELECT 'basin', COUNT_BIG(*) FROM dbo.basin
UNION ALL SELECT 'province', COUNT_BIG(*) FROM dbo.province
UNION ALL SELECT 'quality_flag', COUNT_BIG(*) FROM dbo.quality_flag
UNION ALL SELECT 'station', COUNT_BIG(*) FROM dbo.station
UNION ALL SELECT 'station_rule', COUNT_BIG(*) FROM dbo.station_rule;
```

Expected: `4 / 6 / 12 / 4 / 120 / 120`

## Cardinality guard

ต้องคืนศูนย์แถว:

```sql
SELECT station_code, report_hour, COUNT_BIG(*) row_count
FROM dbo.vw_hourly_situation
GROUP BY station_code, report_hour
HAVING COUNT_BIG(*) <> 1;
```

## Required data-quality cases

แต่ละ query ต้องคืนอย่างน้อยหนึ่งแถว:

```sql
SELECT TOP (1) * FROM dbo.rainfall_15min WHERE rainfall_mm IS NULL;
SELECT TOP (1) * FROM dbo.rainfall_15min WHERE quality_code = 'S';
SELECT TOP (1) * FROM dbo.water_level_hourly WHERE vertical_datum <> 'MSL1915';
SELECT TOP (1) * FROM dbo.vw_hourly_situation WHERE is_complete = 0;
```

## Period guard

```sql
SELECT MIN(observed_at) min_time, MAX(observed_at) max_time FROM dbo.rainfall_15min;
SELECT MIN(observed_at) min_time, MAX(observed_at) max_time FROM dbo.water_level_hourly;
```

Expected:

- Rainfall: `2026-07-21 00:00:00` ถึง `2026-07-24 11:45:00`
- Water level: `2026-07-21 00:00:00` ถึง `2026-07-24 11:00:00`

## Regenerate literal dump

```bash
python3 scripts/generate_literal_sql.py
```

หลัง generate จำนวนแถวและผล acceptance tests ต้องไม่เปลี่ยน
