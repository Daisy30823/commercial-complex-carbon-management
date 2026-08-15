# 功能验收与缺陷修复报告

验收日期：2026-08-11  
验收环境：Java 17、MySQL 8.0（`localhost:3306/commercial_complex_carbon_db`）、Tomcat 10.1.57、Windows  
基线备份：`backups/functional-acceptance-baseline-20260811-214336.zip`（SHA-256：`287CCD9D55F83C10AC0888CE8BB815EC240C20F5DDCEE52113679497E6B3BD68`）

## 1. 数据基线

未重新执行主 SQL、未删除数据库、未删除原有模拟数据。验收前关键数量为：`energy_consumption_record=5500`、`carbon_accounting_record=5500`、`meter_device=220`、`alert_event=254`、`corrective_task=250`、`operation_log=500`。验收过程中新增两条带 `ACC-E-` 前缀的测试能耗记录，最终能耗/碳记录为 `5502/5502`；测试记录未删除，便于答辩追溯。六类 CRUD 测试记录均通过存储过程停用，未使用普通更新替代。

## 2. 六类存储过程 CRUD

| 页面/过程 | 新增前→后 | 修改验证 | 停用验证 | 校验/异常 | 结论 |
|---|---|---|---|---|---|
| 综合体 / `sp_save_commercial_complex`、`sp_delete_commercial_complex` | 新增测试编码 `ACC-0811220309`，ID 2 | 名称、地址和面积修改后查询一致 | `record_status:1→0` | 重复编码返回 400“编码或唯一字段已存在”；必填校验返回 400 | 通过 |
| 建筑 / `sp_save_building`、`sp_delete_building` | 测试建筑 ID 4 | 名称、面积、楼层变化已查询确认 | `record_status:1→0` | 非法部门外键返回 400；必填校验返回 400 | 通过 |
| 功能区域 / `sp_save_functional_area`、`sp_delete_functional_area` | 测试区域 ID 13 | 名称、楼层、面积变化已查询确认 | `record_status:1→0` | 非法建筑外键返回 400；必填校验返回 400 | 通过 |
| 商户 / `sp_save_merchant`、`sp_delete_merchant` | 测试商户 ID 11 | 名称、品牌、经营面积变化已查询确认 | `merchant_status:1→2` | 重复编码/必填项返回 400 | 通过 |
| 计量节点 / `sp_save_meter_node`、`sp_delete_meter_node` | 测试根节点 28、子节点 29 | 节点名称和父级关系变化已查询确认 | `node_status:1→0` | 父节点有子节点拒绝停用；自父级和循环关系均返回 400 | 通过 |
| 计量设备 / `sp_save_meter_device`、`sp_delete_meter_device` | 测试设备 ID 221 | 名称、型号、采集频率变化已查询确认 | `device_status:1→0` 且离线 | 非法节点/能源外键返回 400；必填校验返回 400 | 通过 |

后端统一使用 `CallableStatement` 调用上述过程，重复编码、外键、检查约束被转换为安全的中文错误，不向前端输出堆栈。

## 3. 计量节点树

页面实际加载 29 个节点，使用 `sp_query_meter_node_tree`；原生递归 `details/summary` 支持展开折叠。通过页面新增根节点、子节点、修改和停用，并刷新确认结构保持。删除有子节点的父节点返回“当前节点存在子节点，请先停用或迁移子节点”；后端阻止自引用和祖先循环。页面提供“新增根节点”和“新增子节点”按钮及节点详情表单。数据库过程调用均已在 Tomcat 日志与接口响应中验证。

## 4. 能耗与触发器

| 项目 | 数据库执行前 | 数据库执行后 | 结论 |
|---|---:|---:|---|
| 合法新增 | 5500 / 5500 | 5501 / 5501 | 通过，触发器自动生成碳记录 |
| 新增记录 | — | 能耗 ID 5501，`20.000000 kWh` | 通过 |
| 碳核算 | — | 活动数据 20、因子快照 0.5366、排放 10.732 kgCO₂e、同一 `energy_record_id` | 通过 |
| 修改记录 | 10→20 kWh | 碳记录仍为唯一 ID 5501，活动数据/排放更新为 20 / 10.732 | 通过，触发器重新核算 |

负读数、非法 JSON、缺少有效因子、设备与能源类型不一致均返回 400，未写入数据库；重复统计周期使用真实已存在周期返回 400。审核状态限定为 0/1/2。另有一条负向测试因使用了不存在的周期而合法写入（ID 5502），未删除，最终数量为 5502/5502，已在数据基线中明确记录。

## 5. 七个查询过程

以下接口均从页面“查询分析”入口实际调用 MySQL 存储过程，结果不是前端静态数据：

| 过程 | 实测条件 | 返回 |
|---|---|---:|
| `sp_query_monthly_area_energy_carbon` | 综合体 1、2026 年 8 月 | 60 行 |
| `sp_query_top_merchants_carbon` | 综合体 1、2026 年 8 月、Top 5 | 5 行 |
| `sp_query_over_budget_areas` | 预算 1 | 4 行 |
| `sp_query_open_alerts` | 综合体 1 | 204 行（刷新后按状态变化减少） |
| `sp_query_project_effect` | 综合体 1 | 7 行 |
| `sp_query_energy_mix` | 综合体 1、2026 年 8 月 | 5 行 |
| `sp_query_meter_node_tree` | 综合体 1 | 29 行，含状态字段 |

前端有加载、空结果和错误文本状态；非法参数由后端返回 400。查询分析页已在浏览器打开并显示真实结果。

## 6. 统计口径与图表

首页“近 30 日能源消费”已改为方案 B：`sum(consumption_amount * energy_type.standard_coal_coefficient)`，单位为 `tce`；同时返回 `energyBreakdown`，保留电力 kWh、天然气 m³、水 t、柴油 L、热力 GJ 的原始明细，禁止跨单位直接相加。当前实测综合能耗为约 `556.349 tce`。

六类 ECharts 均真实访问数据库：趋势折线（tce 与 tCO₂e 双轴）、区域柱状（tCO₂e）、能源环形（碳排放构成，tCO₂e）、日期×区域热力（tce）、区域绩效雷达（tce/㎡、kgCO₂e/㎡、预算率、预警数）、预算仪表盘（执行率）。浏览器主页及查询页面控制台错误数为 0；图表单位和换算已同步修正。大于 1000 kg 的碳排放前端优先显示 tCO₂e，普通值显示 kgCO₂e。

## 7. 碳预算

两次调用 `sp_refresh_budget_actuals(1)` 均成功。刷新前后预算明细实际排放合计 `1681580.125307 kgCO₂e`、预算合计 `14998143.002319 kgCO₂e`、超预算明细 4 条保持一致；重复刷新没有产生重复未关闭预警。首页仪表盘执行率约 11.211%，年度预算汇总与明细口径一致。

## 8. 预警—整改闭环

实测预警 14：`event_status 1→2→3`，`acknowledged_by_user_id=1`、`closed_by_user_id=1`；关联整改任务 14：`task_status 1→2→3`，措施、处理结果、复核结果写入数据库；操作日志由 500 增至 506。页面已提供预警确认/关闭按钮和整改任务页面入口。验收早期发现并修复了 acknowledge/close 参数方向错误，最终版本已重新部署并按正确方向验证。

## 9. 节能项目评价

`/api/projects` 列表、详情和状态筛选可用；`sp_query_project_effect(1)` 实测返回 7 行，包含节能量、减排量、节能率、投资回报率、回收期字段。数据库现有正值样例已核对，接口使用 `nullif`/空值兼容；未改动项目数据。

## 10. 通用与浏览器验收

登录、Session 用户信息、主页、菜单切换、列表查询/重置、真实分页、空状态、统一 Toast、表单必填、二次确认、退出登录和 Session 失效跳转均已检查。最终浏览器地址为 `http://localhost:8080/commercial-complex-carbon/app.jsp`，登录用户为 `admin`，主页实际打开；最终浏览器控制台无 error/warning。

## 11. 修复文件与验证命令

- `src/main/java/cn/complexcarbon/controller/ApiServlet.java`：分页、状态过滤、六类过程校验、能耗写入/触发器入口、图表 tce 口径、预警闭环、日志和错误映射。
- `src/main/webapp/assets/js/app.js`：分页/CRUD 表单、树展开折叠和子节点、查询分析入口、预警/整改操作、统一单位显示。
- `docs/functional-acceptance-report.md`：本报告。

已真实执行：`mvnw.cmd test`（3 个测试，0 失败）、`mvnw.cmd clean package`（BUILD SUCCESS）。最新 WAR：`<项目目录>\target\commercial-complex-carbon.war`，并已复制到 Tomcat `webapps` 后重启。

## 12. 仍存在的问题

本轮没有重构视觉主题。SQL 原始脚本中的部分中文注释在 PowerShell 日志中显示为编码乱码，但数据库对象和网页 UTF-8 内容可正常使用；计量树查询过程按课程要求返回停用节点并由页面显示停用状态。JUnit 当前仍以轻量 JSON/响应测试为主，数据库验收结果来自本机 MySQL 实测记录，后续可将本报告用例沉淀为自动化集成测试。
