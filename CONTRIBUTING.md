# 贡献指南

1. 从最新主分支创建功能分支，保持改动聚焦。
2. 不提交 `.env`、`db.properties`、数据库 dump、日志、构建产物或任何真实凭据。
3. Java 代码保持 Java 17、Jakarta Servlet 与现有 JDBC 风格；SQL 使用 `PreparedStatement` 或 `CallableStatement`。
4. 提交前执行 `mvnw.cmd test` 和 `mvnw.cmd clean package`。
5. 涉及数据库结构时提供向前迁移方案，不得在应用重新部署时重置现有数据。
6. Pull Request 说明行为变化、验证命令和安全影响。
