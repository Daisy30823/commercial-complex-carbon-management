# 三模块最终部署回归记录

## 实际环境

- Java 17、MySQL 8、Tomcat 10.1.57。
- 未重跑主 SQL，未 drop 数据库，未删除原有业务模拟数据。
- 最新 WAR：`target/commercial-complex-carbon.war`，已复制到 Tomcat `webapps` 并重新启动。

## 接口回归

- 使用本机私密管理员凭据登录成功，当前用户具有管理员角色。
- `GET /api/data-quality/issues` 返回分页结构：总数 111，首屏 20 条。
- `GET /api/data-quality/rules` 返回 11 条集中配置规则。
- 2026 年 7 月月报返回 14 天真实趋势数据；2026 年 1 月月报返回空月结果，接口均成功。

## 浏览器回归

- 商户管理页刷新后仍保持 `#/merchants` 路由。
- 月度碳报告、数据质量中心均可打开，质量列表显示中文表格和分页。
- 浏览器控制台 error 日志为空。

## 构建与部署

- `mvnw.cmd test`：BUILD SUCCESS，22 项测试通过。
- `mvnw.cmd clean package`：BUILD SUCCESS。
- 首页访问 HTTP 200，Tomcat 已运行最新 WAR。
