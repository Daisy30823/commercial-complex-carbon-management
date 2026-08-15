# 数据表结构说明

共 29 张数据表。字段信息由 MySQL 8 元数据生成，NULL、默认值、键类型和备注保持与发布数据库一致。

## alert_event

预警事件。主键：`alert_event_id`；字段数：28。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `alert_event_id` | `bigint unsigned` | NO | - | PRI | 预警事件主键 |
| 2 | `alert_rule_id` | `bigint unsigned` | NO | - | MUL | 预警规则主键 |
| 3 | `complex_id` | `bigint unsigned` | NO | - | MUL | 商业综合体主键 |
| 4 | `area_id` | `bigint unsigned` | YES | - | MUL | 关联功能区域 |
| 5 | `meter_device_id` | `bigint unsigned` | YES | - | MUL | 关联计量设备 |
| 6 | `energy_record_id` | `bigint unsigned` | YES | - | MUL | 关联能耗记录 |
| 7 | `budget_detail_id` | `bigint unsigned` | YES | - | MUL | 关联预算明细 |
| 8 | `event_code` | `varchar(100)` | NO | - | UNI | 事件编码 |
| 9 | `event_type` | `varchar(60)` | NO | - |  | 事件类型 |
| 10 | `severity_level` | `varchar(20)` | NO | - |  | 预警等级 |
| 11 | `event_title` | `varchar(200)` | NO | - |  | 事件标题 |
| 12 | `event_content` | `varchar(1500)` | NO | - |  | 事件内容 |
| 13 | `detected_value` | `decimal(20,6)` | YES | - |  | 检测值 |
| 14 | `threshold_value` | `decimal(20,6)` | YES | - |  | 阈值快照 |
| 15 | `value_unit` | `varchar(40)` | YES | - |  | 数值单位 |
| 16 | `occurred_at` | `datetime` | NO | - | MUL | 发生时间 |
| 17 | `first_seen_at` | `datetime` | NO | - |  | 首次发现时间 |
| 18 | `last_seen_at` | `datetime` | NO | - |  | 最近发现时间 |
| 19 | `event_status` | `tinyint` | NO | 1 |  | 1待确认，2处理中，3已关闭，4误报 |
| 20 | `acknowledged_by_user_id` | `bigint unsigned` | YES | - | MUL | 确认人 |
| 21 | `acknowledged_at` | `datetime` | YES | - |  | 确认时间 |
| 22 | `closed_by_user_id` | `bigint unsigned` | YES | - | MUL | 关闭人 |
| 23 | `closed_at` | `datetime` | YES | - |  | 关闭时间 |
| 24 | `source_snapshot` | `json` | YES | - |  | 数据快照 |
| 25 | `close_reason` | `varchar(500)` | YES | - |  | 关闭原因 |
| 26 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 27 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 28 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## alert_rule

预警规则。主键：`alert_rule_id`；字段数：24。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `alert_rule_id` | `bigint unsigned` | NO | - | PRI | 预警规则主键 |
| 2 | `complex_id` | `bigint unsigned` | YES | - | MUL | 所属综合体 |
| 3 | `rule_code` | `varchar(60)` | NO | - | UNI | 规则编码 |
| 4 | `rule_name` | `varchar(120)` | NO | - |  | 规则名称 |
| 5 | `rule_category` | `varchar(50)` | NO | - |  | 规则分类 |
| 6 | `target_type` | `varchar(50)` | NO | - |  | 目标对象类型 |
| 7 | `metric_code` | `varchar(80)` | NO | - |  | 指标编码 |
| 8 | `comparison_operator` | `varchar(20)` | NO | - |  | 比较运算符 |
| 9 | `threshold_value` | `decimal(20,6)` | NO | - |  | 阈值 |
| 10 | `threshold_unit` | `varchar(40)` | YES | - |  | 阈值单位 |
| 11 | `duration_minutes` | `int` | NO | 0 |  | 持续时间 |
| 12 | `severity_level` | `varchar(20)` | NO | - |  | 预警等级 |
| 13 | `auto_create_task_flag` | `tinyint` | NO | 1 |  | 是否自动生成整改任务 |
| 14 | `notification_channels` | `json` | YES | - |  | 通知渠道 |
| 15 | `rule_expression` | `json` | YES | - |  | 规则表达式 |
| 16 | `priority_no` | `int` | NO | 100 |  | 优先级 |
| 17 | `effective_date` | `date` | YES | - |  | 生效日期 |
| 18 | `expiry_date` | `date` | YES | - |  | 失效日期 |
| 19 | `active_flag` | `tinyint` | NO | 1 | MUL | 是否启用 |
| 20 | `rule_status` | `tinyint` | NO | 1 |  | 规则状态 |
| 21 | `rule_description` | `varchar(1000)` | YES | - |  | 规则说明 |
| 22 | `created_by_user_id` | `bigint unsigned` | YES | - | MUL | 创建人 |
| 23 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 24 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## app_user

系统用户。主键：`user_id`；字段数：20。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `user_id` | `bigint unsigned` | NO | - | PRI | 用户主键 |
| 2 | `department_id` | `bigint unsigned` | YES | - | MUL | 所属部门 |
| 3 | `username` | `varchar(60)` | NO | - | UNI | 登录账号 |
| 4 | `password_hash` | `varchar(255)` | NO | - |  | 密码哈希 |
| 5 | `real_name` | `varchar(60)` | NO | - |  | 真实姓名 |
| 6 | `gender` | `tinyint` | YES | - |  | 0未知，1男，2女 |
| 7 | `employee_no` | `varchar(40)` | YES | - | UNI | 工号 |
| 8 | `job_title` | `varchar(80)` | YES | - |  | 岗位 |
| 9 | `phone` | `varchar(30)` | YES | - |  | 联系电话 |
| 10 | `email` | `varchar(120)` | YES | - |  | 邮箱 |
| 11 | `avatar_url` | `varchar(255)` | YES | - |  | 头像地址 |
| 12 | `last_login_time` | `datetime` | YES | - |  | 最后登录时间 |
| 13 | `last_login_ip` | `varchar(64)` | YES | - |  | 最后登录ip |
| 14 | `failed_login_count` | `int` | NO | 0 |  | 连续失败次数 |
| 15 | `locked_until` | `datetime` | YES | - |  | 锁定截止时间 |
| 16 | `user_status` | `tinyint` | NO | 1 | MUL | 1正常，0停用，2锁定 |
| 17 | `password_changed_at` | `datetime` | YES | - |  | 密码修改时间 |
| 18 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 19 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 20 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## building

综合体建筑。主键：`building_id`；字段数：21。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `building_id` | `bigint unsigned` | NO | - | PRI | 建筑主键 |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | 所属商业综合体 |
| 3 | `managing_department_id` | `bigint unsigned` | YES | - | MUL | 管理部门 |
| 4 | `building_code` | `varchar(40)` | NO | - |  | 建筑编码 |
| 5 | `building_name` | `varchar(100)` | NO | - |  | 建筑名称 |
| 6 | `building_type` | `varchar(50)` | NO | - |  | 建筑类型 |
| 7 | `address_detail` | `varchar(255)` | YES | - |  | 位置描述 |
| 8 | `gross_floor_area` | `decimal(18,2)` | NO | 0.00 |  | 建筑面积 |
| 9 | `above_ground_floors` | `int` | NO | 0 |  | 地上层数 |
| 10 | `underground_floors` | `int` | NO | 0 |  | 地下层数 |
| 11 | `building_height` | `decimal(10,2)` | YES | - |  | 建筑高度 |
| 12 | `completion_date` | `date` | YES | - |  | 竣工日期 |
| 13 | `use_start_date` | `date` | YES | - |  | 投入使用日期 |
| 14 | `design_daily_flow` | `int` | YES | - |  | 设计日客流量 |
| 15 | `air_conditioning_area` | `decimal(18,2)` | YES | - |  | 空调面积 |
| 16 | `energy_management_grade` | `varchar(20)` | YES | - |  | 能源管理等级 |
| 17 | `record_status` | `tinyint` | NO | 1 |  | 1启用，0停用 |
| 18 | `sort_no` | `int` | NO | 0 |  | 排序号 |
| 19 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 20 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 21 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## carbon_accounting_record

碳核算记录。主键：`carbon_accounting_id`；字段数：21。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `carbon_accounting_id` | `bigint unsigned` | NO | - | PRI | 碳核算记录主键 |
| 2 | `energy_record_id` | `bigint unsigned` | NO | - | UNI | 能源消费记录主键 |
| 3 | `emission_factor_id` | `bigint unsigned` | NO | - | MUL | 排放因子主键 |
| 4 | `accounting_code` | `varchar(100)` | NO | - | UNI | 核算记录编码 |
| 5 | `scope_no` | `tinyint` | NO | - |  | 核算范围 |
| 6 | `emission_category` | `varchar(60)` | NO | - |  | 排放类别 |
| 7 | `activity_data` | `decimal(20,6)` | NO | - |  | 活动数据 |
| 8 | `activity_data_unit` | `varchar(30)` | NO | - |  | 活动数据单位 |
| 9 | `factor_snapshot` | `decimal(20,10)` | NO | - |  | 排放因子快照 |
| 10 | `factor_unit_snapshot` | `varchar(80)` | NO | - |  | 因子单位快照 |
| 11 | `carbon_emission_kg` | `decimal(20,6)` | NO | - |  | 碳排放量kgco2e |
| 12 | `carbon_emission_t` | `decimal(20,9)` | YES | - |  | 碳排放量tco2e |
| 13 | `accounting_date` | `date` | NO | - | MUL | 核算日期 |
| 14 | `accounting_method` | `varchar(100)` | NO | 活动数据×排放因子 |  | 核算方法 |
| 15 | `formula_text` | `varchar(500)` | YES | - |  | 公式说明 |
| 16 | `calculated_by_user_id` | `bigint unsigned` | YES | - | MUL | 核算人 |
| 17 | `calculated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 核算时间 |
| 18 | `verified_by_user_id` | `bigint unsigned` | YES | - | MUL | 复核人 |
| 19 | `verified_at` | `datetime` | YES | - |  | 复核时间 |
| 20 | `accounting_status` | `tinyint` | NO | 1 |  | 0草稿，1已核算，2已复核，3作废 |
| 21 | `remark` | `varchar(500)` | YES | - |  | 备注 |

## carbon_budget

年度碳预算。主键：`carbon_budget_id`；字段数：23。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `carbon_budget_id` | `bigint unsigned` | NO | - | PRI | 碳预算主键 |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | 所属商业综合体 |
| 3 | `prepared_department_id` | `bigint unsigned` | YES | - | MUL | 编制部门 |
| 4 | `prepared_by_user_id` | `bigint unsigned` | YES | - | MUL | 编制人 |
| 5 | `approved_by_user_id` | `bigint unsigned` | YES | - | MUL | 审批人 |
| 6 | `budget_code` | `varchar(60)` | NO | - | UNI | 预算编码 |
| 7 | `budget_name` | `varchar(120)` | NO | - |  | 预算名称 |
| 8 | `budget_year` | `int` | NO | - | MUL | 预算年度 |
| 9 | `total_budget_emission_kg` | `decimal(20,6)` | NO | - |  | 年度预算kgco2e |
| 10 | `baseline_year` | `int` | YES | - |  | 基准年度 |
| 11 | `baseline_emission_kg` | `decimal(20,6)` | YES | - |  | 基准排放kgco2e |
| 12 | `target_reduction_rate` | `decimal(10,6)` | YES | - |  | 目标减排比例 |
| 13 | `actual_emission_kg` | `decimal(20,6)` | NO | 0.000000 |  | 实际排放kgco2e |
| 14 | `execution_rate` | `decimal(12,6)` | NO | 0.000000 |  | 预算执行率 |
| 15 | `remaining_budget_kg` | `decimal(20,6)` | NO | 0.000000 |  | 剩余预算kgco2e |
| 16 | `preparation_date` | `date` | YES | - |  | 编制日期 |
| 17 | `approval_date` | `date` | YES | - |  | 审批日期 |
| 18 | `effective_date` | `date` | YES | - |  | 生效日期 |
| 19 | `budget_status` | `tinyint` | NO | 1 |  | 0草稿，1执行中，2已完成，3作废 |
| 20 | `approval_comment` | `varchar(500)` | YES | - |  | 审批意见 |
| 21 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 22 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 23 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## carbon_budget_detail

月度区域预算明细。主键：`carbon_budget_detail_id`；字段数：19。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `carbon_budget_detail_id` | `bigint unsigned` | NO | - | PRI | 预算明细主键 |
| 2 | `carbon_budget_id` | `bigint unsigned` | NO | - | MUL | 碳预算主键 |
| 3 | `area_id` | `bigint unsigned` | NO | - | MUL | 功能区域主键 |
| 4 | `budget_month` | `tinyint` | NO | - |  | 预算月份 |
| 5 | `budget_emission_kg` | `decimal(20,6)` | NO | - |  | 预算排放kgco2e |
| 6 | `actual_emission_kg` | `decimal(20,6)` | NO | 0.000000 |  | 实际排放kgco2e |
| 7 | `execution_rate` | `decimal(12,6)` | NO | 0.000000 |  | 预算执行率 |
| 8 | `remaining_budget_kg` | `decimal(20,6)` | NO | 0.000000 |  | 剩余预算kgco2e |
| 9 | `over_budget_flag` | `tinyint` | NO | 0 | MUL | 是否超预算 |
| 10 | `warning_level` | `varchar(20)` | NO | 正常 |  | 预警等级 |
| 11 | `adjustment_amount_kg` | `decimal(20,6)` | NO | 0.000000 |  | 预算调整量 |
| 12 | `adjustment_reason` | `varchar(500)` | YES | - |  | 预算调整原因 |
| 13 | `adjusted_by_user_id` | `bigint unsigned` | YES | - | MUL | 调整人 |
| 14 | `adjusted_at` | `datetime` | YES | - |  | 调整时间 |
| 15 | `audit_status` | `tinyint` | NO | 1 |  | 审核状态 |
| 16 | `valid_flag` | `tinyint` | NO | 1 |  | 是否有效 |
| 17 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 18 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 19 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## commercial_complex

商业综合体基本档案。主键：`complex_id`；字段数：25。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `complex_id` | `bigint unsigned` | NO | - | PRI | 商业综合体主键 |
| 2 | `complex_code` | `varchar(40)` | NO | - | UNI | 综合体编码 |
| 3 | `complex_name` | `varchar(120)` | NO | - |  | 综合体名称 |
| 4 | `short_name` | `varchar(60)` | YES | - |  | 简称 |
| 5 | `unified_social_credit_code` | `varchar(40)` | YES | - |  | 运营主体统一社会信用代码 |
| 6 | `address` | `varchar(255)` | NO | - |  | 详细地址 |
| 7 | `province_name` | `varchar(50)` | NO | 浙江省 |  | 省份 |
| 8 | `city_name` | `varchar(50)` | NO | 杭州市 |  | 城市 |
| 9 | `district_name` | `varchar(50)` | YES | - |  | 区县 |
| 10 | `longitude` | `decimal(10,6)` | YES | - |  | 经度 |
| 11 | `latitude` | `decimal(10,6)` | YES | - |  | 纬度 |
| 12 | `gross_floor_area` | `decimal(18,2)` | NO | 0.00 |  | 总建筑面积 |
| 13 | `leasable_area` | `decimal(18,2)` | NO | 0.00 |  | 可出租面积 |
| 14 | `parking_spaces` | `int` | NO | 0 |  | 停车位数量 |
| 15 | `opening_date` | `date` | YES | - |  | 开业日期 |
| 16 | `business_start_time` | `time` | YES | - |  | 营业开始时间 |
| 17 | `business_end_time` | `time` | YES | - |  | 营业结束时间 |
| 18 | `operator_name` | `varchar(120)` | YES | - |  | 运营单位 |
| 19 | `property_company` | `varchar(120)` | YES | - |  | 物业单位 |
| 20 | `contact_name` | `varchar(60)` | YES | - |  | 联系人 |
| 21 | `contact_phone` | `varchar(30)` | YES | - |  | 联系电话 |
| 22 | `record_status` | `tinyint` | NO | 1 | MUL | 1启用，0停用 |
| 23 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 24 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 25 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## corrective_task

整改任务。主键：`corrective_task_id`；字段数：23。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `corrective_task_id` | `bigint unsigned` | NO | - | PRI | 整改任务主键 |
| 2 | `alert_event_id` | `bigint unsigned` | NO | - | UNI | 预警事件主键 |
| 3 | `responsible_department_id` | `bigint unsigned` | NO | - | MUL | 责任部门 |
| 4 | `responsible_user_id` | `bigint unsigned` | YES | - | MUL | 责任人 |
| 5 | `verifier_user_id` | `bigint unsigned` | YES | - | MUL | 复核人 |
| 6 | `task_code` | `varchar(100)` | NO | - | UNI | 任务编码 |
| 7 | `task_title` | `varchar(200)` | NO | - |  | 任务标题 |
| 8 | `task_content` | `varchar(1500)` | NO | - |  | 整改内容 |
| 9 | `priority_level` | `varchar(20)` | NO | 一般 |  | 优先级 |
| 10 | `planned_start_at` | `datetime` | YES | - |  | 计划开始时间 |
| 11 | `planned_end_at` | `datetime` | NO | - |  | 计划完成时间 |
| 12 | `actual_start_at` | `datetime` | YES | - |  | 实际开始时间 |
| 13 | `actual_end_at` | `datetime` | YES | - |  | 实际完成时间 |
| 14 | `corrective_measure` | `varchar(1500)` | YES | - |  | 整改措施 |
| 15 | `handling_result` | `varchar(1500)` | YES | - |  | 处理结果 |
| 16 | `task_status` | `tinyint` | NO | 1 |  | 1待处理，2处理中，3已完成，4已关闭 |
| 17 | `overdue_flag` | `tinyint` | NO | 0 |  | 是否逾期 |
| 18 | `verified_at` | `datetime` | YES | - |  | 复核时间 |
| 19 | `verification_result` | `varchar(500)` | YES | - |  | 复核结果 |
| 20 | `attachments` | `json` | YES | - |  | 附件 |
| 21 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 22 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 23 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## data_quality_issue

数据质量问题。主键：`data_quality_issue_id`；字段数：27。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `data_quality_issue_id` | `bigint unsigned` | NO | - | PRI | - |
| 2 | `issue_code` | `varchar(100)` | YES | - |  | - |
| 3 | `complex_id` | `bigint unsigned` | NO | - | MUL | - |
| 4 | `issue_rule` | `varchar(50)` | NO | - |  | - |
| 5 | `issue_category` | `varchar(50)` | NO | - |  | - |
| 6 | `severity_level` | `varchar(20)` | NO | - |  | - |
| 7 | `source_table` | `varchar(80)` | NO | - |  | - |
| 8 | `source_record_id` | `bigint unsigned` | YES | - |  | - |
| 9 | `meter_device_id` | `bigint unsigned` | YES | - | MUL | - |
| 10 | `energy_record_id` | `bigint unsigned` | YES | - | MUL | - |
| 11 | `issue_title` | `varchar(200)` | NO | - |  | - |
| 12 | `issue_description` | `varchar(1500)` | NO | - |  | - |
| 13 | `detected_value` | `varchar(255)` | YES | - |  | - |
| 14 | `expected_value` | `varchar(255)` | YES | - |  | - |
| 15 | `issue_fingerprint` | `varchar(64)` | NO | - | UNI | - |
| 16 | `issue_status` | `tinyint` | NO | 0 |  | 0????1????2????3?? |
| 17 | `assigned_user_id` | `bigint unsigned` | YES | - |  | - |
| 18 | `detected_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |
| 19 | `first_seen_at` | `datetime` | YES | - |  | - |
| 20 | `last_seen_at` | `datetime` | YES | - |  | - |
| 21 | `resolved_at` | `datetime` | YES | - |  | - |
| 22 | `resolved_by_user_id` | `bigint unsigned` | YES | - | MUL | - |
| 23 | `resolution_type` | `varchar(40)` | YES | - |  | - |
| 24 | `resolution_note` | `varchar(1000)` | YES | - |  | - |
| 25 | `source_snapshot` | `json` | YES | - |  | - |
| 26 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |
| 27 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |

## data_quality_review

数据质量复核。主键：`data_quality_review_id`；字段数：8。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `data_quality_review_id` | `bigint unsigned` | NO | - | PRI | - |
| 2 | `data_quality_issue_id` | `bigint unsigned` | NO | - | MUL | - |
| 3 | `reviewer_user_id` | `bigint unsigned` | NO | - | MUL | - |
| 4 | `review_action` | `varchar(30)` | NO | - |  | - |
| 5 | `before_snapshot` | `json` | YES | - |  | - |
| 6 | `after_snapshot` | `json` | YES | - |  | - |
| 7 | `review_comment` | `varchar(1000)` | YES | - |  | - |
| 8 | `reviewed_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |

## data_quality_rule_config

数据质量规则集中配置。主键：`rule_code`；字段数：7。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `rule_code` | `varchar(50)` | NO | - | PRI | - |
| 2 | `rule_name` | `varchar(120)` | NO | - |  | - |
| 3 | `rule_description` | `varchar(500)` | NO | - |  | - |
| 4 | `severity_level` | `varchar(20)` | NO | - |  | - |
| 5 | `threshold_json` | `json` | YES | - |  | - |
| 6 | `active_flag` | `tinyint` | NO | 1 |  | - |
| 7 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |

## emission_factor

碳排放因子。主键：`emission_factor_id`；字段数：22。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `emission_factor_id` | `bigint unsigned` | NO | - | PRI | 排放因子主键 |
| 2 | `energy_type_id` | `bigint unsigned` | NO | - | MUL | 能源类型主键 |
| 3 | `factor_code` | `varchar(60)` | NO | - | UNI | 因子编码 |
| 4 | `factor_name` | `varchar(120)` | NO | - |  | 因子名称 |
| 5 | `factor_value` | `decimal(20,10)` | NO | - |  | 排放因子数值 |
| 6 | `factor_unit` | `varchar(80)` | NO | - |  | 排放因子单位 |
| 7 | `numerator_unit` | `varchar(40)` | NO | kgco2e |  | 分子单位 |
| 8 | `denominator_unit` | `varchar(40)` | NO | - |  | 分母单位 |
| 9 | `greenhouse_gas_type` | `varchar(30)` | NO | co2e |  | 温室气体类型 |
| 10 | `scope_no` | `tinyint` | NO | - |  | 1直接，2购入能源间接，3其他间接 |
| 11 | `applicable_region` | `varchar(100)` | YES | - |  | 适用地区 |
| 12 | `factor_source` | `varchar(255)` | NO | - |  | 因子来源 |
| 13 | `source_document` | `varchar(255)` | YES | - |  | 来源文件 |
| 14 | `version_no` | `varchar(40)` | NO | - |  | 版本号 |
| 15 | `effective_date` | `date` | NO | - |  | 生效日期 |
| 16 | `expiry_date` | `date` | YES | - |  | 失效日期 |
| 17 | `uncertainty_rate` | `decimal(10,6)` | YES | - |  | 不确定性比例 |
| 18 | `active_flag` | `tinyint` | NO | 1 |  | 是否当前有效 |
| 19 | `factor_status` | `tinyint` | NO | 1 |  | 1启用，0停用 |
| 20 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 21 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 22 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## energy_allocation_rule

公共能耗分摊规则。主键：`allocation_rule_id`；字段数：17。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `allocation_rule_id` | `bigint unsigned` | NO | - | PRI | - |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | - |
| 3 | `energy_type_id` | `bigint unsigned` | YES | - |  | - |
| 4 | `building_id` | `bigint unsigned` | YES | - |  | - |
| 5 | `area_id` | `bigint unsigned` | YES | - |  | - |
| 6 | `rule_code` | `varchar(60)` | NO | - |  | - |
| 7 | `rule_name` | `varchar(120)` | NO | - |  | - |
| 8 | `allocation_method` | `varchar(30)` | NO | - |  | lease_area, contract_ratio, operating_days, manual |
| 9 | `parameters_json` | `json` | YES | - |  | - |
| 10 | `effective_date` | `date` | NO | - |  | - |
| 11 | `expiry_date` | `date` | YES | - |  | - |
| 12 | `active_flag` | `tinyint` | NO | 1 |  | - |
| 13 | `rule_config` | `json` | YES | - |  | - |
| 14 | `remark` | `varchar(500)` | YES | - |  | - |
| 15 | `created_by_user_id` | `bigint unsigned` | YES | - |  | - |
| 16 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |
| 17 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |

## energy_consumption_record

能源消费明细。主键：`energy_record_id`；字段数：25。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `energy_record_id` | `bigint unsigned` | NO | - | PRI | 能耗记录主键 |
| 2 | `meter_device_id` | `bigint unsigned` | NO | - | MUL | 计量设备主键 |
| 3 | `energy_type_id` | `bigint unsigned` | NO | - | MUL | 能源类型主键 |
| 4 | `record_code` | `varchar(100)` | NO | - | UNI | 记录编码 |
| 5 | `record_date` | `date` | NO | - | MUL | 统计日期 |
| 6 | `period_start` | `datetime` | NO | - |  | 统计开始时间 |
| 7 | `period_end` | `datetime` | NO | - |  | 统计结束时间 |
| 8 | `start_reading` | `decimal(20,6)` | NO | 0.000000 |  | 期初读数 |
| 9 | `end_reading` | `decimal(20,6)` | NO | 0.000000 |  | 期末读数 |
| 10 | `multiplier` | `decimal(18,6)` | NO | 1.000000 |  | 倍率快照 |
| 11 | `consumption_amount` | `decimal(20,6)` | NO | 0.000000 |  | 实际用量 |
| 12 | `consumption_unit` | `varchar(30)` | NO | - |  | 用量单位 |
| 13 | `unit_price` | `decimal(18,6)` | NO | 0.000000 |  | 能源单价 |
| 14 | `energy_cost` | `decimal(20,2)` | NO | 0.00 |  | 能源成本 |
| 15 | `data_source` | `varchar(30)` | NO | auto |  | 数据来源 |
| 16 | `data_quality_status` | `tinyint` | NO | 1 |  | 1正常，2估算，3补录，4异常 |
| 17 | `abnormal_flag` | `tinyint` | NO | 0 | MUL | 是否异常 |
| 18 | `audit_status` | `tinyint` | NO | 0 |  | 0待审，1通过，2退回 |
| 19 | `auditor_user_id` | `bigint unsigned` | YES | - | MUL | 审核人 |
| 20 | `audit_time` | `datetime` | YES | - |  | 审核时间 |
| 21 | `raw_payload` | `json` | YES | - |  | 原始设备报文 |
| 22 | `correction_reason` | `varchar(500)` | YES | - |  | 数据修正原因 |
| 23 | `created_by_user_id` | `bigint unsigned` | YES | - | MUL | 创建人 |
| 24 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 25 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## energy_saving_project

节能项目。主键：`energy_saving_project_id`；字段数：29。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `energy_saving_project_id` | `bigint unsigned` | NO | - | PRI | 节能项目主键 |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | 商业综合体主键 |
| 3 | `responsible_department_id` | `bigint unsigned` | NO | - | MUL | 责任部门 |
| 4 | `area_id` | `bigint unsigned` | YES | - | MUL | 实施区域 |
| 5 | `project_manager_user_id` | `bigint unsigned` | YES | - | MUL | 项目负责人 |
| 6 | `project_code` | `varchar(80)` | NO | - | UNI | 项目编码 |
| 7 | `project_name` | `varchar(200)` | NO | - |  | 项目名称 |
| 8 | `project_type` | `varchar(80)` | NO | - |  | 项目类型 |
| 9 | `project_source` | `varchar(80)` | YES | - |  | 项目来源 |
| 10 | `supplier_name` | `varchar(150)` | YES | - |  | 供应商 |
| 11 | `planned_start_date` | `date` | YES | - |  | 计划开始日期 |
| 12 | `planned_end_date` | `date` | YES | - |  | 计划结束日期 |
| 13 | `actual_start_date` | `date` | YES | - |  | 实际开始日期 |
| 14 | `actual_end_date` | `date` | YES | - |  | 实际结束日期 |
| 15 | `investment_amount` | `decimal(20,2)` | NO | 0.00 |  | 投资金额 |
| 16 | `expected_annual_energy_saving` | `decimal(20,6)` | NO | 0.000000 |  | 预计年节能量 |
| 17 | `expected_energy_unit` | `varchar(30)` | YES | - |  | 预计节能单位 |
| 18 | `expected_carbon_reduction_kg` | `decimal(20,6)` | NO | 0.000000 |  | 预计减排kgco2e |
| 19 | `expected_cost_saving` | `decimal(20,2)` | NO | 0.00 |  | 预计年节约费用 |
| 20 | `baseline_start_date` | `date` | YES | - |  | 基准期开始日期 |
| 21 | `baseline_end_date` | `date` | YES | - |  | 基准期结束日期 |
| 22 | `project_status` | `tinyint` | NO | 1 |  | 0拟建，1实施中，2已完成，3暂停，4终止 |
| 23 | `acceptance_status` | `tinyint` | NO | 0 |  | 0未验收，1通过，2未通过 |
| 24 | `acceptance_date` | `date` | YES | - |  | 验收日期 |
| 25 | `project_description` | `varchar(1500)` | YES | - |  | 项目说明 |
| 26 | `attachments` | `json` | YES | - |  | 附件 |
| 27 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 28 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 29 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## energy_type

能源类型与折标系数。主键：`energy_type_id`；字段数：17。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `energy_type_id` | `bigint unsigned` | NO | - | PRI | 能源类型主键 |
| 2 | `energy_code` | `varchar(40)` | NO | - | UNI | 能源编码 |
| 3 | `energy_name` | `varchar(60)` | NO | - | UNI | 能源名称 |
| 4 | `energy_category` | `varchar(30)` | NO | - |  | 能源类别 |
| 5 | `standard_unit` | `varchar(30)` | NO | - |  | 标准计量单位 |
| 6 | `display_unit` | `varchar(30)` | NO | - |  | 展示单位 |
| 7 | `decimal_places` | `int` | NO | 3 |  | 小数位数 |
| 8 | `direct_emission_flag` | `tinyint` | NO | 0 |  | 是否直接排放源 |
| 9 | `indirect_emission_flag` | `tinyint` | NO | 1 |  | 是否间接排放源 |
| 10 | `carbon_accounting_flag` | `tinyint` | NO | 1 |  | 是否参与碳核算 |
| 11 | `standard_coal_coefficient` | `decimal(20,8)` | YES | - |  | 折标煤系数 |
| 12 | `calorific_value` | `decimal(20,8)` | YES | - |  | 低位发热量 |
| 13 | `sort_no` | `int` | NO | 0 |  | 排序号 |
| 14 | `energy_status` | `tinyint` | NO | 1 |  | 1启用，0停用 |
| 15 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 16 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 17 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## functional_area

建筑功能区域。主键：`area_id`；字段数：23。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `area_id` | `bigint unsigned` | NO | - | PRI | 功能区域主键 |
| 2 | `building_id` | `bigint unsigned` | NO | - | MUL | 所属建筑 |
| 3 | `responsible_department_id` | `bigint unsigned` | YES | - | MUL | 责任部门 |
| 4 | `area_code` | `varchar(50)` | NO | - |  | 区域编码 |
| 5 | `area_name` | `varchar(100)` | NO | - |  | 区域名称 |
| 6 | `area_type` | `varchar(50)` | NO | - | MUL | 区域类型 |
| 7 | `floor_no` | `varchar(20)` | YES | - |  | 所在楼层 |
| 8 | `zone_name` | `varchar(60)` | YES | - |  | 分区名称 |
| 9 | `gross_area` | `decimal(18,2)` | NO | 0.00 |  | 区域面积 |
| 10 | `rentable_area` | `decimal(18,2)` | NO | 0.00 |  | 可出租面积 |
| 11 | `public_area_flag` | `tinyint` | NO | 0 |  | 是否公共区域 |
| 12 | `opening_time` | `time` | YES | - |  | 开放开始时间 |
| 13 | `closing_time` | `time` | YES | - |  | 开放结束时间 |
| 14 | `design_capacity` | `int` | YES | - |  | 设计容纳人数 |
| 15 | `current_occupancy` | `int` | YES | - |  | 当前人数 |
| 16 | `operation_status` | `varchar(30)` | NO | 正常 |  | 运营状态 |
| 17 | `energy_management_level` | `varchar(20)` | YES | - |  | 能耗管理级别 |
| 18 | `carbon_budget_enabled` | `tinyint` | NO | 1 |  | 是否启用碳预算 |
| 19 | `record_status` | `tinyint` | NO | 1 |  | 1启用，0停用 |
| 20 | `sort_no` | `int` | NO | 0 |  | 排序号 |
| 21 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 22 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 23 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## merchant

入驻商户。主键：`merchant_id`；字段数：25。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `merchant_id` | `bigint unsigned` | NO | - | PRI | 商户主键 |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | 所属商业综合体 |
| 3 | `merchant_code` | `varchar(50)` | NO | - |  | 商户编码 |
| 4 | `merchant_name` | `varchar(120)` | NO | - |  | 商户名称 |
| 5 | `brand_name` | `varchar(120)` | YES | - |  | 品牌名称 |
| 6 | `merchant_category` | `varchar(60)` | NO | - | MUL | 商户类型 |
| 7 | `unified_social_credit_code` | `varchar(40)` | YES | - | UNI | 统一社会信用代码 |
| 8 | `legal_representative` | `varchar(60)` | YES | - |  | 法定代表人 |
| 9 | `contact_name` | `varchar(60)` | YES | - |  | 联系人 |
| 10 | `contact_phone` | `varchar(30)` | YES | - |  | 联系电话 |
| 11 | `contact_email` | `varchar(120)` | YES | - |  | 邮箱 |
| 12 | `business_license_no` | `varchar(80)` | YES | - |  | 营业执照编号 |
| 13 | `business_scope` | `varchar(500)` | YES | - |  | 经营范围 |
| 14 | `planned_business_hours` | `varchar(100)` | YES | - |  | 营业时间 |
| 15 | `operating_area` | `decimal(18,2)` | NO | 0.00 |  | 经营面积 |
| 16 | `employee_count` | `int` | NO | 0 |  | 员工数量 |
| 17 | `high_energy_flag` | `tinyint` | NO | 0 |  | 是否重点用能商户 |
| 18 | `risk_level` | `varchar(20)` | YES | - |  | 能耗风险等级 |
| 19 | `settlement_mode` | `varchar(30)` | YES | - |  | 能源费用结算方式 |
| 20 | `merchant_status` | `tinyint` | NO | 1 | MUL | 1营业，0停业，2退场 |
| 21 | `entry_date` | `date` | YES | - |  | 入驻日期 |
| 22 | `exit_date` | `date` | YES | - |  | 退场日期 |
| 23 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 24 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 25 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## merchant_energy_bill

商户月度能碳账单。主键：`merchant_energy_bill_id`；字段数：34。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `merchant_energy_bill_id` | `bigint unsigned` | NO | - | PRI | - |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | - |
| 3 | `merchant_id` | `bigint unsigned` | NO | - | MUL | - |
| 4 | `allocation_rule_id` | `bigint unsigned` | YES | - | MUL | - |
| 5 | `bill_code` | `varchar(100)` | NO | - | UNI | - |
| 6 | `bill_year` | `int` | NO | - |  | - |
| 7 | `bill_month` | `tinyint` | NO | - |  | - |
| 8 | `version_no` | `int` | NO | 1 |  | - |
| 9 | `current_version_flag` | `tinyint` | NO | 1 |  | - |
| 10 | `period_start` | `date` | NO | - |  | - |
| 11 | `period_end` | `date` | NO | - |  | - |
| 12 | `direct_energy_cost` | `decimal(20,2)` | NO | 0.00 |  | - |
| 13 | `allocated_energy_cost` | `decimal(20,2)` | NO | 0.00 |  | - |
| 14 | `total_energy_cost` | `decimal(20,2)` | NO | 0.00 |  | - |
| 15 | `direct_energy_tce` | `decimal(20,8)` | NO | 0.00000000 |  | - |
| 16 | `allocated_energy_tce` | `decimal(20,8)` | NO | 0.00000000 |  | - |
| 17 | `total_energy_tce` | `decimal(20,8)` | NO | 0.00000000 |  | - |
| 18 | `total_standard_coal_tce` | `decimal(20,8)` | NO | 0.00000000 |  | - |
| 19 | `direct_carbon_kg` | `decimal(20,6)` | NO | 0.000000 |  | - |
| 20 | `allocated_carbon_kg` | `decimal(20,6)` | NO | 0.000000 |  | - |
| 21 | `total_carbon_kg` | `decimal(20,6)` | NO | 0.000000 |  | - |
| 22 | `data_completeness_rate` | `decimal(8,4)` | NO | 0.0000 |  | - |
| 23 | `allocation_weight` | `decimal(18,10)` | NO | 0.0000000000 |  | - |
| 24 | `bill_status` | `tinyint` | NO | 0 |  | 0???1????2??? |
| 25 | `generated_by_user_id` | `bigint unsigned` | YES | - |  | - |
| 26 | `confirmed_by_user_id` | `bigint unsigned` | YES | - | MUL | - |
| 27 | `confirmed_at` | `datetime` | YES | - |  | - |
| 28 | `voided_by_user_id` | `bigint unsigned` | YES | - | MUL | - |
| 29 | `voided_at` | `datetime` | YES | - |  | - |
| 30 | `void_reason` | `varchar(500)` | YES | - |  | - |
| 31 | `generated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |
| 32 | `remark` | `varchar(500)` | YES | - |  | - |
| 33 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |
| 34 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |

## merchant_energy_bill_detail

商户账单明细。主键：`merchant_energy_bill_detail_id`；字段数：19。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `merchant_energy_bill_detail_id` | `bigint unsigned` | NO | - | PRI | - |
| 2 | `merchant_energy_bill_id` | `bigint unsigned` | NO | - | MUL | - |
| 3 | `energy_type_id` | `bigint unsigned` | NO | - | MUL | - |
| 4 | `source_type` | `varchar(20)` | NO | - |  | direct?allocated |
| 5 | `source_area_id` | `bigint unsigned` | YES | - |  | - |
| 6 | `consumption_amount` | `decimal(20,6)` | NO | 0.000000 |  | - |
| 7 | `consumption_unit` | `varchar(30)` | NO | - |  | - |
| 8 | `standard_coal_tce` | `decimal(20,8)` | NO | 0.00000000 |  | - |
| 9 | `energy_cost` | `decimal(20,2)` | NO | 0.00 |  | - |
| 10 | `carbon_emission_kg` | `decimal(20,6)` | NO | 0.000000 |  | - |
| 11 | `allocation_base_amount` | `decimal(20,6)` | YES | - |  | - |
| 12 | `allocation_weight` | `decimal(18,10)` | YES | - |  | - |
| 13 | `allocation_ratio` | `decimal(18,10)` | YES | - |  | - |
| 14 | `allocation_method` | `varchar(30)` | YES | - |  | - |
| 15 | `source_record_count` | `int` | NO | 0 |  | - |
| 16 | `calculation_snapshot` | `json` | YES | - |  | - |
| 17 | `calculation_snapshot_json` | `json` | YES | - |  | - |
| 18 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |
| 19 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | - |

## merchant_occupancy

商户入驻区域关系。主键：`occupancy_id`；字段数：19。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `occupancy_id` | `bigint unsigned` | NO | - | PRI | 入驻关系主键 |
| 2 | `merchant_id` | `bigint unsigned` | NO | - | MUL | 商户主键 |
| 3 | `area_id` | `bigint unsigned` | NO | - | MUL | 功能区域主键 |
| 4 | `contract_code` | `varchar(60)` | NO | - | UNI | 合同编号 |
| 5 | `occupancy_start_date` | `date` | NO | - |  | 入驻开始日期 |
| 6 | `occupancy_end_date` | `date` | YES | - |  | 入驻结束日期 |
| 7 | `lease_area` | `decimal(18,2)` | NO | 0.00 |  | 租赁面积 |
| 8 | `lease_purpose` | `varchar(100)` | YES | - |  | 租赁用途 |
| 9 | `rent_calculation_mode` | `varchar(30)` | YES | - |  | 租金计算方式 |
| 10 | `energy_settlement_mode` | `varchar(30)` | YES | - |  | 能源结算方式 |
| 11 | `shared_energy_ratio` | `decimal(10,6)` | NO | 0.000000 |  | 公共能耗分摊比例 |
| 12 | `deposit_amount` | `decimal(18,2)` | NO | 0.00 |  | 押金 |
| 13 | `contract_status` | `tinyint` | NO | 1 |  | 合同状态 |
| 14 | `current_valid_flag` | `tinyint` | NO | 1 |  | 是否当前有效 |
| 15 | `signed_by_user_id` | `bigint unsigned` | YES | - | MUL | 经办用户 |
| 16 | `signed_at` | `datetime` | YES | - |  | 签订时间 |
| 17 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 18 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 19 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## meter_device

计量设备。主键：`meter_device_id`；字段数：27。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `meter_device_id` | `bigint unsigned` | NO | - | PRI | 计量设备主键 |
| 2 | `meter_node_id` | `bigint unsigned` | NO | - | MUL | 所属计量节点 |
| 3 | `energy_type_id` | `bigint unsigned` | NO | - | MUL | 能源类型 |
| 4 | `device_code` | `varchar(80)` | NO | - | UNI | 设备编码 |
| 5 | `device_name` | `varchar(120)` | NO | - |  | 设备名称 |
| 6 | `device_type` | `varchar(60)` | NO | - |  | 设备类型 |
| 7 | `serial_number` | `varchar(100)` | YES | - | UNI | 序列号 |
| 8 | `manufacturer` | `varchar(120)` | YES | - |  | 生产厂家 |
| 9 | `model_number` | `varchar(100)` | YES | - |  | 设备型号 |
| 10 | `communication_protocol` | `varchar(50)` | YES | - |  | 通信协议 |
| 11 | `communication_address` | `varchar(100)` | YES | - |  | 通信地址 |
| 12 | `measuring_unit` | `varchar(30)` | NO | - |  | 计量单位 |
| 13 | `multiplier` | `decimal(18,6)` | NO | 1.000000 |  | 倍率 |
| 14 | `accuracy_class` | `varchar(30)` | YES | - |  | 精度等级 |
| 15 | `collection_frequency_minutes` | `int` | NO | 60 |  | 采集频率 |
| 16 | `installation_location` | `varchar(255)` | YES | - |  | 安装位置 |
| 17 | `installation_date` | `date` | YES | - |  | 安装日期 |
| 18 | `commissioning_date` | `date` | YES | - |  | 投运日期 |
| 19 | `last_calibration_date` | `date` | YES | - |  | 最近检定日期 |
| 20 | `next_calibration_date` | `date` | YES | - |  | 下次检定日期 |
| 21 | `last_collection_time` | `datetime` | YES | - |  | 最近采集时间 |
| 22 | `online_status` | `tinyint` | NO | 1 |  | 1在线，0离线 |
| 23 | `device_status` | `tinyint` | NO | 1 | MUL | 1正常，0停用，2故障 |
| 24 | `warranty_expiry_date` | `date` | YES | - |  | 质保截止日期 |
| 25 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 26 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 27 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## meter_node

分级计量节点树。主键：`meter_node_id`；字段数：23。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `meter_node_id` | `bigint unsigned` | NO | - | PRI | 计量节点主键 |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | 所属商业综合体 |
| 3 | `building_id` | `bigint unsigned` | YES | - | MUL | 所属建筑 |
| 4 | `area_id` | `bigint unsigned` | YES | - | MUL | 所属功能区域 |
| 5 | `merchant_id` | `bigint unsigned` | YES | - | MUL | 所属商户 |
| 6 | `energy_type_id` | `bigint unsigned` | YES | - | MUL | 主要能源类型 |
| 7 | `parent_node_id` | `bigint unsigned` | YES | - | MUL | 上级计量节点 |
| 8 | `node_code` | `varchar(60)` | NO | - |  | 节点编码 |
| 9 | `node_name` | `varchar(120)` | NO | - |  | 节点名称 |
| 10 | `node_type` | `varchar(40)` | NO | - |  | 节点类型 |
| 11 | `node_level` | `int` | NO | 1 |  | 节点层级 |
| 12 | `node_path` | `varchar(1000)` | YES | - |  | 节点路径 |
| 13 | `allocation_method` | `varchar(30)` | YES | - |  | 能耗分摊方式 |
| 14 | `allocation_ratio` | `decimal(10,6)` | NO | 1.000000 |  | 能耗分摊比例 |
| 15 | `virtual_node_flag` | `tinyint` | NO | 0 |  | 是否虚拟节点 |
| 16 | `leaf_node_flag` | `tinyint` | NO | 1 |  | 是否叶子节点 |
| 17 | `data_aggregation_flag` | `tinyint` | NO | 1 |  | 是否参与汇总 |
| 18 | `carbon_accounting_flag` | `tinyint` | NO | 1 |  | 是否参与碳核算 |
| 19 | `node_status` | `tinyint` | NO | 1 |  | 1启用，0停用 |
| 20 | `sort_no` | `int` | NO | 0 |  | 排序号 |
| 21 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 22 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 23 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## operation_log

系统操作审计日志。主键：`operation_log_id`；字段数：19。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `operation_log_id` | `bigint unsigned` | NO | - | PRI | 日志主键 |
| 2 | `user_id` | `bigint unsigned` | YES | - | MUL | 操作用户 |
| 3 | `username_snapshot` | `varchar(60)` | YES | - |  | 用户名快照 |
| 4 | `module_name` | `varchar(80)` | NO | - | MUL | 模块名称 |
| 5 | `business_type` | `varchar(40)` | NO | - |  | 业务类型 |
| 6 | `object_type` | `varchar(80)` | YES | - |  | 操作对象类型 |
| 7 | `object_id` | `varchar(80)` | YES | - |  | 操作对象主键 |
| 8 | `operation_description` | `varchar(500)` | YES | - |  | 操作描述 |
| 9 | `request_method` | `varchar(20)` | YES | - |  | 请求方法 |
| 10 | `request_url` | `varchar(500)` | YES | - |  | 请求地址 |
| 11 | `request_params` | `json` | YES | - |  | 请求参数 |
| 12 | `response_code` | `varchar(20)` | YES | - |  | 响应代码 |
| 13 | `response_body` | `json` | YES | - |  | 响应结果 |
| 14 | `operation_result` | `tinyint` | NO | 1 |  | 1成功，0失败 |
| 15 | `error_message` | `text` | YES | - |  | 错误信息 |
| 16 | `ip_address` | `varchar(64)` | YES | - |  | ip地址 |
| 17 | `user_agent` | `varchar(500)` | YES | - |  | 用户代理 |
| 18 | `execution_time_ms` | `int` | YES | - |  | 执行耗时 |
| 19 | `operation_time` | `datetime` | NO | CURRENT_TIMESTAMP | MUL | 操作时间 |

## project_evaluation

项目效果评价。主键：`project_evaluation_id`；字段数：30。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `project_evaluation_id` | `bigint unsigned` | NO | - | PRI | 项目评价主键 |
| 2 | `energy_saving_project_id` | `bigint unsigned` | NO | - | MUL | 节能项目主键 |
| 3 | `evaluator_user_id` | `bigint unsigned` | YES | - | MUL | 评价人 |
| 4 | `evaluation_no` | `int` | NO | 1 |  | 评价次数 |
| 5 | `evaluation_type` | `varchar(40)` | NO | - |  | 评价类型 |
| 6 | `evaluation_date` | `date` | NO | - | MUL | 评价日期 |
| 7 | `baseline_start_date` | `date` | NO | - |  | 基准期开始日期 |
| 8 | `baseline_end_date` | `date` | NO | - |  | 基准期结束日期 |
| 9 | `evaluation_start_date` | `date` | NO | - |  | 评价期开始日期 |
| 10 | `evaluation_end_date` | `date` | NO | - |  | 评价期结束日期 |
| 11 | `baseline_energy_amount` | `decimal(20,6)` | NO | 0.000000 |  | 基准期能耗 |
| 12 | `normalized_baseline_energy` | `decimal(20,6)` | NO | 0.000000 |  | 归一化基准能耗 |
| 13 | `actual_energy_amount` | `decimal(20,6)` | NO | 0.000000 |  | 评价期实际能耗 |
| 14 | `energy_unit` | `varchar(30)` | NO | - |  | 能耗单位 |
| 15 | `energy_saving_amount` | `decimal(20,6)` | NO | 0.000000 |  | 实际节能量 |
| 16 | `energy_saving_rate` | `decimal(12,6)` | NO | 0.000000 |  | 节能率 |
| 17 | `baseline_carbon_kg` | `decimal(20,6)` | NO | 0.000000 |  | 基准期碳排放 |
| 18 | `actual_carbon_kg` | `decimal(20,6)` | NO | 0.000000 |  | 评价期碳排放 |
| 19 | `carbon_reduction_kg` | `decimal(20,6)` | NO | 0.000000 |  | 实际减排量 |
| 20 | `cost_saving_amount` | `decimal(20,2)` | NO | 0.00 |  | 实际节约费用 |
| 21 | `annualized_cost_saving` | `decimal(20,2)` | NO | 0.00 |  | 年化节约费用 |
| 22 | `return_on_investment_rate` | `decimal(12,6)` | NO | 0.000000 |  | 投资回报率 |
| 23 | `payback_period_months` | `decimal(12,2)` | YES | - |  | 投资回收期 |
| 24 | `evaluation_conclusion` | `varchar(1500)` | YES | - |  | 评价结论 |
| 25 | `evaluation_status` | `tinyint` | NO | 1 |  | 0草稿，1完成，2复核通过 |
| 26 | `verified_by_user_id` | `bigint unsigned` | YES | - | MUL | 复核人 |
| 27 | `verified_at` | `datetime` | YES | - |  | 复核时间 |
| 28 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 29 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 30 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## property_department

物业部门及组织树。主键：`department_id`；字段数：18。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `department_id` | `bigint unsigned` | NO | - | PRI | 部门主键 |
| 2 | `complex_id` | `bigint unsigned` | NO | - | MUL | 所属商业综合体 |
| 3 | `parent_department_id` | `bigint unsigned` | YES | - | MUL | 上级部门 |
| 4 | `department_code` | `varchar(40)` | NO | - |  | 部门编码 |
| 5 | `department_name` | `varchar(100)` | NO | - |  | 部门名称 |
| 6 | `department_type` | `varchar(40)` | YES | - |  | 部门类型 |
| 7 | `department_level` | `int` | NO | 1 |  | 部门层级 |
| 8 | `department_path` | `varchar(500)` | YES | - |  | 部门路径 |
| 9 | `manager_name` | `varchar(60)` | YES | - |  | 负责人 |
| 10 | `contact_phone` | `varchar(30)` | YES | - |  | 联系电话 |
| 11 | `contact_email` | `varchar(120)` | YES | - |  | 邮箱 |
| 12 | `office_location` | `varchar(150)` | YES | - |  | 办公地点 |
| 13 | `responsibility` | `varchar(500)` | YES | - |  | 职责 |
| 14 | `sort_no` | `int` | NO | 0 |  | 排序号 |
| 15 | `department_status` | `tinyint` | NO | 1 |  | 1启用，0停用 |
| 16 | `remark` | `varchar(500)` | YES | - |  | 备注 |
| 17 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 18 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## sys_role

系统角色。主键：`role_id`；字段数：12。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `role_id` | `bigint unsigned` | NO | - | PRI | 角色主键 |
| 2 | `role_code` | `varchar(40)` | NO | - | UNI | 角色编码 |
| 3 | `role_name` | `varchar(80)` | NO | - |  | 角色名称 |
| 4 | `data_scope` | `varchar(30)` | NO | self |  | 数据范围 |
| 5 | `role_description` | `varchar(500)` | YES | - |  | 角色说明 |
| 6 | `sort_no` | `int` | NO | 0 |  | 排序号 |
| 7 | `role_status` | `tinyint` | NO | 1 | MUL | 1启用，0停用 |
| 8 | `built_in_flag` | `tinyint` | NO | 0 |  | 是否内置 |
| 9 | `created_by_user_id` | `bigint unsigned` | YES | - | MUL | 创建人 |
| 10 | `created_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 创建时间 |
| 11 | `updated_by_user_id` | `bigint unsigned` | YES | - | MUL | 更新人 |
| 12 | `updated_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 更新时间 |

## user_role

用户角色关系。主键：`user_role_id`；字段数：9。

| 序号 | 字段 | 类型 | 可空 | 默认值 | 键 | 说明 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `user_role_id` | `bigint unsigned` | NO | - | PRI | 用户角色主键 |
| 2 | `user_id` | `bigint unsigned` | NO | - | MUL | 用户主键 |
| 3 | `role_id` | `bigint unsigned` | NO | - | MUL | 角色主键 |
| 4 | `assigned_by_user_id` | `bigint unsigned` | YES | - | MUL | 分配人 |
| 5 | `assigned_at` | `datetime` | NO | CURRENT_TIMESTAMP |  | 分配时间 |
| 6 | `effective_date` | `date` | YES | - |  | 生效日期 |
| 7 | `expiry_date` | `date` | YES | - |  | 失效日期 |
| 8 | `valid_flag` | `tinyint` | NO | 1 |  | 是否有效 |
| 9 | `remark` | `varchar(300)` | YES | - |  | 备注 |
