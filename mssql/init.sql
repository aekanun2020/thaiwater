SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF DB_ID(N'ThaiWaterLab') IS NULL CREATE DATABASE ThaiWaterLab;
GO
USE ThaiWaterLab;
GO

DROP VIEW IF EXISTS rpt.vw_hourly_situation;
DROP TABLE IF EXISTS fact.water_level_hourly;
DROP TABLE IF EXISTS fact.rainfall_15min;
DROP TABLE IF EXISTS dim.station_rule;
DROP TABLE IF EXISTS dim.station;
DROP TABLE IF EXISTS dim.quality_flag;
DROP TABLE IF EXISTS dim.agency;
DROP TABLE IF EXISTS dim.province;
DROP TABLE IF EXISTS dim.basin;
DROP SCHEMA IF EXISTS rpt;
DROP SCHEMA IF EXISTS fact;
DROP SCHEMA IF EXISTS dim;
GO
CREATE SCHEMA dim;
GO
CREATE SCHEMA fact;
GO
CREATE SCHEMA rpt;
GO

CREATE TABLE dim.agency (
  agency_code varchar(10) PRIMARY KEY,
  agency_name_th nvarchar(200) NOT NULL
);
CREATE TABLE dim.basin (
  basin_code char(2) PRIMARY KEY,
  basin_name_th nvarchar(100) NOT NULL
);
CREATE TABLE dim.province (
  province_code char(2) PRIMARY KEY,
  province_name_th nvarchar(100) NOT NULL
);
CREATE TABLE dim.quality_flag (
  quality_code char(1) PRIMARY KEY,
  quality_name_th nvarchar(100) NOT NULL,
  usable_for_report bit NOT NULL
);
CREATE TABLE dim.station (
  station_id int PRIMARY KEY,
  station_code varchar(20) NOT NULL UNIQUE,
  station_name_th nvarchar(200) NOT NULL,
  basin_code char(2) NOT NULL REFERENCES dim.basin(basin_code),
  province_code char(2) NOT NULL REFERENCES dim.province(province_code),
  agency_code varchar(10) NOT NULL REFERENCES dim.agency(agency_code),
  latitude decimal(9,6) NOT NULL,
  longitude decimal(9,6) NOT NULL,
  vertical_datum varchar(20) NOT NULL
);
CREATE TABLE dim.station_rule (
  station_id int NOT NULL REFERENCES dim.station(station_id),
  effective_from datetime2(0) NOT NULL,
  effective_to datetime2(0) NULL,
  riverbed_level_m_msl decimal(7,3) NOT NULL,
  bank_level_m_msl decimal(7,3) NOT NULL,
  rule_version varchar(40) NOT NULL,
  PRIMARY KEY (station_id, effective_from),
  CHECK (riverbed_level_m_msl < bank_level_m_msl),
  CHECK (effective_to IS NULL OR effective_to > effective_from)
);
CREATE TABLE fact.rainfall_15min (
  rainfall_id bigint PRIMARY KEY,
  station_id int NOT NULL REFERENCES dim.station(station_id),
  observed_at datetime2(0) NOT NULL,
  rainfall_mm decimal(8,2) NULL,
  quality_code char(1) NOT NULL REFERENCES dim.quality_flag(quality_code),
  received_at datetime2(0) NOT NULL,
  UNIQUE (station_id, observed_at),
  CHECK (rainfall_mm IS NULL OR rainfall_mm >= 0)
);
CREATE TABLE fact.water_level_hourly (
  water_level_id bigint PRIMARY KEY,
  station_id int NOT NULL REFERENCES dim.station(station_id),
  observed_at datetime2(0) NOT NULL,
  water_level_m_msl decimal(7,3) NULL,
  discharge_cms decimal(10,2) NULL,
  vertical_datum varchar(20) NOT NULL,
  quality_code char(1) NOT NULL REFERENCES dim.quality_flag(quality_code),
  received_at datetime2(0) NOT NULL,
  UNIQUE (station_id, observed_at)
);
GO

INSERT dim.agency VALUES
('HII',N'สถาบันสารสนเทศทรัพยากรน้ำ (ข้อมูลสังเคราะห์)'),
('RID',N'กรมชลประทาน (ข้อมูลสังเคราะห์)'),
('DWR',N'กรมทรัพยากรน้ำ (ข้อมูลสังเคราะห์)'),
('TMD',N'กรมอุตุนิยมวิทยา (ข้อมูลสังเคราะห์)');
INSERT dim.basin VALUES
('01',N'ลุ่มน้ำสาธิตเหนือ'),('02',N'ลุ่มน้ำสาธิตกลาง'),
('03',N'ลุ่มน้ำสาธิตตะวันออกเฉียงเหนือ'),('04',N'ลุ่มน้ำสาธิตตะวันออก'),
('05',N'ลุ่มน้ำสาธิตใต้'),('06',N'ลุ่มน้ำสาธิตตะวันตก');
INSERT dim.province VALUES
('10',N'จังหวัดสาธิต 10'),('20',N'จังหวัดสาธิต 20'),('30',N'จังหวัดสาธิต 30'),
('40',N'จังหวัดสาธิต 40'),('50',N'จังหวัดสาธิต 50'),('60',N'จังหวัดสาธิต 60'),
('70',N'จังหวัดสาธิต 70'),('80',N'จังหวัดสาธิต 80'),('90',N'จังหวัดสาธิต 90'),
('95',N'จังหวัดสาธิต 95'),('96',N'จังหวัดสาธิต 96'),('99',N'จังหวัดสาธิต 99');
INSERT dim.quality_flag VALUES
('V',N'ผ่านการตรวจสอบ',1),('P',N'ข้อมูลเบื้องต้น',1),
('S',N'น่าสงสัย',0),('M',N'ไม่มีข้อมูล',0);

;WITH n AS (
  SELECT TOP (120) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
  FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dim.station
SELECT n, CONCAT('TW',RIGHT(CONCAT('000',n),3)), CONCAT(N'สถานีสาธิต ',n),
  RIGHT(CONCAT('0',((n-1)%6)+1),2),
  CHOOSE(((n-1)%12)+1,'10','20','30','40','50','60','70','80','90','95','96','99'),
  CHOOSE(((n-1)%4)+1,'HII','RID','DWR','TMD'),
  CAST(6+((n*83)%1400)/100.0 AS decimal(9,6)),
  CAST(98+((n*47)%700)/100.0 AS decimal(9,6)), 'MSL1915'
FROM n;

INSERT dim.station_rule
SELECT station_id,'2026-01-01',NULL,
  CAST(4+(station_id%20)*0.1 AS decimal(7,3)),
  CAST(8+(station_id%20)*0.1 AS decimal(7,3)),
  'THAIWATER-PUBLIC-CRITERIA-LAB-1'
FROM dim.station;

/* 120 stations x 14 days x 96 intervals = 161,280 rows. */
;WITH n AS (
  SELECT TOP (161280) ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1 AS n
  FROM sys.all_objects a CROSS JOIN sys.all_objects b
), x AS (
  SELECT n,(n%120)+1 station_id,
    DATEADD(minute,15*CONVERT(int,n/120),CONVERT(datetime2(0),'2026-07-21')) observed_at
  FROM n
)
INSERT fact.rainfall_15min
SELECT n+1,station_id,observed_at,
  CASE WHEN n%997=0 THEN NULL WHEN n%29 IN (0,1,2,3)
       THEN CAST(((station_id*7+n)%180)/10.0 AS decimal(8,2)) ELSE 0 END,
  CASE WHEN n%997=0 THEN 'M' WHEN n%389=0 THEN 'S'
       WHEN n%17=0 THEN 'P' ELSE 'V' END,
  DATEADD(minute,2+CONVERT(int,n%8),observed_at)
FROM x;

/* 120 stations x 14 days x 24 hours = 40,320 rows. */
;WITH n AS (
  SELECT TOP (40320) ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1 AS n
  FROM sys.all_objects a CROSS JOIN sys.all_objects b
), x AS (
  SELECT n,(n%120)+1 station_id,
    DATEADD(hour,CONVERT(int,n/120),CONVERT(datetime2(0),'2026-07-21')) observed_at
  FROM n
)
INSERT fact.water_level_hourly
SELECT n+1,station_id,observed_at,
  CASE WHEN n%1301=0 THEN NULL ELSE CAST(6.5+(station_id%20)*0.1+((n/120)%48)*0.035 AS decimal(7,3)) END,
  CASE WHEN n%1301=0 THEN NULL ELSE CAST(20+((station_id*13+n)%2500)/10.0 AS decimal(10,2)) END,
  CASE WHEN n%4093=0 THEN 'LOCAL' ELSE 'MSL1915' END,
  CASE WHEN n%1301=0 THEN 'M' WHEN n%503=0 THEN 'S' WHEN n%19=0 THEN 'P' ELSE 'V' END,
  DATEADD(minute,4+CONVERT(int,n%12),observed_at)
FROM x;
GO

CREATE INDEX IX_rain_station_time ON fact.rainfall_15min(station_id,observed_at)
  INCLUDE(rainfall_mm,quality_code);
CREATE INDEX IX_level_station_time ON fact.water_level_hourly(station_id,observed_at)
  INCLUDE(water_level_m_msl,discharge_cms,vertical_datum,quality_code);
GO

CREATE VIEW rpt.vw_hourly_situation AS
WITH rain AS (
  SELECT r.station_id,DATEADD(hour,DATEDIFF(hour,0,r.observed_at),0) report_hour,
    CAST(SUM(CASE WHEN q.usable_for_report=1 THEN r.rainfall_mm END) AS decimal(10,2)) rainfall_1h_mm,
    COUNT_BIG(*) reading_count,
    SUM(CASE WHEN q.usable_for_report=1 AND r.rainfall_mm IS NOT NULL THEN 1 ELSE 0 END) usable_count
  FROM fact.rainfall_15min r JOIN dim.quality_flag q ON q.quality_code=r.quality_code
  GROUP BY r.station_id,DATEADD(hour,DATEDIFF(hour,0,r.observed_at),0)
)
SELECT wl.observed_at report_hour,s.station_code,s.station_name_th,
  b.basin_name_th,p.province_name_th,a.agency_name_th,
  rain.rainfall_1h_mm,rain.reading_count,rain.usable_count,
  wl.water_level_m_msl,wl.discharge_cms,
  CAST(100.0*(wl.water_level_m_msl-sr.riverbed_level_m_msl)
       /NULLIF(sr.bank_level_m_msl-sr.riverbed_level_m_msl,0) AS decimal(8,2)) channel_capacity_percent,
  CASE WHEN q.usable_for_report=0 THEN 'NO_DATA'
       WHEN wl.vertical_datum<>s.vertical_datum THEN 'DATUM_MISMATCH'
       WHEN wl.water_level_m_msl>sr.bank_level_m_msl THEN 'OVER_BANK'
       WHEN 100.0*(wl.water_level_m_msl-sr.riverbed_level_m_msl)/NULLIF(sr.bank_level_m_msl-sr.riverbed_level_m_msl,0)>70 THEN 'HIGH'
       WHEN 100.0*(wl.water_level_m_msl-sr.riverbed_level_m_msl)/NULLIF(sr.bank_level_m_msl-sr.riverbed_level_m_msl,0)>30 THEN 'NORMAL'
       WHEN 100.0*(wl.water_level_m_msl-sr.riverbed_level_m_msl)/NULLIF(sr.bank_level_m_msl-sr.riverbed_level_m_msl,0)>10 THEN 'LOW'
       ELSE 'CRITICAL_LOW' END water_situation,
  sr.rule_version,
  CONVERT(bit,CASE WHEN rain.reading_count=4 AND rain.usable_count=4
                    AND q.usable_for_report=1 AND wl.vertical_datum=s.vertical_datum THEN 1 ELSE 0 END) is_complete
FROM fact.water_level_hourly wl
JOIN dim.station s ON s.station_id=wl.station_id
JOIN dim.basin b ON b.basin_code=s.basin_code
JOIN dim.province p ON p.province_code=s.province_code
JOIN dim.agency a ON a.agency_code=s.agency_code
JOIN dim.quality_flag q ON q.quality_code=wl.quality_code
JOIN dim.station_rule sr ON sr.station_id=wl.station_id
 AND wl.observed_at>=sr.effective_from AND (wl.observed_at<sr.effective_to OR sr.effective_to IS NULL)
LEFT JOIN rain ON rain.station_id=wl.station_id AND rain.report_hour=wl.observed_at;
GO

SELECT 'rainfall_15min' object_name,COUNT_BIG(*) row_count FROM fact.rainfall_15min
UNION ALL SELECT 'water_level_hourly',COUNT_BIG(*) FROM fact.water_level_hourly
UNION ALL SELECT 'joined_report',COUNT_BIG(*) FROM rpt.vw_hourly_situation;
GO

