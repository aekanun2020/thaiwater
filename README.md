# ThaiWater MSSQL Dataset and RAG Documentation

Repository นี้ส่งมอบข้อมูลสังเคราะห์สำหรับ Microsoft SQL Server พร้อมเอกสารอธิบายโครงสร้างและความหมายของข้อมูล เพื่อให้ผู้ทำ project นำไปเชื่อมกับระบบของตนเอง

> ข้อมูลทั้งหมดเป็นข้อมูลสังเคราะห์ ไม่ใช่ข้อมูลจริงหรือ schema ภายในของ ThaiWater, สสน. หรือ สทนช.

## ไฟล์ส่งมอบ

| File | Purpose |
|---|---|
| `mssql/init.sql` | สร้างฐาน `ThaiWaterLab` และปั่น observation ด้วย SQL ให้ report 40,320 rows |
| `mssql/thaiwater_literal_10080.sql` | Standalone SQL dump ที่มี `INSERT ... VALUES` จริงและ report 10,080 rows |
| `scripts/generate_literal_sql.py` | สร้าง literal SQL dump ซ้ำแบบ deterministic |
| `rag/erd.md` | Physical ERD, keys, cardinality, grain และ join path |
| `rag/data_dictionary.md` | Data Dictionary ครบทุก table/view และทุก column |
| `rag/thaiwater_semantic_contract.md` | Business rules, quality codes และ certified SQL |
| `tests/acceptance.md` | SQL validation และ expected row counts |

## วิธีรันแบบแนะนำ: Literal SQL dump

ไฟล์ `mssql/thaiwater_literal_10080.sql` รันได้เดี่ยว ไม่ต้องรันไฟล์อื่นก่อน

### SQL Server Management Studio หรือ Azure Data Studio

1. เชื่อม Microsoft SQL Server ด้วย account ที่มีสิทธิ์ `CREATE DATABASE`
2. เปิด `mssql/thaiwater_literal_10080.sql`
3. เลือก database `master`
4. กด Execute
5. รอ query ท้ายไฟล์แสดงจำนวน 40,320 / 10,080 / 10,080

ไฟล์จะสร้าง database `ThaiWaterLiteral`

```sql
USE ThaiWaterLiteral;

SELECT COUNT_BIG(*) AS joined_rows
FROM dbo.vw_hourly_situation;

SELECT TOP (100) *
FROM dbo.vw_hourly_situation
ORDER BY report_hour, station_code;
```

### ใช้ sqlcmd

```bash
sqlcmd -S localhost -U sa -P 'YOUR_PASSWORD' -C \
  -i mssql/thaiwater_literal_10080.sql
```

ผลที่คาดหวัง:

| Object | Rows |
|---|---:|
| `dbo.rainfall_15min` | 40,320 |
| `dbo.water_level_hourly` | 10,080 |
| `dbo.vw_hourly_situation` | 10,080 |

## วิธีรันชุดข้อมูลขนาดใหญ่

`mssql/init.sql` สร้าง database `ThaiWaterLab` และใช้ set-based SQL สร้างข้อมูลจำนวนมาก

```bash
sqlcmd -S localhost -U sa -P 'YOUR_PASSWORD' -C \
  -i mssql/init.sql
```

ผลที่คาดหวัง:

| Object | Rows |
|---|---:|
| `fact.rainfall_15min` | 161,280 |
| `fact.water_level_hourly` | 40,320 |
| `rpt.vw_hourly_situation` | 40,320 |

ตรวจผล:

```sql
USE ThaiWaterLab;

SELECT COUNT_BIG(*) AS joined_rows
FROM rpt.vw_hourly_situation;

SELECT water_situation, COUNT_BIG(*) AS station_hours
FROM rpt.vw_hourly_situation
WHERE is_complete = 1
GROUP BY water_situation
ORDER BY station_hours DESC;
```

## เอกสารที่ต้องอ่านก่อนใช้ข้อมูล

1. `rag/erd.md` — ตารางเชื่อมกันอย่างไรและแต่ละ table มี grain อะไร
2. `rag/data_dictionary.md` — column หมายถึงอะไร ใช้หน่วยใด และ nullable หรือไม่
3. `rag/thaiwater_semantic_contract.md` — business rule, quality policy และ certified query

ประเด็นสำคัญคือ ต้อง aggregate ฝน 15 นาทีเป็นรายชั่วโมงก่อน join กับระดับน้ำรายชั่วโมง มิฉะนั้นระดับน้ำจะถูกทำซ้ำสี่เท่า

## สร้าง Literal SQL ใหม่

```bash
python3 scripts/generate_literal_sql.py
```

คำสั่งจะเขียน `mssql/thaiwater_literal_10080.sql` ใหม่ด้วยข้อมูล deterministic ชุดเดิม

## Public references

- [ThaiWater](https://www.thaiwater.net/)
- [ThaiWater Mobile data scope](https://www.thaiwater.net/mobile)
- [ThaiWater data standards](https://standard.thaiwater.net/docs/)
