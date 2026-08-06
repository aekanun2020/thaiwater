# ThaiWater Synthetic Dataset Semantic Contract

เอกสารนี้เป็น semantic contract สำหรับฐาน `thaiwater` ที่ติดตั้งจาก `mssql/thaiwater_literal_10080.sql` ไม่ใช่ schema หรือข้อมูลจริงของ ThaiWater, สสน. หรือ สทนช.

## Dataset scope

- Database/schema: `thaiwater.dbo`
- Dataset: ฝน ระดับน้ำ อัตราการไหล สถานี และข้อมูลประกอบ
- Stations: 120
- Rainfall period: `2026-07-21 00:00` ถึง `2026-07-24 11:45` เวลาไทย
- Water-level/report period: `2026-07-21 00:00` ถึง `2026-07-24 11:00` เวลาไทย

## Certified report

- Object: `dbo.vw_hourly_situation`
- Grain: หนึ่งสถานีต่อหนึ่งชั่วโมง
- Logical key: `(station_code, report_hour)`
- Expected rows: 10,080
- Purpose: วิเคราะห์ฝน ระดับน้ำ อัตราการไหล และสถานการณ์น้ำในชุดเรียน

## Join path

1. Aggregate `dbo.rainfall_15min` จาก station-15-minute เป็น station-hour
2. Join กับ `dbo.water_level_hourly` ด้วย `station_id + report_hour`
3. Join `dbo.station` ไปยัง `dbo.basin`, `dbo.province` และ `dbo.agency`
4. Join `dbo.quality_flag` เพื่อเลือก observation ที่ใช้รายงานได้
5. Join `dbo.station_rule` ด้วย `station_id` และ `observed_at >= effective_from`

ข้อมูลปัจจุบันมี rule เดียวต่อสถานีและ `effective_to IS NULL` ทุกแถว จึงยังไม่รองรับประวัติกฎหลายช่วงเวลาโดยสมบูรณ์

## Quality codes

| Code | ความหมาย | usable_for_report |
|---|---|---:|
| `V` | ผ่านการตรวจสอบ | 1 |
| `P` | ข้อมูลเบื้องต้น | 1 |
| `S` | น่าสงสัย | 0 |
| `M` | ไม่มีข้อมูล | 0 |

การอนุญาต `P` เป็น policy ของชุดเรียน

## Business rules

| Rule | Definition |
|---|---|
| `BR-01` | Grain ของ certified view คือ station-hour |
| `BR-02` | Aggregate ฝนก่อน join เพื่อป้องกันระดับน้ำถูกทำซ้ำ 4 เท่า |
| `BR-03` | `NULL rainfall_mm` คือ missing ไม่ใช่ zero |
| `BR-04` | ฝนรายชั่วโมง complete เมื่อมี usable non-null ครบ 4 ค่า |
| `BR-05` | Quality `S` และ `M` ไม่ร่วมผลรวมฝนที่ใช้รายงาน |
| `BR-06` | ระดับน้ำใช้ rule ที่เริ่มมีผลแล้ว ณ `observed_at` |
| `BR-07` | Datum ไม่ตรงให้สถานะ `DATUM_MISMATCH` |
| `BR-08` | `<=10%` CRITICAL_LOW; `>10–30%` LOW; `>30–70%` NORMAL; `>70–100%` HIGH; `>100%` OVER_BANK |
| `BR-09` | รายงานที่ต้องการข้อมูลครบใช้ `is_complete = 1` |
| `BR-10` | ทุกผลวิเคราะห์ต้องระบุว่าเป็นข้อมูลสังเคราะห์และบอกช่วงเวลา |

## Certified SQL examples

```sql
USE thaiwater;

SELECT water_situation, COUNT_BIG(*) station_hours
FROM dbo.vw_hourly_situation
WHERE is_complete = 1
GROUP BY water_situation
ORDER BY station_hours DESC;
```

```sql
SELECT TOP (10) province_name_th, MAX(rainfall_1h_mm) max_rainfall_1h_mm
FROM dbo.vw_hourly_situation
WHERE is_complete = 1
GROUP BY province_name_th
ORDER BY max_rainfall_1h_mm DESC;
```

```sql
SELECT is_complete, COUNT_BIG(*) station_hours
FROM dbo.vw_hourly_situation
GROUP BY is_complete;
```

## Verified current-data profile

| Metric | Value |
|---|---:|
| Rainfall rows | 40,320 |
| Water-level rows | 10,080 |
| Certified-view rows | 10,080 |
| Complete station-hours | 9,907 |
| Incomplete station-hours | 173 |
| Duplicate logical keys | 0 |

สถานการณ์ที่พบจริงคือ `NORMAL`, `HIGH`, `OVER_BANK`, `NO_DATA` และ `DATUM_MISMATCH`; `LOW` และ `CRITICAL_LOW` เป็นค่าที่ business rule รองรับแต่ไม่พบในข้อมูลชุดนี้

## Public references

- [ThaiWater](https://www.thaiwater.net/)
- [ThaiWater Mobile data scope](https://www.thaiwater.net/mobile)
- [Water data standards](https://standard.thaiwater.net/docs/)
