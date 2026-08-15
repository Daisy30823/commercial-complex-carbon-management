# 部署说明

1. 安装 MySQL 8.0、JDK 17、Maven 3.9、Tomcat 10.1。
2. 使用 UTF-8 导入根目录 `2025333541001戴哲语.sql`，再执行 `database/patches/auth_seed.sql`。
3. 复制 `src/main/resources/db.properties.example` 为 `src/main/resources/db.properties`，填写数据库账号密码；该文件已被 `.gitignore` 忽略。
4. 执行 `mvnw.cmd clean package`，生成 `target/commercial-complex-carbon.war`；项目固定使用 Maven 3.9.9，无需全局安装 Maven。
5. 将 WAR 复制到 Tomcat `webapps`，启动 Tomcat，访问 `http://localhost:8080/commercial-complex-carbon/`。
6. 管理员账号由部署者在私有环境中初始化，不在源码或文档中公开。

云端环境变量见 `docs/railway-deployment.md`。Windows 本地开发仍可使用被 Git 忽略的 `db.properties`；数据库不会被自动清空或重建。

本系统所有碳排放因子、能耗和减排量均为课程设计模拟管理核算数据，不构成正式碳核证、碳配额或可交易碳资产。
