# 数据库设计摘要

核心链路为 `commercial_complex → building → functional_area → merchant_occupancy → merchant`，计量链路为 `meter_node(parent_node_id) → meter_device → energy_consumption_record`，触发器依据 `emission_factor` 写入 `carbon_accounting_record`，再由 `carbon_budget/carbon_budget_detail`、`alert_event/corrective_task` 和 `energy_saving_project/project_evaluation` 支撑管理闭环。

`meter_node` 使用自关联外键形成综合体—建筑—区域—商户的多级树。`operation_log.request_params/response_body`、`alert_event.source_snapshot`、`energy_consumption_record.raw_payload` 和项目附件字段使用 MySQL JSON。月度区域能碳、预算执行、商户月度碳排放通过视图提供查询基础。
