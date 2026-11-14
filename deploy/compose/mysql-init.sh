# Same as the Helm chart's 01-ems-databases.sh: one server, two databases, one user per service.
# Sourced by the mysql image entrypoint on first start (empty data volume only).
docker_process_sql <<-EOSQL
	CREATE DATABASE IF NOT EXISTS employee_db;
	CREATE DATABASE IF NOT EXISTS department_db;
	CREATE USER IF NOT EXISTS 'employee'@'%' IDENTIFIED BY '${EMPLOYEE_DB_PASSWORD}';
	CREATE USER IF NOT EXISTS 'department'@'%' IDENTIFIED BY '${DEPARTMENT_DB_PASSWORD}';
	GRANT ALL PRIVILEGES ON employee_db.* TO 'employee'@'%';
	GRANT ALL PRIVILEGES ON department_db.* TO 'department'@'%';
	FLUSH PRIVILEGES;
EOSQL
