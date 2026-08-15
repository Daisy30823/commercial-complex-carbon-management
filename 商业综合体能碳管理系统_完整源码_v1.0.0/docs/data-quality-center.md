# 数据质量与异常复核中心

入口为 `#/data-quality`。`data_quality_rule_config` 集中保存规则名称、阈值和严重等级；扫描过程覆盖 `missing_record`、`duplicate_period`、`negative_consumption`、`end_less_than_start`、`sudden_increase`、`continuous_zero`、`device_offline`、`invalid_json`、`pending_audit`、`expired_emission_factor`、`abnormal_flag`。

问题通过规则码和 SHA-256 指纹去重，重复扫描不会新增相同问题；复核、解决、误报和创建预警均写入 `data_quality_review`，数据库字段保留发现和解决时间。创建预警时在 `source_snapshot` 写入问题编号，并检查同一问题是否已有未关闭预警。

详情页可查看原始报文、期初/期末读数、碳排放和复核轨迹。修正动作要求填写原因，在同一事务中保存 before/after 快照、更新能耗记录、写操作日志，并依赖现有数据库触发器同步碳核算；不物理删除原记录。

扫描和写操作由后端按角色限制：系统管理员、能源管理员可扫描/修正；碳核算员、审核员可处理账单和复核。页面状态为待处理、复核中、已解决、误报，所有用户可看到中文规则和明确空状态。
