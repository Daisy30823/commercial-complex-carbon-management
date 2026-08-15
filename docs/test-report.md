# 测试报告

## 环境

2026-08-11 已使用项目 Maven Wrapper 3.3.2、Maven 3.9.9、Amazon Corretto Java 17.0.20 实际执行测试与打包。`mysql80` 服务状态为 Running；数据库由用户确认导入并验证，本次工作未修改数据库结构或数据。

- `mvnw.cmd test`：BUILD SUCCESS；3 个测试，0 失败，0 错误，0 跳过。
- `mvnw.cmd clean package`：BUILD SUCCESS；Java 17 编译成功并生成 WAR。
- `一键部署到tomcat.bat`：已对本机 Tomcat 10.1.57 实际验证，WAR 复制成功。
- Tomcat 部署后访问 `http://localhost:8080/commercial-complex-carbon/`：HTTP 200，登录页可达。
- 登录 smoke test：按前端 JSON 格式提交本机私密管理员凭据，响应 200；带同一 session 请求 `/api/auth/me` 返回管理员用户；`/api/complexes` 返回 1 条记录。
- 数据完整性复核：`meter_device=220`、`energy_consumption_record=5500`、`carbon_accounting_record=5500`、`alert_event=254`、`corrective_task=250`、`operation_log=500`，MySQL80 服务 Running。
- WAR：`<项目目录>\target\commercial-complex-carbon.war`，大小 6,441,139 字节。

## 用户环境执行

```text
mvnw.cmd test
mvnw.cmd clean package
mysql --default-character-set=utf8mb4 -uroot -p < 2025333541001戴哲语.sql
mysql --default-character-set=utf8mb4 -uroot -p commercial_complex_carbon_db < database/patches/auth_seed.sql
mysql --default-character-set=utf8mb4 -uroot -p commercial_complex_carbon_db < database/verify_requirements.sql
```

代码级覆盖：认证 session、六类过程 CRUD 路由、七个查询过程路由、触发器由原始 SQL 负责、预算刷新、预警查询、参数空值校验。待安装依赖后补充真实数据库连接、页面访问和 WAR 部署结果。
## 2026-08-11 功能验收补充

- `mvnw.cmd test`：BUILD SUCCESS，3 tests，0 failures。
- `mvnw.cmd clean package`：BUILD SUCCESS，生成 `target/commercial-complex-carbon.war`。
- 已连接本机 MySQL 8 和 Tomcat 10.1 实测 API、触发器、预算、预警闭环及浏览器页面；详细前后数据见 `docs/functional-acceptance-report.md`。
# 2026-08-13 UI整改测试补充

- 环境：Java 17、MySQL 8、Tomcat 10.1、Windows 11。
- `mvnw.cmd test`：BUILD SUCCESS，3 tests，0 failures。
- `mvnw.cmd clean package`：BUILD SUCCESS，生成 `target/commercial-complex-carbon.war`。
- 已重新清理 Tomcat 展开目录、work 缓存并部署 WAR。
- 浏览器实测：登录成功、商户页刷新保持路由、前进后退、个人中心、专题查询、综合体选择器、计量体系页面均可访问。
- 综合体隔离实测：复杂体 4 的计量树为空，切换复杂体 1 后返回 29 个节点；控制台无 JavaScript error。
- 未验证：离线 CDN 场景及所有业务弹窗的逐字段人工录入；数据库原有功能验收基线保持不变。

## 2026-08-14 全系统 UI 修复回归

- 备份：项目 ZIP 与 MySQL dump 已生成。
- Maven：`mvnw.cmd test`、`mvnw.cmd clean package` 均 BUILD SUCCESS。
- 静态资源：`login.css`、`app.css`、`app.js` HTTP 200，无 404。
- 浏览器：错误密码提示正常，使用本机私密管理员凭据登录成功；Dashboard 首次进入自动加载。
- 业务：综合体建档全部状态 3 条、启用 2 条、停用 1 条；预算页可打开。
- 图表：6 个 ECharts canvas；1920×1080 与 1366×768 均无横向溢出；控制台无 error/warn。
- 数据安全：修复前后 8 张基线表记录数一致，未执行主 SQL。

## 2026-08-14 欢迎入口与素材验收

- 根地址返回欢迎入口页，不再直接展示登录表单。
- `landing-background.png`、`brand-logo.png`、`landing.css`、`login.css` 均 HTTP 200。
- 未登录“立即进入”进入登录页；真实登录成功进入 `app.jsp#/dashboard`；退出后回到登录页。
- 1366×768、1920×1080、768px 窄屏无横向溢出，图片真实加载，Console 无 error。
- 截图：`docs/screenshots/landing-page.png`、`docs/screenshots/login-page-with-logo.png`。
## 2026-08-14 三模块增量测试

环境：Java 17、Maven Wrapper、MySQL 8、Tomcat 10.1，本地数据库 `commercial_complex_carbon_db`。

- `mvnw.cmd test`：22 项通过，包含真实数据库连接、表/过程存在性、直计与公共分摊守恒、尾差、版本保留、跨综合体隔离、完整率、质量三类问题、重复扫描、触发器修正回滚和管理员角色测试。
- `mvnw.cmd clean package`：BUILD SUCCESS，生成 `target/commercial-complex-carbon.war`。
- 数据库过程烟测：预览 50 条能源明细、生成 10 个当前账单、月报覆盖 14/31 天、质量扫描重复后指纹数不变；确认低于 95% 完整率的账单被拒绝。
- Session 浏览器验收：欢迎页→登录→`#/merchant-bills`、`#/monthly-reports`、`#/data-quality`；刷新账单页保持 hash；账单明细、月报、质量详情/复核/解决/创建预警均可用；`tab.dev.logs({levels:['error']})` 为空。

未执行：没有重跑主 SQL，没有删除或清空任何原始业务数据。历史数据库已存在的 5502 条能耗和 5502 条碳核算记录保持不减少。

## 2026-08-14 第二轮数据与界面修复测试

- `mvnw.cmd test`：BUILD SUCCESS，共 26 项测试，0 失败、0 错误、0 跳过。
- `mvnw.cmd clean package`：BUILD SUCCESS，WAR 内包含本地 `assets/vendor/echarts.min.js`。
- MySQL 字符集：数据库和连接均为 `utf8mb4`；计量节点、功能区域问号记录均为 0。
- API 实测：登录成功；综合体总数 3；杭州返回 8 栋启用建筑，宁波返回 4 栋启用建筑；计量树无问号文本。
- 数据保护：能耗记录 5502、碳核算记录 5502，修复前后未减少；本轮未执行主 SQL，未修改数据库结构。
- 最终部署：WAR 与 Tomcat `webapps` 中文件均为 11,282,597 字节，系统首页及本地 ECharts 静态资源 HTTP 200。
- 未完成验证：因当前 Codex 未连接 Chrome 扩展，不能执行指定的 Chrome 无痕最终截图；未将其他浏览器结果冒充为 Chrome 验收。

## 2026-08-14 Dashboard 定向修复回归

- `mvnw.cmd test`：BUILD SUCCESS，26 项测试，0 失败、0 错误、0 跳过。
- `mvnw.cmd clean package`：BUILD SUCCESS，最新 WAR 已生成。
- 本机浏览器真实登录后六个 ECharts Canvas 均生成；排名图、热力图、雷达图和仪表盘居中且无裁切。
- 综合体页面刷新后保持 `#/complexes`；停用验收记录显示规范中文且未进入顶部启用综合体选择器；浏览器 Console 无 JavaScript error。
- `app.css`、`app.js`、本地 ECharts、Logo、背景图均返回 HTTP 200。
- 数据库当前数量：综合体 3、设备 222、能耗 5502、碳核算 5502、预警 255、整改任务 250、操作日志 508；本轮没有删除原始模拟数据。
- Tomcat 最终冷部署通过：确认端口停止后删除旧 WAR、展开目录及应用 work/temp 缓存；源 WAR 与部署 WAR 均为 11,283,164 字节，重启后 HTTP 200。
- 最终浏览器复核：Logo 高度 86px、透明背景、0 圆角，旧品牌文字不可见；六个图表 Canvas 均生成；综合体页刷新保持 `#/complexes`；Console 无 error/warn。
- 截图已在浏览器中生成和人工核对，但浏览器接口未将指定路径写入 `docs/screenshots`，未伪造截图文件。

## 2026-08-14 Dashboard 运行时修复

- 项目 ZIP 与 MySQL dump 已完成，修改前后基线均为：综合体 3、设备 222、能耗 5502、碳核算 5502、商户账单 20、操作日志 508。
- `mvnw.cmd test`：BUILD SUCCESS，26 项测试通过。
- `mvnw.cmd clean package`：BUILD SUCCESS，最终 WAR 11,287,496 字节。
- Tomcat 已清理旧 WAR、展开目录和应用缓存后冷部署；根地址 HTTP 200。
- 真实 Session 登录成功，`admin` 当前用户可查询；账单查询和分摊预览均 HTTP 200。
- 部署后七个 Dashboard 请求均 HTTP 200，最慢摘要 231ms；雷达查询由约 11.5 秒优化至 116ms。
- 部署后的 JSP 与账单详情脚本均不包含指定模拟核算提示句。
- 未完成：Chrome 扩展未连接，无法执行附件指定的 Chrome 无痕视觉验收和四张截图；未用内置浏览器替代。

## 2026-08-14 多综合体数据扩充验收

- 数据环境：本机 MySQL 8 当前库，未重跑主 SQL，未删除原始业务数据。
- `mvnw.cmd test`：BUILD SUCCESS，43 项测试，0 失败、0 错误、0 跳过。
- `mvnw.cmd clean package`：BUILD SUCCESS，43 项测试再次通过，生成 `target/commercial-complex-carbon.war`。
- 新增 `MultiComplexDataIntegrationTest` 17 项：四综合体规模、空间和入驻隔离、计量树父子隔离、设备和半年能耗、触发器碳记录、预算明细、三个月账单、质量问题、日志总量、文字残留、月报过程与性能。
- 首轮测试发现杭州 7 月账单仍是扩容前 10 商户版本；修复后当前账单覆盖全部有效入驻商户，账单 tce 与月度能耗一致。
- 首轮 HTTP 验收发现能耗列表错误引用不存在的 `record_status`；修复后四个综合体能耗接口均成功，返回总数 10,902 / 5,400 / 5,400 / 5,400。
- 最终 Session 验收：真实 JSON 登录成功，`/api/auth/me` 返回 admin；4 个综合体共 80 个关键请求全部成功，最慢 1.058 秒。
- 最终部署：Tomcat 10.1 清理应用 WAR、展开目录和 work 缓存后部署，根地址 HTTP 200。
- 用户可见文字：数据库 17 个范围为 0；源码和 WAR 扫描均为 0。
- 浏览器限制：Google Chrome 已安装，但当前账户无 Chrome 用户数据目录，ChatGPT 浏览器扩展和 Native Host 未安装，无法执行指定的 Chrome 无痕视觉、Console 和截图验收；未用其他浏览器冒充。
- JavaScript 语法：使用只读语法解析检查 `app.js` 和 `dashboard-runtime.js`；发现并修复日志 CSV 导出函数缺失右括号，最终检查通过。
- 补丁幂等：再次执行 `042_multi_complex_data_generator.sql`，能耗、碳、账单、质量问题、日志执行前后均为 `27102,27102,512,1036,2108`。
- 最终部署复核：源 WAR 与 Tomcat 部署 WAR SHA-256 一致；最终登录成功，当前用户 admin，4/4 综合体摘要和能耗列表均返回数据库数据。
# 2026-08-14 导航图、注册、八综合体与排序测试

## 环境

- Java：17.0.20
- MySQL：8.0，本机 `commercial_complex_carbon_db`
- Maven Wrapper：3.9.9 配置完整
- Tomcat：10.1（最终 WAR 尚待本轮重新部署）

## 已通过

| 检查 | 结果 |
| --- | --- |
| 项目与数据库修改前备份 | 通过，ZIP 36,356,721 字节，SQL 20,568,893 字节 |
| Java 17 主源码编译检查 | 通过，`ApiServlet`、`SqlSortHelper` 等类文件成功生成 |
| JavaScript 语法 | 通过，`app.js`、`table-sort.js`、`dashboard-runtime.js` 均通过 `node --check` |
| 启用综合体 | 通过，实测 8 个 |
| 每个新综合体业务规模 | 通过，部门/建筑/区域/商户/节点/设备/能耗/预算/预警/整改/项目/账单/质量问题均达标 |
| 能耗触发碳核算 | 通过，48,702 条能耗对应 48,702 条碳核算，缺失关联 0 |
| 多综合体隔离 | 通过，跨综合体入驻关系 0，跨综合体节点父子关系 0 |
| 新综合体差异性 | 通过，四个综合体总用量和总费用均不同 |
| 排序 SQL 安全设计 | 通过代码检查，所有 SQL 排序列来自 `SqlSortHelper` 白名单 |
| 排序索引检查 | 已执行 `explain`；过滤使用既有索引，排序结果集规模可控，不新增重复索引 |

## 待验证

两次申请执行 `mvnw.cmd test` 均因外部执行审批服务连接中断被系统拒绝。受限执行模式不能读取用户目录下的 Maven 插件缓存，直接运行会在 `maven-resources-plugin` 解析阶段失败，尚未进入本轮测试代码。因此以下项目不能标记为通过：

- `mvnw.cmd test`
- `mvnw.cmd clean package`
- 最新 WAR 生成
- Tomcat 重新部署
- 注册接口、登录和只读写操作拦截的真实 HTTP 测试
- Chrome 横幅、注册页、排序交互、控制台与截图验收

需要用户明确允许下一次 Maven/Tomcat 外部执行后继续完成。
# 2026-08-15 最终构建、部署与运行验收

本节为本轮最终结果；如本文前部仍保留历史阶段的“待执行”描述，以本节为准。

- `mvnw.cmd test`：BUILD SUCCESS，共 46 项测试，0 失败、0 错误、0 跳过。
- `mvnw.cmd clean package`：BUILD SUCCESS，打包阶段再次执行 46 项测试并全部通过。
- 最新 WAR：`<项目目录>\target\commercial-complex-carbon.war`，13,133,679 字节，SHA-256 为 `1C169BF13D737D16FDA11C7563A28E9FFD8EB7D9266B12A12E46E2E916049063`。
- Tomcat 10.1.57：已停止旧实例，清理旧 WAR、展开目录和应用 work 缓存，复制并启动最新 WAR；应用根地址返回 HTTP 200。
- WAR 内容：已核对注册页、Dashboard 图片、表格排序脚本、`SqlSortHelper` 类和实际 `db.properties` 均已打包；数据库密码未写入报告。
- 注册与权限：通过真实 HTTP 注册 `已移除的课程只读账号`，BCrypt 哈希长度 60、前缀 `$2a$`，角色为 `registered_user`；登录和只读查询成功，业务写请求被后端以 400 拒绝，数据库未产生被拦截的测试综合体。
- 管理员会话：使用本机私密管理员凭据登录成功，`/api/auth/me` 返回管理员用户；综合体接口返回 8 个启用综合体。
- 排序：选定综合体的能耗列表按用量降序首值 1018.281、升序首值 5.9，顺序单调性校验通过；账单完整集排序通过；非法排序字段返回 400。
- 八综合体接口：逐一调用总览和六类图表接口，均返回当前 MySQL 数据；四个新增综合体分别返回建筑 5、设备 30、趋势 30 天、排名 12、能源结构 5、热力数据 450、雷达数据 15、仪表盘 1 条。
- 数据保护：未重新执行主 SQL，未 drop database，未删除或清空数据；验收后 `energy_consumption_record=48702`、`carbon_accounting_record=48702`，二者仍一一对应。
- Tomcat 日志：检查本次部署后的日志尾部，未发现 `SEVERE`、`ERROR` 或未处理异常。
- Chrome 视觉验收：未执行。Chrome 程序已安装，但当前 Windows 用户缺少 Chrome 用户数据目录、Codex Browser 扩展 Native Messaging Host 注册项和 manifest，自动化接口返回 `Browser is not available: chrome`。本次没有使用其他浏览器冒充 Chrome，也不据此宣称浏览器控制台零错误。
