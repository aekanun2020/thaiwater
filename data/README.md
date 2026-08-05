# Data landing zone

Repository ต้นทางไม่มี dataset ณ วันที่ 2026-08-05 ชุดเริ่มต้นจึงสร้างข้อมูลสังเคราะห์จาก `mssql/init.sql`

เมื่อเพิ่มข้อมูลจริงให้ใช้โครงสร้าง:

```text
data/
├── raw/          # ไฟล์ต้นฉบับ ห้ามแก้ไข
├── staging/      # ไฟล์ที่ normalize encoding/header แล้ว
└── manifest.csv  # source, retrieval date, checksum, license, owner
```

ก่อน ingest ต้องเพิ่ม field mapping, unit, timezone, missing-value convention, key และ quality policy ลงใน `rag/thaiwater_semantic_contract.md`

