# 课程提交包敏感信息扫描报告

## 扫描范围

对课程提交包、完整源码包和部署包的最终暂存目录进行文本、文件名和 WAR 内容检查。检查项包括真实 `db.password`、令牌、API Key、Secret、Private Key、本机项目路径、用户目录、Tomcat/MySQL 绝对路径、私人测试账号、备份、日志、编译缓存和 IDE 缓存。

## 已处理内容

- `src/main/resources/db.properties` 不进入任何提交 ZIP。
- Maven WAR 明确排除 `WEB-INF/classes/db.properties`，仅保留 `db.properties.example`。
- 示例密码统一为 `your_mysql_password`。
- 发布数据库移除 3 个后期私人/测试注册账号及其关联角色、登录日志，不修改正式数据库。
- 暂存副本中的 `<项目目录>`、`<Tomcat目录>` 替换真实本机绝对路径。
- `target`、`backup`、`backups`、`logs`、`runtime-logs`、`.idea`、`.vscode`、临时 SQL 和 QA 渲染文件不进入源码包。
- 数据库备份和冻结前项目 ZIP 只保留在本机 `backup` 目录。

## 允许项

- `db.password=your_mysql_password` 是明确占位配置，不是实际密码。
- 源码中的 `password`、`token`、`secret` 等词仅作为认证字段或安全检查关键字存在，不代表凭据。
- 发布演示数据中的客服电话、商户联系信息和邮箱均为课程示例数据，不是私人联系方式。

## 最终结论

2026-08-15 最终暂存目录扫描通过：实际 MySQL 密码精确值命中 0，本机项目路径命中 0，`<用户目录>\` 用户目录命中 0，本机 Tomcat 路径命中 0，3 个私人/测试账号名称命中 0；禁止配置文件和禁止目录均为 0。

三个 ZIP 均已使用 .NET ZIP 读取器打开并解压到独立校验目录；未发现空包、乱码替换字符、嵌套 ZIP、`db.properties`、备份、日志、IDE 缓存或编译目录。最终校验值记录在 `dist/SHA256SUMS.txt`。
