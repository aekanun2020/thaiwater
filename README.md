# ThaiWater Langflow + MCP + RAG + MSSQL Lab

Project พร้อมสอนและทดลองว่า **MCP ทำให้ Agent เข้าถึงฐานข้อมูล แต่ RAG ทำให้ Agent เข้าใจฐานข้อมูล** โดยใช้ข้อมูลสังเคราะห์ที่สอดคล้องกับคำศัพท์และเกณฑ์สาธารณะของ ThaiWater

## Repository status

ตอน clone จาก `https://github.com/aekanun2020/thaiwater.git` เมื่อ 2026-08-05 repository ไม่มี commit และไม่มี dataset Project นี้จึงสร้างข้อมูลสังเคราะห์ใน repo แทน และเตรียม `data/` สำหรับรับข้อมูลจริงในอนาคต

## สิ่งที่ได้

| Layer | Implementation |
|---|---|
| Database | SQL Server 2022, 120 สถานี, ฝน 161,280 rows, ระดับน้ำ 40,320 rows |
| Literal SQL dump | `mssql/thaiwater_literal_10080.sql` มี observation เป็น `INSERT ... VALUES` จริงและ join ได้ 10,080 rows |
| Report | `rpt.vw_hourly_situation`, join 8 objects, 40,320 rows |
| MCP | Python read-only server, schema discovery และ SELECT จำกัด 500 rows |
| RAG | Physical ERD, complete data dictionary, grain, join path, quality codes, business rules, certified SQL |
| Langflow | Docker deployment และคู่มือประกอบ Agent ที่ใช้ RAG + MCP tools |
| Safety | read-only SQL gate, result cap, synthetic-data disclosure, cardinality tests |

## Quick start

```bash
cp .env.example .env
# ใส่รหัสผ่านและ OPENAI_API_KEY
docker compose up --build -d
docker compose ps
```

จากนั้นเปิด `http://localhost:7860` และทำตาม [docs/langflow_setup.md](docs/langflow_setup.md)

## โครงสร้าง

```text
thaiwater/
├── docker-compose.yml
├── mssql/
│   ├── init.sh
│   ├── init.sql
│   └── thaiwater_literal_10080.sql
├── mcp/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── server.py
├── rag/thaiwater_semantic_contract.md
├── rag/erd.md
├── rag/data_dictionary.md
├── prompts/system_prompt.md
├── docs/langflow_setup.md
├── tests/acceptance.md
└── data/
    ├── README.md
    └── manifest.csv
```

หากต้องการเห็นข้อมูลเป็นรายแถวโดยไม่ใช้ SQL data generator ให้เปิดหรือรัน `mssql/thaiwater_literal_10080.sql` ซึ่งเป็น standalone database dump มี rainfall 40,320 rows, water level 10,080 rows และ joined report 10,080 rows

## Learning outcome

ผู้เรียนจะเห็น failure mode สำคัญ:

- SQL รันผ่านแต่ join ผิด grain ทำให้ยอดซ้ำ 4 เท่า
- `NULL` ถูกเข้าใจผิดเป็นฝนไม่ตก
- `received_at` ถูกใช้แทน `observed_at`
- ระดับน้ำถูกเทียบกับตลิ่งทั้งที่ datum คนละระบบ
- quality code ถูกเดาจากชื่อย่อ
- threshold ปัจจุบันถูกใช้กับข้อมูลย้อนหลังโดยไม่ทำ effective-date join

รายละเอียดทั้งหมดอยู่ใน semantic contract ซึ่งควรถูก ingest เข้า RAG ก่อนใช้งาน Agent

## Public references

- [ThaiWater](https://www.thaiwater.net/)
- [ThaiWater Mobile data scope](https://www.thaiwater.net/mobile)
- [ThaiWater data standards](https://standard.thaiwater.net/docs/)
- [Langflow MCP client](https://docs.langflow.org/mcp-client)
- [Langflow Vector RAG](https://docs.langflow.org/next/chat-with-rag)
- [Langflow Docker deployment](https://docs.langflow.org/deployment-docker)
