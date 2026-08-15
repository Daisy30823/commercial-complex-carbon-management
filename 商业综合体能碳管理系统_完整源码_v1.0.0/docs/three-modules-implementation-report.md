# 三模块实现与验收报告

## 数据保护

修改前项目备份：`backup/three-modules-before-20260814-165815.zip`；数据库备份：`backup/commercial_complex_carbon_db_before_three_modules.sql`。未执行主 SQL、未 drop 数据库、未删除既有模拟记录。原始基线为：综合体 3、商户 11、入驻关系 10、设备 220、能耗 5502、碳核算 5502、预警 254、整改 250、日志 506。

## 新增对象

- `020_merchant_energy_bill.sql`：分摊规则、账单头、能源明细、版本和完整率字段。
- `021_merchant_bill_procedures.sql`：预览、生成、查询、确认、作废过程。
- `022_monthly_report.sql`：月度报告动态数据集过程。
- `023_data_quality.sql`：质量问题、复核和集中规则配置表。
- `024_data_quality_procedures.sql`：扫描、查询、复核、解决、误报及兼容别名过程。

## 实际结果

2026 年 7 月真实生成 10 个商户账单；重生成产生 v2 并将 v1 保留为历史版本。账单合计约 1,552,155.79 元、309.8547 tce、935,736.6575 kgCO₂e，与月报和原始能耗按折标煤计算一致。月报识别 14/31 天覆盖率 45.16%，未伪装完整月份。质量扫描真实产生异常标记、待审核、非法 JSON 三类问题，重复扫描保持指纹去重；浏览器中完成详情、复核、解决和创建预警。

`mvnw.cmd test`：22 项通过；`mvnw.cmd clean package`：BUILD SUCCESS；WAR：`target/commercial-complex-carbon.war`。Tomcat 10.1 已清理旧展开目录、work 缓存并重新部署，8080 可访问；浏览器登录后无 console error。

## 仍需注意

账单和碳报告均是课程设计模拟管理结果。当前历史主数据日期不覆盖完整自然月，因此确认按钮按规则禁用是预期行为；可在不删除原始数据的情况下补采后重新生成新版本。
