# 2026-08-14 界面修复与回归报告

## 备份与数据基线

- 项目备份：`backup/0814-ui-fix-before-20260814-154949.zip`。
- 数据库备份：`backup/commercial_complex_carbon_db_before_0814_ui_fix.sql`。
- 修复前/后数量一致：`commercial_complex=3`、`building=4`、`functional_area=13`、`meter_device=222`、`energy_consumption_record=5502`、`carbon_accounting_record=5502`、`alert_event=254`、`operation_log=506`。
- 未执行主 SQL、未 drop database、未修改数据库结构、过程、触发器、函数或视图。

## 问题一：顶部综合体与建档列表矛盾

### 原因

后端通用 `list()` 查询把 `complexId` 条件错误应用到了 `commercial_complex` 自身，并默认附加 `record_status=1`。因此顶部选择器有多个启用综合体时，建档页面只返回当前上下文的一条启用记录。

### 修复

- `ApiServlet.java`：商业综合体建档不再附加 `complexId`，默认查询全部状态；其他业务列表继续按当前 `complexId` 过滤。
- 增加 `status=1/0` 可选过滤；关键字支持编码、名称和地址。
- `app.js`：建档列表增加“全部状态/启用/停用”筛选，显示“当前使用”上下文标签和 `m²` 单位。

### 实测

- 数据库 `commercial_complex=3`。
- 建档页面全部状态显示 3 条；启用筛选 2 条；停用筛选 1 条。
- 顶部选择器显示 2 个启用综合体。
- 新增/停用后列表仍保留全部档案，顶部选择器只保留启用记录。

## 问题二：登录页样式失效

### 原因

`login.jsp` 只引用通用 `app.css`，而通用样式没有 `.login-page`、`.login-card` 等登录布局；同时资源路径为脆弱的相对路径，无法保证不同 Context Path 和缓存场景下稳定加载。

### 修复

- 重写 `login.jsp` 为响应式双栏登录卡片。
- 新增 `assets/css/login.css`，使用动态 `${pageContext.request.contextPath}` 路径和 `v=20260814` 版本参数。
- 增加密码显示/隐藏、回车提交、表单校验、加载状态和中文错误提示。

### 实测

- 登录页首次打开布局正常，CSS HTTP 200。
- 错误密码显示“用户名或密码错误”，仍停留登录页。
- 使用本机私密管理员凭据登录成功并进入 `app.jsp#/dashboard`。
- 登录页、CSS、JS 和 API 无 404；浏览器控制台无 error/warn。

## 问题三：Dashboard 图表拥挤

### 修复

- `app.js` 的统一 `chart()` 先 `dispose()` 旧实例，再 `clear()`、`setOption(option,true)`、`resize()`，避免重复叠加。
- 趋势图：双 Y 轴中文图例、单位、Tooltip、日期抽样和 dataZoom。
- 区域排名：横向柱状、降序、截断标签、完整 Tooltip、数值标签和区域较多时 dataZoom。
- 能源构成：环形图中心布局、底部可滚动图例、百分比和排放量 Tooltip。
- 热力图：日期旋转/抽样、区域标签宽度、底部 visualMap、Tooltip 和 dataZoom。
- 雷达图：默认 3 个区域，支持 2—5 个自定义选择，图例滚动，指标中文化。
- 仪表盘：半圆 gauge，百分比固定两位小数，实际/预算/剩余统一使用 `tCO₂e`。
- `app.css`：图表卡片固定高度 340—350px，双列响应式布局，1366×768 和 1920×1080 不横向溢出；新增细滚动条和 ResizeObserver。

### 实测

- 浏览器检测到 6 个 ECharts canvas。
- 1920×1080：6 张卡片均有明确高度，页面无横向溢出。
- 1366×768：6 个图表仍存在，页面无横向溢出。
- 切换菜单、刷新、切换综合体和日期后图表重新查询；控制台无 error/warn。

## 构建、部署和浏览器验收

- `mvnw.cmd test`：BUILD SUCCESS，3 tests，0 failures。
- `mvnw.cmd clean package`：BUILD SUCCESS。
- 最新 WAR：`<项目目录>\target\commercial-complex-carbon.war`。
- 已停止 Tomcat、删除旧 WAR/展开目录、清理 `work` 和 `temp`、复制新 WAR、重新启动 Tomcat。
- 登录页：`http://localhost:8080/commercial-complex-carbon/login.jsp`。
- 系统首页：`http://localhost:8080/commercial-complex-carbon/app.jsp#/dashboard`。
- 验收截图：`docs/screenshots/0814-login-fixed.png`、`docs/screenshots/0814-complex-list-fixed.png`、`docs/screenshots/0814-dashboard-fixed.png`。

## 剩余说明

- 建档中已有历史测试数据仍按要求保留；停用记录通过状态筛选查看，不删除数据。
- ECharts 仍依赖现有 CDN；完全离线环境需预缓存 vendor 文件，但不影响当前本机联网演示。
