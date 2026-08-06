# ThaiWater MSSQL Dataset and Learning Documentation

ชุดข้อมูลสังเคราะห์สำหรับ Microsoft SQL Server เพื่อการเรียนรู้เรื่อง relational model, time-series observation, data quality และการทำรายงานสถานการณ์น้ำ

> ข้อมูลทั้งหมดเป็นข้อมูลสังเคราะห์ ไม่ใช่ข้อมูลจริงหรือ schema ภายในของ ThaiWater, สสน. หรือ สทนช.

## ชุดข้อมูลหลักที่รองรับ

- Database: `thaiwater`
- Schema: `dbo`
- ช่วงข้อมูล: `2026-07-21 00:00` ถึง `2026-07-24 11:45` เวลาไทย
- สถานี: 120 แห่ง
- ฝน 15 นาที: 40,320 แถว
- ระดับน้ำรายชั่วโมง: 10,080 แถว
- Certified view: 10,080 station-hours

## ไฟล์สำคัญ

| File | Purpose |
|---|---|
| [`docs/index.html`](docs/index.html) | Interactive ERD และ Data Dictionary: ซูม เลื่อน คลิก และค้นหาได้ |
| `mssql/thaiwater_literal_10080.sql` | สร้างฐาน `thaiwater`, schema และข้อมูล literal ทั้งชุด |
| `scripts/generate_literal_sql.py` | สร้าง SQL dump เดิมซ้ำแบบ deterministic |
| `rag/erd.md` | ERD, keys, cardinality, grain และ join path |
| `rag/data_dictionary.md` | Data Dictionary ตรงกับ schema ที่ติดตั้งจริง |
| `rag/thaiwater_semantic_contract.md` | Business rules, quality policy และ certified SQL |
| `tests/acceptance.md` | SQL validation สำหรับฐาน `thaiwater` |

## ติดตั้ง

```bash
sqlcmd -S localhost -U SA -P 'YOUR_PASSWORD' -C \
  -i mssql/thaiwater_literal_10080.sql
```

ไฟล์สามารถรันซ้ำได้ โดยจะลบและสร้าง object ภายใน `thaiwater` ใหม่ก่อนโหลดข้อมูล

## ตรวจผล

```sql
USE thaiwater;

SELECT COUNT_BIG(*) AS rainfall_rows FROM dbo.rainfall_15min;
SELECT COUNT_BIG(*) AS water_level_rows FROM dbo.water_level_hourly;
SELECT COUNT_BIG(*) AS report_rows FROM dbo.vw_hourly_situation;
```

ผลที่คาดหวังคือ `40,320 / 10,080 / 10,080`

## วิธีใช้ข้อมูลอย่างถูกต้อง

ใช้ `dbo.vw_hourly_situation` เป็นทางเข้าหลักสำหรับรายงาน หากเขียน query จาก fact tables เอง ต้อง aggregate ฝน 15 นาทีเป็นรายชั่วโมงก่อน join กับระดับน้ำ มิฉะนั้นระดับน้ำหนึ่งแถวจะถูกทำซ้ำสี่เท่า

เปิด [`docs/index.html`](docs/index.html) ด้วยเว็บเบราว์เซอร์เพื่อสำรวจ ERD และค้นหา Data Dictionary แบบ interactive

## ชุดข้อมูลขนาดใหญ่สำหรับการทดลองเพิ่มเติม

`mssql/init.sql` เป็นชุดแยกสำหรับฐาน `ThaiWaterLab` ที่ใช้ schema `dim/fact/rpt` และมี report 40,320 แถว เอกสารหลักของ repository นี้อ้างอิงฐาน `thaiwater` เท่านั้น เพื่อไม่ให้สับสนกับฐานที่ติดตั้งจริง

## สร้าง SQL dump ใหม่

```bash
python3 scripts/generate_literal_sql.py
```

## Public references

- [ThaiWater](https://www.thaiwater.net/)
- [ThaiWater Mobile data scope](https://www.thaiwater.net/mobile)
- [ThaiWater data standards](https://standard.thaiwater.net/docs/)
