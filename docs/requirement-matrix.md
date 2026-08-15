# 课程要求矩阵

|要求|实现位置|
|---|---|
|10 个以上实体、15 张表、字段规模|`2025333541001戴哲语.sql` 中 23 张表，10 张以上表字段不少于 15 列|
|主键、外键|原始 SQL 各表主键及业务外键；`database/verify_requirements.sql` 校验|
|视图、JSON 字段、树形结构|`v_monthly_area_energy_carbon` 等视图；`operation_log.request_params`、`meter_node.parent_node_id`|
|模拟数据 5000+|`sp_generate_demo_energy_records(25)` 生成 25 天日度记录；设备/预警/日志过程同步生成|
|六类存储过程 CRUD|`ApiServlet.save/delete` 调用 commercial_complex、building、functional_area、merchant、meter_node、meter_device 的 `sp_save_*`/`sp_delete_*`|
|节点树增删改|`app.jsp` 的“计量节点树”页，`/api/meter-nodes/tree` 与节点 CRUD|
|数据库查询程序|`/api/analytics/*` 和 `/api/charts/*` 实际调用月度区域、商户排名、超预算、开放预警、项目效果、能源构成、节点树 7 个过程|
|条件查询|列表关键词、综合体筛选，图表日期范围/年份/月份/等级参数|
|图表≥5 种|趋势折线、区域柱状、能源环形、日期区域热力、绩效雷达、预算仪表盘|
|碳预算|`/api/budgets/refresh` 调用 `sp_refresh_budget_actuals`，预算超标调用 `sp_query_over_budget_areas`|
|预警整改|`/api/alerts/open`、`/api/corrective-tasks/{id}`，页面展示处理措施、结果、复核字段|
|节能项目评价|`/api/projects/effects` 调用 `sp_query_project_effect`，页面项目列表可查|
|登录与权限|`AuthFilter`、session、`/api/auth/login|logout|me`，bcrypt 演示哈希|
|JSON 展示与日志|列表保留 JSON 列，操作日志表可查询；前端统一表格展示|
## 三模块增量映射

| 能力 | 数据库对象 | 页面/接口 |
|---|---|---|
| 商户直计与公共分摊 | `energy_allocation_rule`、`merchant_energy_bill`、`merchant_energy_bill_detail`、`sp_preview_merchant_bill_allocation`、`sp_generate_merchant_energy_bills` | `#/merchant-bills`、`/api/merchant-bills/*` |
| 月度能碳管理报告 | `sp_generate_monthly_carbon_report_dataset` 及现有月度查询过程 | `#/monthly-reports`、`/api/monthly-reports/preview` |
| 数据质量闭环 | `data_quality_rule_config`、`data_quality_issue`、`data_quality_review`、`sp_scan_data_quality`、复核/解决/误报过程 | `#/data-quality`、`/api/data-quality/*` |
| JSON 展示与快照 | 账单计算快照、质量 source/before/after JSON | 账单明细和质量详情弹窗 |
| 数据修正触发碳核算 | 现有能耗更新触发器 + `data_quality_review` | `PUT /api/data-quality/issues/{id}/correct` |
| 跨综合体隔离 | 所有新增表的 `complex_id` 外键与后端参数化过滤 | 顶部综合体切换自动重载三个模块 |
# 本轮补充映射

- 多综合体演示：8 个启用综合体均具备建筑、区域、商户、计量树、设备、能耗、触发碳核算、预算、预警整改、项目评价、账单和质量问题数据，详见 `docs/eight-complex-data.md`。
- 登录安全扩展：`/register.jsp`、`post /api/auth/register`、`registered_user` 只读角色、BCrypt 和后端业务写权限拦截。
- 条件查询交互：统一表头排序支持分页列表、数据质量、账单、日志及专题查询，详见 `docs/table-sorting.md`。
