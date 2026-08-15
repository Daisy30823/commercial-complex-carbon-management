# v1.0.0 最终发布报告

## 冻结版本

- 版本：`v1.0.0`。
- 技术栈：Java 17、Maven Wrapper、Tomcat 10.1、Jakarta Servlet、JSP、JDBC、MySQL 8、原生 JavaScript和 ECharts。
- 本轮未增加业务功能，未修改数据库表、字段、视图、过程、函数或触发器设计。

## 构建结果

- `mvnw.cmd test`：BUILD SUCCESS，46 项测试，0 失败、0 错误、0 跳过。
- `mvnw.cmd clean package`：BUILD SUCCESS，打包阶段 46 项测试再次通过。
- WAR：`target/commercial-complex-carbon.war`，13,133,446 字节。
- WAR SHA-256：`ECC313491814309BB1C8771C9B83F72E63668C237F9A1C7FA81544E839ADC061`。
- WAR 不包含实际 `db.properties`，仅包含 `db.properties.example`。

## 数据库发布结果

- 完整演示 SQL 已从当前正式结构和示例数据生成。
- 私人/无意义测试账号已从发布副本移除，正式数据库未删除任何用户或业务数据。
- 从零安装到 `commercial_complex_carbon_release_test` 成功。
- 数据库验证、应用登录、Dashboard、专题查询、存储过程 CRUD 和能耗触发碳核算均通过。
- 临时测试数据库已删除，正式系统已恢复且 HTTP 200。

## 设计与验收材料

- E-R 图由 29 张表及实际外键元数据生成并完成图片检查。
- 关系模式和完整数据表结构由 MySQL `information_schema` 生成。
- “实体及含义表.docx”通过 ZIP/OOXML、段落数、表格行数和文件完整性检查；LibreOffice 未安装，Microsoft Word 后台导出因本机首次启动状态超时，未完成像素级逐页渲染，该限制不影响 DOCX 打开和内容结构。
- 19 张系统截图已通过真实 Session 登录逐页生成；浏览器控制台错误列表为空。

## 数据保护

未重新执行主 SQL到正式数据库，未 drop、清空或重建正式数据库。正式核心数据复核为设备 462、能耗 48,702、碳核算 48,702、预警 838、整改任务 530。

## 未完成项

仅 DOCX 的 LibreOffice/Word 像素级渲染 QA 受本机 Office 环境阻塞；已完成结构性验证。核心系统、数据库发布、Maven 构建、部署和提交包内容不存在未完成项。

## 提交包验证

- 课程提交包、完整源码包和部署包均已生成。
- 三个 ZIP 均可由标准 ZIP 读取器打开并完整解压。
- 课程提交包包含 19 张真实系统截图、最终 E-R 图、实体 DOCX、关系模式、数据库结构、部署说明和测试结果。
- 完整源码包不包含 `target`、WAR、真实 `db.properties`、备份、日志或 IDE 缓存。
- 部署包包含无密码 WAR、完整演示数据库、配置示例、一键数据库初始化和 Tomcat 启停脚本。
- 发布包未上传 GitHub，未进行公网部署。
