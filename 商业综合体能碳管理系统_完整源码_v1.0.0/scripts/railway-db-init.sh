#!/bin/sh
set -eu

DB_HOST="${DB_HOST:-${MYSQLHOST:-}}"
DB_PORT="${DB_PORT:-${MYSQLPORT:-}}"
DB_NAME="${DB_NAME:-${MYSQLDATABASE:-}}"
DB_USER="${DB_USER:-${MYSQLUSER:-}}"
DB_PASSWORD="${DB_PASSWORD:-${MYSQLPASSWORD:-}}"
export DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD

for variable in DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD; do
    eval "value=\${$variable:-}"
    if [ -z "$value" ]; then
        echo "[database] Missing required environment variable: $variable" >&2
        exit 1
    fi
done

mysql_db() {
    MYSQL_PWD="$DB_PASSWORD" mysql \
        --protocol=TCP \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --user="$DB_USER" \
        --database="$DB_NAME" \
        --default-character-set=utf8mb4 \
        --connect-timeout=10 \
        "$@"
}

attempt=0
until mysql_db --batch --skip-column-names --execute="SELECT 1" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 60 ]; then
        echo "[database] MySQL did not become ready within 300 seconds." >&2
        exit 1
    fi
    sleep 5
done

mysql_db <<'SQL'
CREATE TABLE IF NOT EXISTS `schema_migration_history` (
  `version` varchar(100) NOT NULL,
  `description` varchar(255) NOT NULL,
  `installed_at` timestamp NULL DEFAULT NULL,
  `success` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
SQL

migration_version='cloud-baseline-v1.0.0'
migration_rows="$(mysql_db --batch --skip-column-names --execute="SELECT COUNT(*) FROM schema_migration_history WHERE version='${migration_version}'")"
migration_success="$(mysql_db --batch --skip-column-names --execute="SELECT COALESCE(MAX(success),0) FROM schema_migration_history WHERE version='${migration_version}'")"

if [ "$migration_success" = "1" ]; then
    echo "[database] Cloud baseline already installed; skipping database initialization."
    exit 0
fi

if [ "$migration_rows" != "0" ]; then
    echo "[database] A previous initialization is incomplete. Refusing to overwrite the database." >&2
    exit 1
fi

existing_tables="$(mysql_db --batch --skip-column-names --execute="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name<>'schema_migration_history'")"
if [ "$existing_tables" != "0" ]; then
    echo "[database] Existing database objects found without migration history. Refusing to initialize." >&2
    exit 1
fi

for variable in ADMIN_USERNAME ADMIN_INITIAL_PASSWORD; do
    eval "value=\${$variable:-}"
    if [ -z "$value" ]; then
        echo "[database] Missing first-deployment environment variable: $variable" >&2
        exit 1
    fi
done

admin_hash="$(java -cp '/usr/local/tomcat/webapps/ROOT/WEB-INF/classes:/usr/local/tomcat/webapps/ROOT/WEB-INF/lib/*' cn.complexcarbon.util.AdminPasswordTool)"
mysql_db --execute="INSERT INTO schema_migration_history(version,description,success) VALUES('${migration_version}','Railway cloud baseline',0)"
echo "[database] Importing the cloud baseline. This runs only once."
if ! mysql_db < /app/database/cloud/railway_init.sql; then
    echo "[database] Baseline import failed. Existing objects were not removed; inspect the MySQL logs." >&2
    exit 1
fi

mysql_db <<SQL
UPDATE app_user
SET username=CONCAT('disabled_user_',user_id)
WHERE username='${ADMIN_USERNAME}' AND user_id<>1 AND user_status=0;

UPDATE app_user
SET username='${ADMIN_USERNAME}', password_hash='${admin_hash}', real_name='系统管理员',
    phone=NULL, email=NULL, user_status=1, failed_login_count=0, locked_until=NULL,
    password_changed_at=NOW(), remark='云端首次初始化管理员'
WHERE user_id=1;

INSERT INTO user_role(user_id,role_id,assigned_by_user_id,effective_date,valid_flag,remark)
SELECT 1,role_id,1,CURDATE(),1,'云端首次初始化管理员角色'
FROM sys_role
WHERE role_code='admin'
ON DUPLICATE KEY UPDATE valid_flag=1,expiry_date=NULL,remark=VALUES(remark);

UPDATE schema_migration_history
SET success=1,installed_at=CURRENT_TIMESTAMP
WHERE version='${migration_version}';
SQL

unset admin_hash DB_PASSWORD MYSQLPASSWORD ADMIN_INITIAL_PASSWORD MYSQL_PWD
echo "[database] Cloud baseline and administrator initialized successfully."
