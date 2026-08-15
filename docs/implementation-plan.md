# 实施计划

1. 固定 SQL 事实来源，核对表、视图、触发器与过程签名。
2. 建立 Java 17 + Maven WAR + Servlet/JDBC 基础和 session 认证。
3. 使用 `CallableStatement` 接入六类核心实体 CRUD 过程。
4. 接入七个查询过程、预算、预警整改和项目效果接口。
5. 使用原生 JavaScript + ECharts 完成六种数据库驱动图表。
6. 补齐中文部署、接口、验收矩阵、验证脚本与测试报告。

风险：本执行环境未提供 JDK、Maven 或 MySQL 命令，构建和数据库 smoke test 需在安装 Java 17/Maven 3.9/MySQL 8 的环境执行；代码按 Tomcat 10.1（Jakarta Servlet 6）编写。

验收条件：SQL 可导入，WAR 可生成，登录后主要导航和 API 可用，六类 CRUD 调用存储过程，树形节点可维护，六种图表调用数据库查询，文档与脚本齐全。
