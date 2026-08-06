# Data landing zone

ฐาน `thaiwater` ปัจจุบันใช้ข้อมูลสังเคราะห์ที่สร้างแบบ deterministic โดย `scripts/generate_literal_sql.py` และส่งมอบเป็น `mssql/thaiwater_literal_10080.sql` ไม่มีข้อมูลจริงอยู่ใน repository

ชุดข้อมูลที่ติดตั้งประกอบด้วยสถานี 120 แห่ง ข้อมูลฝน 15 นาที 40,320 แถว และข้อมูลระดับน้ำรายชั่วโมง 10,080 แถว ในช่วง 21–24 กรกฎาคม 2026

เมื่อเพิ่มข้อมูลจริงให้ใช้โครงสร้าง:

```text
data/
├── raw/          # ไฟล์ต้นฉบับ ห้ามแก้ไข
├── staging/      # ไฟล์ที่ normalize encoding/header แล้ว
└── manifest.csv  # source, retrieval date, checksum, license, owner
```

ก่อน ingest ต้องเพิ่ม field mapping, unit, timezone, missing-value convention, key และ quality policy ลงใน `rag/thaiwater_semantic_contract.md`
