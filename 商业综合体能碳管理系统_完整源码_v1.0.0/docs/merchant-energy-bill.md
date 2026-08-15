# 商户能碳账单

该模块按综合体、商户和年月生成内部模拟管理账单。商户直计取 `meter_node.merchant_id` 非空的设备记录；公共能源池只取同一综合体中 `merchant_id is null` 且节点属于公共区域、公共设备或 root/building/area 节点的记录，两个集合不重叠。

## 口径

- 原始用量按电力 kWh、天然气 m3、自来水 t、柴油 L、外购热力 GJ 分能源类型展示，不直接相加。
- 账单总计只汇总费用、折标煤 tce 和碳排放 kgCO₂e/tCO₂e。
- `lease_area`、`contract_ratio`、`operating_days`、`manual` 四种规则均复用有效 `merchant_occupancy`。比例在同一综合体月度商户集合内归一化，最后一个商户吸收小数尾差。
- 账单含 `version_no`、`current_version_flag`、数据完整率和计算快照。重生成保留历史版本，查询默认只取当前版本。
- 数据完整率低于 95% 或账期存在未解决高风险质量问题时，`sp_confirm_merchant_energy_bill` 拒绝确认，只允许保留草稿。

## 操作

进入 `#/merchant-bills`，选择年月和分摊方法，先预览再生成；列表可以查看能源明细、打印、导出 CSV、确认或作废。页面底部明确声明账单不是法定收费或碳核证凭证。

## 数据库对象

`020_merchant_energy_bill.sql` 创建 `energy_allocation_rule`、`merchant_energy_bill`、`merchant_energy_bill_detail`；`021_merchant_bill_procedures.sql` 创建预览、生成、查询、确认、作废过程。所有过程由 Java `CallableStatement` 调用。
