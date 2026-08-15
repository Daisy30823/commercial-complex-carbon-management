#!/bin/sh
set -eu
MAVEN_PROJECTBASEDIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -n "${JAVA_HOME:-}" ]; then JAVA_EXE="$JAVA_HOME/bin/java"; else JAVA_EXE="$(command -v java || true)"; fi
if [ -z "$JAVA_EXE" ] || [ ! -x "$JAVA_EXE" ]; then
  echo "[error] Java 17 not found; set JAVA_HOME." >&2
  exit 1
fi
"$JAVA_EXE" -version 2>&1 | grep -q 'version "17' || { echo '[error] Java 17 is required.' >&2; exit 1; }
exec "$JAVA_EXE" -Dmaven.multiModuleProjectDirectory="$MAVEN_PROJECTBASEDIR" -classpath "$MAVEN_PROJECTBASEDIR/.mvn/wrapper/maven-wrapper.jar" org.apache.maven.wrapper.MavenWrapperMain "$@"
