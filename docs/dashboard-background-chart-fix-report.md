# Dashboard 背景与图表运行时修复报告

## 备份与数据基线

- 项目备份：`backup/dashboard-visual-runtime-fix-before-20260814-212317.zip`，13,687,774 字节。
- 数据库备份：`backup/commercial_complex_carbon_db_before_dashboard_fix.sql`，4,442,078 字节。
- 修改前记录数：`commercial_complex=3`、`meter_device=222`、`energy_consumption_record=5502`、`carbon_accounting_record=5502`、`merchant_energy_bill=20`、`operation_log=508`。
- 未执行主 SQL，未修改数据库结构、表、过程、触发器、函数或视图。

## 背景过淡根因

背景素材已正确位于 `src/main/webapp/assets/images/app-background.png`，并设置在登录后所有模块共享的 `.main` 容器，不存在图片路径错误。真实问题是上一次遮罩仍为顶部 74%、底部 84% 的近白色覆盖，同时业务卡片使用完全不透明白色；页面大面积区域因此接近纯白。

修复后 `.main` 使用顶部 58%、底部 68% 的独立线性遮罩，背景定位为 `center bottom`、`cover`、固定且不平铺，并设置浅灰绿色降级背景。`.view` 和 `.module-view` 保持透明，卡片与 KPI 使用 94% 不透明白色，窄屏提高至 96%，不对父容器设置整体 `opacity`。

## 图表首次加载根因

旧 `loadDashboard()` 先 `await` Dashboard 摘要接口，摘要完成后才发出六个图表接口；图表卡片没有独立加载状态，因此在摘要和图表接口串行累计期间表现为纯白。`show('dashboard')` 虽然不等待异步函数，但不是图表最终不显示的直接原因；浏览器复核时图表容器在初始化前已有正宽高。

旧代码还存在多层历史 `chart()` / `loadDashboard()` 覆盖，后处理函数在图表首次绘制后再次以合并方式更新部分 Option，使生命周期不透明。真实接口计时还发现旧雷达查询约 11.5 秒：能耗、碳记录、预警和预算视图同时连接后形成多对多行膨胀。后端已改为各指标按区域预聚合后再连接，部署后雷达接口降至 116ms。修复采用独立 `dashboard-runtime.js`：

1. Dashboard 激活后立即写入六个“数据加载中”状态；
2. 等待两个浏览器绘制帧，并在必要时用 `ResizeObserver` 等待所有容器获得正宽高；
3. 摘要与六个图表接口同时发出，每个请求完成后立即独立渲染；
4. 单图失败显示中文错误和重试按钮，不阻塞其他图表；
5. 创建前销毁旧实例，使用 `notMerge:true`、`lazyUpdate:false` 和 `replaceMerge:['series']`；
6. 路由离开 Dashboard 时释放六个实例，切换综合体、日期、刷新和返回 Dashboard 都重新执行同一流程；
7. 不使用固定延时，最终再经过两个绘制帧统一 `resize()`。

## 仪表盘重叠根因

旧仪表盘先创建 Gauge Series，之后又通过合并式 `setOption` 局部修改 series；中心 `detail` 位于 10% 偏移，58% 长度的指针穿过中心数值区域。修复后只创建一个 Gauge Series，中心百分比只由 `detail` 输出，两位小数；`title`、`axisLabel` 均关闭，不使用 `graphic`。指针缩短为 42%，百分比下移到 30%，三项预算指标继续由图表下方三列 HTML 展示，单位统一为 `tCO₂e`。

## 商户账单说明

- 已从商户能碳账单主页面删除指定说明及其提示框，布局自动收紧。
- 已从账单详情和打印 DOM 删除同类内部模拟说明。
- 完整率不足时的业务风险警告继续保留，不影响查询、预览、生成、确认、打印和导出。
- `src/main/webapp` 搜索指定句及详情同类句均无残留。

## 修改文件

- `src/main/webapp/assets/js/dashboard-runtime.js`
- `src/main/webapp/assets/js/app.js`
- `src/main/webapp/assets/css/app.css`
- `src/main/webapp/app.jsp`
- `src/main/java/cn/complexcarbon/controller/ApiServlet.java`

## 验收状态

| 项目 | 状态 |
| --- | --- |
| `mvnw.cmd test` | BUILD SUCCESS，26 项测试通过 |
| `mvnw.cmd clean package` | BUILD SUCCESS，26 项测试通过 |
| Tomcat 冷部署 | 通过，HTTP 200，源/部署 WAR 均为 11,287,496 字节 |
| 首次登录六图自动加载 | 待部署后实测 |
| 仪表盘单值无重叠 | 待部署后实测 |
| 商户账单页面与详情 | Session/API 和部署源码检查通过；Chrome 页面待实测 |

部署后真实 Session/API 计时：摘要 231ms，趋势 159ms，排名 118ms，能源结构 123ms，热力图 82ms，雷达 116ms，仪表盘 15ms。修改后记录数与修改前一致。Chrome 无痕视觉验收尚未执行，原因是本机未连接 Codex Chrome 扩展；未使用其他浏览器冒充。
