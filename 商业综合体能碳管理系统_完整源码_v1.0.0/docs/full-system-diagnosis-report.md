# 全系统前后端诊断报告

## 真实根因

此前问题不是 MySQL 数据缺失，而是前端初始化与发布版本不一致：页面依赖一次性的 DOM 启动流程，静态资源没有版本参数，旧 WAR/浏览器缓存可能继续使用旧 `app.js`；同时刷新按钮承担了初始化职责，导致首次进入时综合体、日期和 Dashboard 数据没有可靠渲染。导航绑定也依赖初始化成功，初始化异常时左侧菜单表现为无响应。

## 修复内容

- `src/main/webapp/assets/js/app.js`：统一 `DOMContentLoaded` 启动入口，自动初始化日期和综合体，再按 Hash 渲染页面；增加路由、模块错误隔离、全局错误和 Promise rejection 提示；刷新按钮只刷新当前路由；综合体和日期切换保持当前路由。
- `src/main/webapp/app.jsp`：页面使用上下文路径加载资源，并增加构建版本参数，避免 WAR 更新后继续命中旧缓存；页面保留六类 ECharts、树形计量体系和个人中心入口。
- `src/main/java/cn/complexcarbon/controller/ApiServlet.java`：摘要、列表、图表和专题查询继续使用真实 MySQL 数据并按 `complexId`、统计日期过滤，月度查询使用当前统计年月。
- `scripts/frontend-smoke-test.ps1`：新增无 Node 依赖的真实登录、路由和 API 冒烟检查。

## 数据库安全

本轮未执行主 SQL、未 drop database、未修改表结构/存储过程/触发器/视图，未删除用户或模拟数据。数据库密码不写入本报告。

## 验证结果

- 浏览器真实登录：成功；首次进入首页自动显示综合体 `杭州示范商业综合体`、统计日期 `2026-08-13`、KPI 和图表。
- 综合体选择器：显示杭州、宁波两个启用综合体；此前已验证切换后计量树数据隔离。
- 页面入口：已通过真实浏览器打开 Dashboard、业务列表、计量体系、专题查询和个人中心；左侧导航元素存在且可点击。
- Maven：`mvnw.cmd test` 和 `mvnw.cmd clean package` 均 BUILD SUCCESS。
- WAR：`target/commercial-complex-carbon.war` 已重新部署到 Tomcat。
- 自动化冒烟脚本实际输出：登录成功，16 个路由均为 HTTP 200，`auth/me`、`complexes/enabled`、`dashboard/summary` 均返回 `success=true`，错误列表为空。
- 2026-08-14 数据量复核：`commercial_complex=3`、`meter_device=222`、`energy_consumption_record=5502`、`carbon_accounting_record=5502`、`alert_event=254`、`corrective_task=250`、`operation_log=506`，未减少现有模拟数据。

## 仍需注意

无头冒烟脚本需要 Tomcat 正常运行后执行；CDN 版 ECharts 在完全离线环境需要预缓存。其余本轮诊断目标已落实到代码和部署包。
