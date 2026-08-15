FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /workspace
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw
COPY src/ src/
RUN ./mvnw test && ./mvnw clean package

FROM tomcat:10.1-jre17-temurin-jammy

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai \
    SESSION_COOKIE_SECURE=true

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends default-mysql-client unzip tzdata \
    && rm -rf /var/lib/apt/lists/* /usr/local/tomcat/webapps/ROOT \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo Asia/Shanghai > /etc/timezone

COPY --from=build /workspace/target/commercial-complex-carbon.war /usr/local/tomcat/webapps/ROOT.war
RUN mkdir -p /usr/local/tomcat/webapps/ROOT \
    && unzip -q /usr/local/tomcat/webapps/ROOT.war -d /usr/local/tomcat/webapps/ROOT

WORKDIR /app
COPY database/cloud/ database/cloud/
COPY scripts/railway-entrypoint.sh scripts/railway-db-init.sh scripts/
RUN chmod 0755 scripts/railway-entrypoint.sh scripts/railway-db-init.sh

EXPOSE 8080
CMD ["/app/scripts/railway-entrypoint.sh"]
