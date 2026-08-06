# Data Dictionary — `thaiwater`

เอกสารนี้ตรงกับ metadata ของฐาน `thaiwater` ที่สร้างจาก `mssql/thaiwater_literal_10080.sql` ทุก object อยู่ใน schema `dbo`

> `Null` ด้านล่างหมายถึงข้อกำหนดทางกายภาพของ SQL Server ไม่ใช่เพียงค่าที่พบในข้อมูลปัจจุบัน

## `dbo.agency`

Grain: หนึ่งแถวต่อหน่วยงานเจ้าของข้อมูล

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `agency_code` | `varchar(10)` | No | PK | รหัสหน่วยงานภายในชุดเรียน |
| `agency_name_th` | `nvarchar(200)` | No | | ชื่อหน่วยงานภาษาไทย |

## `dbo.basin`

Grain: หนึ่งแถวต่อลุ่มน้ำสังเคราะห์

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `basin_code` | `char(2)` | No | PK | รหัสลุ่มน้ำในชุดเรียน ไม่ใช่รหัสทางการ |
| `basin_name_th` | `nvarchar(100)` | No | | ชื่อลุ่มน้ำสังเคราะห์ |

## `dbo.province`

Grain: หนึ่งแถวต่อจังหวัดสังเคราะห์

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `province_code` | `char(2)` | No | PK | รหัสจังหวัดในชุดเรียน |
| `province_name_th` | `nvarchar(100)` | No | | ชื่อจังหวัดสังเคราะห์ |

## `dbo.quality_flag`

Grain: หนึ่งแถวต่อ quality code

| Column | SQL type | Null | Key | ความหมาย |
|---|---|---:|---|---|
| `quality_code` | `char(1)` | No | PK | รหัสคุณภาพ observation |
| `quality_name_th` | `nvarchar(100)` | No | | คำอธิบายสถานะภาษาไทย |
| `usable_for_report` | `bit` | No | | `1` ใช้คำนวณรายงานได้; `0` ใช้วิเคราะห์คุณภาพเท่านั้น |

| Code | Meaning | usable_for_report |
|---|---|---:|
| `V` | ผ่านการตรวจสอบ | 1 |
| `P` | ข้อมูลเบื้องต้น | 1 |
| `S` | น่าสงสัย | 0 |
| `M` | ไม่มีข้อมูล | 0 |

## `dbo.station`

Grain: หนึ่งแถวต่อสถานี

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `station_id` | `int` | No | PK | | Surrogate key |
| `station_code` | `varchar(20)` | No | UK | | Business key ที่แสดงต่อผู้ใช้ |
| `station_name_th` | `nvarchar(200)` | No | | | ชื่อสถานีสังเคราะห์ |
| `basin_code` | `char(2)` | Yes | FK | `dbo.basin.basin_code` | ลุ่มน้ำของสถานี |
| `province_code` | `char(2)` | Yes | FK | `dbo.province.province_code` | จังหวัดของสถานี |
| `agency_code` | `varchar(10)` | Yes | FK | `dbo.agency.agency_code` | หน่วยงานเจ้าของข้อมูล |
| `latitude` | `decimal(9,6)` | No | | | ละติจูด WGS84 จำลอง, decimal degrees |
| `longitude` | `decimal(9,6)` | No | | | ลองจิจูด WGS84 จำลอง, decimal degrees |
| `vertical_datum` | `varchar(20)` | No | | | Datum มาตรฐาน เช่น `MSL1915` |

## `dbo.station_rule`

Grain: หนึ่งแถวต่อสถานีต่อกฎที่เริ่มมีผล

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `station_id` | `int` | No | PK, FK | `dbo.station.station_id` | สถานีที่กฎใช้; PK บังคับ non-null |
| `effective_from` | `datetime2(0)` | No | PK | | เวลาเริ่มใช้แบบ inclusive; PK บังคับ non-null |
| `effective_to` | `datetime2(0)` | Yes | | | เวลาสิ้นสุด; ข้อมูลชุดนี้เป็น `NULL` ทุกแถว |
| `riverbed_level_m_msl` | `decimal(7,3)` | Yes | | | ระดับท้องน้ำ, เมตร MSL |
| `bank_level_m_msl` | `decimal(7,3)` | Yes | | | ระดับตลิ่ง, เมตร MSL |
| `rule_version` | `varchar(40)` | Yes | | | รุ่นกฎสำหรับ audit |

ตัว view ปัจจุบันเลือก rule ด้วย `station_id` และ `observed_at >= effective_from` เพราะข้อมูลมี rule แบบ open-ended เพียงหนึ่งแถวต่อสถานี

## `dbo.rainfall_15min`

Grain: หนึ่งแถวต่อสถานีต่อช่วง 15 นาที

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `rainfall_id` | `bigint` | No | PK | | Surrogate observation key |
| `station_id` | `int` | Yes | UK, FK | `dbo.station.station_id` | UK ร่วมกับ `observed_at` |
| `observed_at` | `datetime2(0)` | Yes | UK | | เวลาสิ้นสุดช่วงตรวจวัด เวลาไทย |
| `rainfall_mm` | `decimal(8,2)` | Yes | | | ฝนใน 15 นาที, mm; `NULL` คือไม่มีข้อมูล ไม่ใช่ศูนย์ |
| `quality_code` | `char(1)` | Yes | FK | `dbo.quality_flag.quality_code` | สถานะคุณภาพ |
| `received_at` | `datetime2(0)` | Yes | | | เวลาที่ระบบได้รับข้อมูล ไม่ใช่เวลาตรวจวัด |

## `dbo.water_level_hourly`

Grain: หนึ่งแถวต่อสถานีต่อชั่วโมง

| Column | SQL type | Null | Key | FK target | ความหมาย/หน่วย |
|---|---|---:|---|---|---|
| `water_level_id` | `bigint` | No | PK | | Surrogate observation key |
| `station_id` | `int` | Yes | UK, FK | `dbo.station.station_id` | UK ร่วมกับ `observed_at` |
| `observed_at` | `datetime2(0)` | Yes | UK | | เวลาตรวจวัดรายชั่วโมง เวลาไทย |
| `water_level_m_msl` | `decimal(7,3)` | Yes | | | ระดับผิวน้ำ, เมตร MSL |
| `discharge_cms` | `decimal(10,2)` | Yes | | | อัตราการไหล, m³/s (`cms`) |
| `vertical_datum` | `varchar(20)` | Yes | | | Datum ของ observation |
| `quality_code` | `char(1)` | Yes | FK | `dbo.quality_flag.quality_code` | สถานะคุณภาพ |
| `received_at` | `datetime2(0)` | Yes | | | เวลาที่ระบบได้รับข้อมูล |

## `dbo.vw_hourly_situation`

Grain: หนึ่งแถวต่อสถานีต่อชั่วโมง; logical key `(station_code, report_hour)`

| Column | SQL type | Metadata null | ความหมาย/หน่วย |
|---|---|---:|---|
| `report_hour` | `datetime2(0)` | Yes | ชั่วโมงรายงาน เวลาไทย |
| `station_code` | `varchar(20)` | No | รหัสสถานี |
| `station_name_th` | `nvarchar(200)` | No | ชื่อสถานี |
| `basin_name_th` | `nvarchar(100)` | No | ชื่อลุ่มน้ำ |
| `province_name_th` | `nvarchar(100)` | No | ชื่อจังหวัด |
| `agency_name_th` | `nvarchar(200)` | No | หน่วยงานเจ้าของข้อมูล |
| `rainfall_1h_mm` | `decimal(38,2)` | Yes | ผลรวมฝนที่ quality policy อนุญาตในชั่วโมงนั้น, mm |
| `water_level_m_msl` | `decimal(7,3)` | Yes | ระดับน้ำ, เมตร MSL |
| `discharge_cms` | `decimal(10,2)` | Yes | อัตราการไหล, m³/s |
| `channel_capacity_percent` | `decimal(8,2)` | Yes | `(level-riverbed)/(bank-riverbed)*100` |
| `water_situation` | `varchar(14)` | No | `NO_DATA`, `DATUM_MISMATCH`, `CRITICAL_LOW`, `LOW`, `NORMAL`, `HIGH`, `OVER_BANK` |
| `is_complete` | `bit` | Yes | `1` เมื่อฝนครบ 4 ค่า ระดับน้ำใช้ได้ และ datum ตรง |

`reading_count`, `usable_count` และ `rule_version` ใช้ภายในนิยาม view แต่ไม่ได้ถูกส่งออกเป็นคอลัมน์ของ view
