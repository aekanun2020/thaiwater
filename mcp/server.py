import os
import re
from decimal import Decimal
from typing import Any

import pymssql
from mcp.server.fastmcp import FastMCP
from starlette.requests import Request
from starlette.responses import JSONResponse

MAX_ROWS = int(os.getenv("MAX_RESULT_ROWS", "500"))
mcp = FastMCP(
    "thaiwater-mssql-readonly",
    host="0.0.0.0",
    port=8000,
    stateless_http=True,
)


def connect():
    return pymssql.connect(
        server=os.environ["MSSQL_HOST"],
        port=int(os.getenv("MSSQL_PORT", "1433")),
        user=os.environ["MSSQL_USER"],
        password=os.environ["MSSQL_PASSWORD"],
        database=os.environ["MSSQL_DATABASE"],
        as_dict=True,
        autocommit=True,
    )


def serializable(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return value


def rows_to_dicts(rows):
    return [{key: serializable(value) for key, value in row.items()} for row in rows]


@mcp.custom_route("/health", methods=["GET"])
async def health(_: Request):
    return JSONResponse({"status": "ok"})


@mcp.tool()
def list_tables() -> list[dict]:
    """List queryable tables and views. Use before composing SQL."""
    sql = """
    SELECT s.name AS schema_name, o.name AS object_name,
           CASE o.type WHEN 'U' THEN 'TABLE' ELSE 'VIEW' END AS object_type
    FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
    WHERE o.type IN ('U','V') AND s.name IN ('dim','fact','rpt')
    ORDER BY s.name,o.name
    """
    with connect() as conn, conn.cursor() as cur:
        cur.execute(sql)
        return rows_to_dicts(cur.fetchall())


@mcp.tool()
def describe_object(schema_name: str, object_name: str) -> dict:
    """Return columns and key constraints. This is structural metadata, not business meaning."""
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", schema_name + object_name):
        raise ValueError("Invalid identifier")
    columns_sql = """
    SELECT c.column_id,c.name AS column_name,t.name AS data_type,c.max_length,
           c.precision,c.scale,c.is_nullable
    FROM sys.columns c JOIN sys.types t ON t.user_type_id=c.user_type_id
    WHERE c.object_id=OBJECT_ID(%s) ORDER BY c.column_id
    """
    keys_sql = """
    SELECT kc.name AS constraint_name,kc.type_desc,c.name AS column_name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
    JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
    WHERE kc.parent_object_id=OBJECT_ID(%s) ORDER BY kc.name,ic.key_ordinal
    """
    full_name = f"{schema_name}.{object_name}"
    with connect() as conn, conn.cursor() as cur:
        cur.execute(columns_sql, (full_name,))
        columns = rows_to_dicts(cur.fetchall())
        if not columns:
            raise ValueError("Object not found or not allowed")
        cur.execute(keys_sql, (full_name,))
        keys = rows_to_dicts(cur.fetchall())
    return {"object": full_name, "columns": columns, "keys": keys}


@mcp.tool()
def run_readonly_query(sql: str) -> dict:
    """Run one SELECT or WITH query. Results are capped; DDL, DML, comments, and multi-statements are rejected."""
    cleaned = sql.strip().rstrip(";").strip()
    lowered = cleaned.lower()
    if not re.match(r"^(select|with)\b", lowered):
        raise ValueError("Only SELECT or WITH queries are allowed")
    banned = re.compile(
        r"\b(insert|update|delete|merge|drop|alter|create|truncate|execute|exec|grant|revoke|deny|backup|restore|dbcc|waitfor|openrowset|opendatasource)\b|--|/\*|\*/|;",
        re.IGNORECASE,
    )
    if banned.search(cleaned):
        raise ValueError("Unsafe SQL token detected")
    with connect() as conn, conn.cursor() as cur:
        cur.execute(cleaned)
        fetched = cur.fetchmany(MAX_ROWS + 1)
        has_more = len(fetched) > MAX_ROWS
        rows = rows_to_dicts(fetched[:MAX_ROWS])
        columns = [item[0] for item in cur.description]
    return {
        "row_limit": MAX_ROWS,
        "returned_rows": len(rows),
        "truncated": has_more,
        "columns": columns,
        "rows": rows,
    }


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
