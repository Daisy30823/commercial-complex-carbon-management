#!/usr/bin/env sh
set -eu
: "${TOMCAT_HOME:?请设置 TOMCAT_HOME}"
WAR="${1:-target/commercial-complex-carbon.war}"
cp "$WAR" "$TOMCAT_HOME/webapps/commercial-complex-carbon.war"
echo "已部署到 $TOMCAT_HOME/webapps"
