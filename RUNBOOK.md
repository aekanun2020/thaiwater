# Runbook — รัน Project ตั้งแต่ศูนย์

เลือกวิธี A สำหรับทำ project Langflow หรือวิธี B เพื่อรันไฟล์ SQL และดูข้อมูลอย่างเดียว

## Prerequisites

- Docker Desktop และ `docker compose`
- RAM ว่างประมาณ 6–8 GB
- OpenAI API key สำหรับ Langflow
- Port `1433`, `8000`, `7860` ว่าง

บน Apple Silicon ตัว MSSQL ใช้ `linux/amd64` emulation จึงอาจเริ่มช้ากว่า container ปกติ

## วิธี A — Langflow + MCP + MSSQL

### 1. Clone

```bash
git clone https://github.com/aekanun2020/thaiwater.git
cd thaiwater
```

### 2. สร้างและแก้ `.env`

```bash
make setup
```

แก้สามค่านี้ใน `.env`:

```dotenv
MSSQL_SA_PASSWORD=รหัสผ่านที่แข็งแรง
LANGFLOW_SUPERUSER_PASSWORD=รหัสผ่านหน้า Langflow
OPENAI_API_KEY=คีย์จริงของคุณ
```

ห้าม commit `.env`; repository ignore ไฟล์นี้แล้ว

### 3. เปิดระบบ

```bash
make start
```

ครั้งแรก Docker จะดาวน์โหลด image แล้วทำตามลำดับ:

1. เปิด SQL Server 2022
2. รัน `mssql/init.sql`
3. สร้างฝน 161,280 rows และระดับน้ำ 40,320 rows
4. สร้าง report view 40,320 rows
5. เปิด read-only MCP ที่ port 8000
6. เปิด Langflow ที่ port 7860

### 4. ตรวจระบบ

```bash
make status
make verify
```

ผลสำคัญ:

```text
joined_rows = 40320
{"status":"ok"}
```

ถ้าไม่ผ่าน:

```bash
make logs
```

### 5. ประกอบ Langflow flow

เปิด http://localhost:7860 แล้ว login ด้วย `LANGFLOW_SUPERUSER` และ `LANGFLOW_SUPERUSER_PASSWORD`

ทำตาม [docs/langflow_setup.md](docs/langflow_setup.md):

1. ingest Markdown ทั้งหมดใน `rag/`
2. ลงทะเบียน MCP URL `http://mssql-mcp:8000/mcp`
3. ต่อ Vector Search Tool และ MCP Tools เข้ากับ Agent
4. ใส่ `prompts/system_prompt.md` เป็น system instructions
5. ทดสอบตาม `tests/acceptance.md`

### 6. หยุดระบบ

```bash
make stop
```

ข้อมูลใน MSSQL volume ยังอยู่

## วิธี B — รัน Literal SQL อย่างเดียว

ไฟล์ `mssql/thaiwater_literal_10080.sql` เป็น standalone dump มี `INSERT ... VALUES` จริง ไม่ต้องรัน `init.sql` ก่อน

| Object | Rows |
|---|---:|
| `dbo.rainfall_15min` | 40,320 |
| `dbo.water_level_hourly` | 10,080 |
| `dbo.vw_hourly_situation` | 10,080 |

### SSMS หรือ Azure Data Studio

1. เชื่อม SQL Server ด้วย account ที่สร้าง database ได้
2. เปิด `mssql/thaiwater_literal_10080.sql`
3. เลือก database `master`
4. กด Execute
5. รอ query สุดท้ายแสดง 40,320 / 10,080 / 10,080

ตรวจข้อมูล:

```sql
USE ThaiWaterLiteral;

SELECT COUNT_BIG(*) AS joined_rows
FROM dbo.vw_hourly_situation;

SELECT TOP (100) *
FROM dbo.vw_hourly_situation
ORDER BY report_hour, station_code;
```

### sqlcmd

```bash
sqlcmd -S localhost -U sa -P 'YOUR_PASSWORD' -C \
  -i mssql/thaiwater_literal_10080.sql
```

## Query ตัวอย่างสำหรับฐาน Full stack

```sql
USE ThaiWaterLab;

SELECT TOP (100) *
FROM rpt.vw_hourly_situation
ORDER BY report_hour, station_code;

SELECT water_situation, COUNT_BIG(*) AS station_hours
FROM rpt.vw_hourly_situation
WHERE is_complete = 1
GROUP BY water_situation
ORDER BY station_hours DESC;

-- ต้องคืน 0 rows หาก grain ถูกต้อง
SELECT station_code, report_hour, COUNT_BIG(*) AS row_count
FROM rpt.vw_hourly_situation
GROUP BY station_code, report_hour
HAVING COUNT_BIG(*) <> 1;
```

## Troubleshooting

ดู log:

```bash
docker compose logs mssql
docker compose logs mssql-init
docker compose logs mssql-mcp
docker compose logs langflow
```

Langflow container ต้องใช้ MCP URL `http://mssql-mcp:8000/mcp` ส่วนโปรแกรมบนเครื่อง host ใช้ `http://localhost:8000/mcp` อย่าใช้ `localhost` ภายใน Langflow เพราะจะชี้กลับไปยัง container Langflow เอง

ตรวจว่า `MSSQL_SA_PASSWORD` ผ่าน password policy หาก SQL Server ไม่เริ่มทำงาน

การลบ Docker volume จะลบฐานข้อมูลและกู้คืนไม่ได้ จึงไม่มี Make target สำหรับลบ volume

