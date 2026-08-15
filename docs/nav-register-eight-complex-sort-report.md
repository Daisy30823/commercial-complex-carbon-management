# 导航图、注册、八综合体与排序整改报告

| 项目 | 原问题 | 修改方案 | 主要文件 | 当前结果 |
| --- | --- | --- | --- | --- |
| Dashboard 横幅 | 原绿色 SVG 未使用指定本地素材 | 复制 `导航栏图.png`，使用相对资源 URL、浅色遮罩和响应式背景 | `dashboard-hero.png`、`app.css` | 已实现，待最终浏览器截图复核 |
| 用户注册 | 仅有管理员登录，没有自助注册 | 新增注册页和 JSON 接口，BCrypt、重复校验、事务和操作日志 | `register.jsp`、`ApiServlet.java` | 已实现 |
| 默认权限 | 新用户无明确权限边界 | 新增 `registered_user` 只读角色，后端拒绝业务写请求，前端隐藏写按钮 | `050_registration_default_role.sql`、`ApiServlet.java`、`app.css` | 角色已在 MySQL 验证 |
| 八综合体 | 仅 4 个启用综合体 | 幂等新增温州、金华、湖州、台州并生成完整业务链 | `051`、`052` | MySQL 实测 8 个启用综合体 |
| 表格排序 | 表头不能排序，分页结果顺序固定 | SQL 白名单排序、服务层完整集排序、统一列头组件 | `SqlSortHelper.java`、`table-sort.js`、`app.js` | 代码与语法检查通过，待部署浏览器验收 |

## 数据保护

- 修改前项目备份：`backup/nav-register-eight-complex-sort-before-20260814-231501.zip`
- 修改前数据库备份：`backup/commercial_complex_carbon_db_before_nav_register_sort.sql`
- 未执行主 SQL，未删除原始模拟数据，未修改数据库表结构。

## 已执行验证

- Java 17 `javac` 编译主源码：类文件生成成功。
- `node --check`：`app.js`、`table-sort.js`、`dashboard-runtime.js` 均通过。
- MySQL：8 个启用综合体；四个新综合体逐项数量均达到要求；能耗与碳核算一一对应。
- 索引：检查核心表索引后决定不新增重复索引。

## 最终验收状态

`mvnw.cmd test`、`mvnw.cmd clean package`、Tomcat 部署、注册/登录/只读拦截和浏览器排序检查将在最终构建阶段记录。未实际执行前不标记为通过。
# 2026-08-15 最终验收补充

此前“待验证”状态已经收口，结果如下：

| 验收项 | 最终结果 |
| --- | --- |
| Maven 测试 | 通过，46 项测试，BUILD SUCCESS |
| Maven 打包 | 通过，BUILD SUCCESS |
| 最新 WAR | `<项目目录>\target\commercial-complex-carbon.war`，13,133,679 字节 |
| Tomcat 部署 | 通过，清理旧应用和 work 缓存后重新部署，HTTP 200 |
| 注册与 BCrypt | 通过真实 HTTP 注册，数据库哈希为兼容 `$2a$` BCrypt |
| 默认只读权限 | 读取成功，业务写请求由后端拒绝且未落库 |
| 八综合体 | 8 个启用综合体均可查询，总览和六类图表接口逐一返回真实数据库数据 |
| 表格排序 | 能耗升降序、账单完整集排序、质量列表和非法字段拦截均通过 |
| 数据保护 | 未执行主 SQL、未 drop、未删除或清空现有数据 |
| Chrome 视觉验收 | 未通过环境前置条件：Browser 扩展 Native Host 未安装，未使用其他浏览器替代 |

最终 WAR 的 SHA-256 为 `1C169BF13D737D16FDA11C7563A28E9FFD8EB7D9266B12A12E46E2E916049063`。应用地址为 `http://localhost:8080/commercial-complex-carbon/`。
