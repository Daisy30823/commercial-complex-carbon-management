# API 摘要

统一响应：`{"success":true,"code":200,"message":"操作成功","data":...}`。除认证接口外均要求 session 登录。

|URL|方法|用途|数据库|
|---|---|---|---|
|`/api/auth/login`|POST|用户名密码登录|preparedstatement 查询 `app_user`|
|`/api/auth/logout`|POST|退出|销毁 session|
|`/api/auth/me`|GET|当前用户|session|
|`/api/dashboard/summary`|GET|首页 KPI|8 条 preparedstatement 聚合|
|`/api/complexes`、`/api/buildings`、`/api/areas`、`/api/merchants`、`/api/meter-nodes`、`/api/meter-devices`|GET/POST/PUT/DELETE|列表和六类 CRUD|对应 `sp_save_*`/`sp_delete_*`，写操作使用 CallableStatement|
|`/api/meter-nodes/tree`|GET|节点树|`sp_query_meter_node_tree`|
|`/api/analytics/monthly-area`|GET|月度区域能碳|`sp_query_monthly_area_energy_carbon`|
|`/api/analytics/top-merchants`|GET|商户排放排名|`sp_query_top_merchants_carbon`|
|`/api/analytics/over-budget`|GET|超预算区域|`sp_query_over_budget_areas`|
|`/api/analytics/open-alerts`|GET|未关闭预警|`sp_query_open_alerts`|
|`/api/analytics/project-effect`|GET|项目效果|`sp_query_project_effect`|
|`/api/analytics/energy-mix`|GET|能源构成|`sp_query_energy_mix`|
|`/api/charts/*`|GET|六类图表数据|过程或预编译聚合 SQL|
|`/api/budgets/refresh`|POST|刷新预算实际值|`sp_refresh_budget_actuals`|

错误情况：参数缺失返回 400；未登录返回 401；数据库异常返回 500 且不向前端泄露堆栈。
## 三模块新增接口

- `GET /api/allocation-rules`：读取当前综合体启用分摊规则；`POST/PUT/DELETE /api/allocation-rules`：规则管理，要求管理员或碳核算角色。
- `GET /api/merchant-bills`、`GET /api/merchant-bills/{id}`：当前版本账单及能源明细。
- `GET /api/merchant-bills/preview`：调用 `sp_preview_merchant_bill_allocation`；参数 `complexId/year/month/method`。
- `POST /api/merchant-bills/generate`：调用 `sp_generate_merchant_energy_bills`，只允许管理员、碳核算员、审核员。
- `PUT /api/merchant-bills/{id}/confirm`、`PUT /api/merchant-bills/{id}/void`：调用确认/作废过程；完整率和高风险问题由数据库过程校验。
- `GET /api/monthly-reports/preview`：调用月度报告数据集、七项查询过程和账单/预算/质量查询，返回可打印章节。
- `GET /api/data-quality/rules`、`GET /api/data-quality/issues`、`GET /api/data-quality/issues/{id}`：质量规则、问题和复核轨迹。
- `POST /api/data-quality/scan`：调用 `sp_scan_data_quality`；`PUT /review|resolve|false-positive|correct`：事务化复核、修正和闭环。
- `POST /api/data-quality/issues/{id}/create-alert`：创建或复用关联未关闭预警，source_snapshot 保存问题编号。
# 本轮新增接口与通用参数

## 用户注册

- URL：`post /api/auth/register`
- Content-Type：`application/json`
- 参数：`username`、`realName`、`phone`、`email`、`password`、`confirmPassword`
- 数据库：事务写入 `app_user`、`user_role`、`operation_log`
- 错误：用户名/邮箱重复、密码少于 8 位、两次密码不一致、邮箱格式错误、默认角色未初始化

## 列表排序

通用分页列表、商户账单和数据质量问题接口支持 `sortBy`、`sortOrder`。`sortOrder` 仅允许 `asc`/`desc`；`sortBy` 必须属于资源白名单，否则返回 400。
