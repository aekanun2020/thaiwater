# Complete Data Dictionary

Data dictionary นี้ตรงกับ `mssql/init.sql` และฐาน `ThaiWaterLab` ข้อมูลทุกแถวเป็นข้อมูลสังเคราะห์

## `dim.agency`

Grain: หนึ่งแถวต่อหน่วยงานเจ้าของข้อมูล

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `agency_code` | `varchar(10)` | No | PK | รหัสหน่วยงานภายใน lab |
| `agency_name_th` | `nvarchar(200)` | No | | ชื่อหน่วยงานภาษาไทยพร้อมข้อความกำกับว่าข้อมูลสังเคราะห์ |

## `dim.basin`

Grain: หนึ่งแถวต่อลุ่มน้ำสังเคราะห์

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `basin_code` | `char(2)` | No | PK | รหัสลุ่มน้ำใน lab ห้ามอนุมานว่าเป็นรหัสทางการ |
| `basin_name_th` | `nvarchar(100)` | No | | ชื่อลุ่มน้ำสังเคราะห์ |

## `dim.province`

Grain: หนึ่งแถวต่อจังหวัดสังเคราะห์

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `province_code` | `char(2)` | No | PK | รหัสจังหวัดใน lab ห้ามนำไป mapping ระบบอื่นโดยไม่มี crosswalk |
| `province_name_th` | `nvarchar(100)` | No | | ชื่อจังหวัดสังเคราะห์ |

## `dim.quality_flag`

Grain: หนึ่งแถวต่อ quality code

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `quality_code` | `char(1)` | No | PK | รหัสสถานะคุณภาพ observation |
| `quality_name_th` | `nvarchar(100)` | No | | คำอธิบายสถานะภาษาไทย |
| `usable_for_report` | `bit` | No | | `1` ให้นำค่าเข้ารายงานของ lab; `0` เก็บเพื่อ data-quality analysis เท่านั้น |

Code values:

| Code | Meaning | usable_for_report |
|---|---|---:|
| `V` | ผ่านการตรวจสอบ | 1 |
| `P` | ข้อมูลเบื้องต้น | 1 |
| `S` | น่าสงสัย | 0 |
| `M` | ไม่มีข้อมูล | 0 |

## `dim.station`

Grain: หนึ่งแถวต่อสถานี

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `station_id` | `int` | No | PK | | surrogate key สำหรับ join ภายในฐาน |
| `station_code` | `varchar(20)` | No | UK | | business key ที่แสดงต่อผู้ใช้ |
| `station_name_th` | `nvarchar(200)` | No | | | ชื่อสถานีสังเคราะห์ |
| `basin_code` | `char(2)` | No | FK | `dim.basin.basin_code` | ลุ่มน้ำของสถานี |
| `province_code` | `char(2)` | No | FK | `dim.province.province_code` | จังหวัดของสถานี |
| `agency_code` | `varchar(10)` | No | FK | `dim.agency.agency_code` | หน่วยงานเจ้าของข้อมูล |
| `latitude` | `decimal(9,6)` | No | | | ละติจูด WGS84 จำลอง, decimal degrees |
| `longitude` | `decimal(9,6)` | No | | | ลองจิจูด WGS84 จำลอง, decimal degrees |
| `vertical_datum` | `varchar(20)` | No | | | datum มาตรฐานของสถานี เช่น `MSL1915` |

## `dim.station_rule`

Grain: หนึ่งแถวต่อสถานีต่อช่วงเวลาที่ rule version มีผล

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `station_id` | `int` | No | PK, FK | `dim.station.station_id` | สถานีที่กฎใช้ |
| `effective_from` | `datetime2(0)` | No | PK | | เวลาเริ่มใช้แบบ inclusive |
| `effective_to` | `datetime2(0)` | Yes | | | เวลาสิ้นสุดแบบ exclusive; `NULL` หมายถึงยังมีผล |
| `riverbed_level_m_msl` | `decimal(7,3)` | No | | | ระดับท้องน้ำ, เมตร MSL |
| `bank_level_m_msl` | `decimal(7,3)` | No | | | ระดับตลิ่ง, เมตร MSL และต้องสูงกว่าท้องน้ำ |
| `rule_version` | `varchar(40)` | No | | | รุ่นกฎสำหรับ audit และ reproducibility |

Effective-date join:

```sql
observation.observed_at >= station_rule.effective_from
AND (observation.observed_at < station_rule.effective_to
     OR station_rule.effective_to IS NULL)
```

## `fact.rainfall_15min`

Grain: หนึ่งแถวต่อสถานีต่อช่วง 15 นาที

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `rainfall_id` | `bigint` | No | PK | | surrogate observation key |
| `station_id` | `int` | No | UK, FK | `dim.station.station_id` | สถานีที่ตรวจวัด |
| `observed_at` | `datetime2(0)` | No | UK | | เวลาสิ้นสุดช่วงตรวจวัด เวลาไทย; UK ร่วมกับ station |
| `rainfall_mm` | `decimal(8,2)` | Yes | | | ฝนในช่วง 15 นาที, mm; `NULL` คือไม่มีข้อมูล ไม่ใช่ศูนย์ |
| `quality_code` | `char(1)` | No | FK | `dim.quality_flag.quality_code` | สถานะคุณภาพ observation |
| `received_at` | `datetime2(0)` | No | | | เวลาที่ระบบได้รับข้อมูล ห้ามใช้เป็นเวลาตรวจวัด |

## `fact.water_level_hourly`

Grain: หนึ่งแถวต่อสถานีต่อชั่วโมง

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `water_level_id` | `bigint` | No | PK | | surrogate observation key |
| `station_id` | `int` | No | UK, FK | `dim.station.station_id` | สถานีที่ตรวจวัด |
| `observed_at` | `datetime2(0)` | No | UK | | เวลาตรวจวัดรายชั่วโมง เวลาไทย; UK ร่วมกับ station |
| `water_level_m_msl` | `decimal(7,3)` | Yes | | | ระดับผิวน้ำ, เมตร MSL ตาม datum ในแถว |
| `discharge_cms` | `decimal(10,2)` | Yes | | | อัตราการไหล, ลูกบาศก์เมตรต่อวินาที (`m3/s`, `cms`) ไม่ใช่ปริมาตร |
| `vertical_datum` | `varchar(20)` | No | | | datum ของ observation ต้องตรงกับ station ก่อนเทียบ rule |
| `quality_code` | `char(1)` | No | FK | `dim.quality_flag.quality_code` | สถานะคุณภาพ observation |
| `received_at` | `datetime2(0)` | No | | | เวลาที่ระบบได้รับข้อมูล |

## `rpt.vw_hourly_situation`

Grain: หนึ่งแถวต่อสถานีต่อชั่วโมง เป็น certified access path สำหรับการทำรายงาน

| Column | Derived from | Null possible | ความหมาย/หน่วย |
|---|---|---:|---|
| `report_hour` | `water_level_hourly.observed_at` | No | ชั่วโมงรายงาน เวลาไทย |
| `station_code` | `station.station_code` | No | รหัสสถานี |
| `station_name_th` | `station.station_name_th` | No | ชื่อสถานี |
| `basin_name_th` | `basin.basin_name_th` | No | ชื่อลุ่มน้ำ |
| `province_name_th` | `province.province_name_th` | No | ชื่อจังหวัด |
| `agency_name_th` | `agency.agency_name_th` | No | หน่วยงานเจ้าของข้อมูล |
| `rainfall_1h_mm` | usable rainfall sum | Yes | ผลรวมฝนที่ policy อนุญาตในชั่วโมงนั้น, mm |
| `reading_count` | rainfall row count | Yes | จำนวน observation ฝนทั้งหมดในชั่วโมง; ควรเป็น 4 |
| `usable_count` | usable non-null rainfall count | Yes | จำนวน observation ฝนที่ใช้รายงานได้ |
| `water_level_m_msl` | water-level fact | Yes | ระดับน้ำ, เมตร MSL |
| `discharge_cms` | water-level fact | Yes | อัตราการไหล, m3/s |
| `channel_capacity_percent` | level, riverbed, bank | Yes | `(level-riverbed)/(bank-riverbed)*100` |
| `water_situation` | quality, datum, capacity | No | `NO_DATA`, `DATUM_MISMATCH`, `CRITICAL_LOW`, `LOW`, `NORMAL`, `HIGH`, `OVER_BANK` |
| `rule_version` | station rule | No | รุ่นกฎที่ใช้ประเมิน |
| `is_complete` | quality and completeness rules | No | `1` เมื่อฝนครบ 4 ค่า ระดับน้ำใช้ได้ และ datum ตรง |

Logical unique key คือ `(station_code, report_hour)` ผลตรวจ cardinality ต้องไม่มี key ใดมากกว่าหนึ่งแถว
