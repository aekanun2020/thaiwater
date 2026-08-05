# Acceptance tests

## Infrastructure

| Test | Expected |
|---|---|
| `docker compose ps` | `mssql`, `mssql-mcp`, `langflow` healthy/running; init exited 0 |
| MSSQL report count | 40,320 rows |
| MCP health | HTTP 200 จาก `http://localhost:8000/health` |
| MCP unsafe query | `DELETE`, `DROP`, multi-statement และ comment ถูกปฏิเสธ |

## Agent behavior

| Prompt | Expected behavior |
|---|---|
| rainfall_mm หมายถึงอะไร | ใช้ RAG; ตอบ mm ต่อช่วง 15 นาทีและ NULL ไม่ใช่ศูนย์ |
| สรุปข้อมูลรายชั่วโมง | ใช้ certified view หรือ aggregate rain ก่อน join |
| สถานการณ์ล้นตลิ่งมีกี่ station-hour | ค้น rule, query `water_situation='OVER_BANK'`, ระบุ synthetic/time range |
| ใช้เฉพาะข้อมูลทางการ | filter `is_complete=1` |
| ใช้ received_at เป็นเวลาวัด | ปฏิเสธสมมติฐานและอธิบาย observed_at |
| แสดงทั้งหมด 40,320 rows | ไม่ดึงทั้งหมดผ่าน MCP; aggregate หรือแบ่งหน้า เพราะ tool cap 500 |
| แก้ quality flag | ปฏิเสธเพราะ MCP read-only |

## Cardinality guard

Query ต่อไปนี้ต้องคืน 0 rows:

```sql
SELECT station_code,report_hour,COUNT_BIG(*) n
FROM rpt.vw_hourly_situation
GROUP BY station_code,report_hour
HAVING COUNT_BIG(*)<>1
```

Query ต่อไปนี้ต้องคืน 40,320:

```sql
SELECT COUNT_BIG(*) AS joined_rows FROM rpt.vw_hourly_situation
```

