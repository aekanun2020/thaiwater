.PHONY: setup start status verify logs stop

setup:
	@test -f .env || cp .env.example .env
	@echo "Created .env if missing. Edit passwords and OPENAI_API_KEY before make start."

start:
	@test -f .env || (echo "ERROR: .env not found. Run: make setup" && exit 1)
	docker compose up --build -d

status:
	docker compose ps

verify:
	@test -f .env || (echo "ERROR: .env not found. Run: make setup" && exit 1)
	docker compose exec -T mssql bash -lc '/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$$MSSQL_SA_PASSWORD" -C -d ThaiWaterLab -Q "SELECT COUNT_BIG(*) AS joined_rows FROM rpt.vw_hourly_situation"'
	curl --fail --silent --show-error http://localhost:8000/health
	@echo
	@echo "Expected: joined_rows = 40320 and MCP status = ok"

logs:
	docker compose logs --tail=200 mssql-init mssql-mcp langflow

stop:
	docker compose down

