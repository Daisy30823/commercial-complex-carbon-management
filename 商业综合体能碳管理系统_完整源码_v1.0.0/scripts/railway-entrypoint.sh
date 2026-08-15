#!/bin/sh
set -eu

PORT="${PORT:-8080}"
case "$PORT" in
    *[!0-9]*|'') echo "[startup] PORT must be numeric." >&2; exit 1 ;;
esac

/app/scripts/railway-db-init.sh
unset ADMIN_INITIAL_PASSWORD

sed -i "s/port=\"8080\"/port=\"${PORT}\"/" /usr/local/tomcat/conf/server.xml
export JAVA_OPTS="${JAVA_OPTS:-} -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai -Djava.awt.headless=true"
export CATALINA_OPTS="${CATALINA_OPTS:-} -Dorg.apache.catalina.connector.RECYCLE_FACADES=true"

exec /usr/local/tomcat/bin/catalina.sh run
