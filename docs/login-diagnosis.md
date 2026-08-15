# 登录诊断记录

本次诊断直接读取现有 `commercial_complex_carbon_db.app_user` 中的 `admin` 记录，没有重跑主 SQL、删除数据库或删除模拟数据。

- `pom.xml` 使用 `org.mindrot:jbcrypt:0.4`；登录代码使用同一库的 `org.mindrot.jbcrypt.BCrypt.checkpw`。
- 当前数据库原哈希长度为 60、前缀为 `$2a$`，但与当时的本机私密凭据不匹配，因此此前 400 的真实原因是凭据与哈希不一致，不是请求格式或 session 问题。
- 使用项目当前 jBCrypt 0.4 的 `BCrypt.gensalt(10)` 和 `BCrypt.hashpw` 生成新的 `$2a$` 哈希，并回验 `checkpw` 为 `true`。
- 当时仅更新管理员记录的 `password_hash`、`user_status=1`、`failed_login_count=0`、`locked_until=null`；公开仓库中的旧密码种子现已弃用。
- 前端使用 `POST api/auth/login`、`Content-Type: application/json`、字段 `username/password`；后端 Jackson 从 JSON 读取同名字段，前后端一致。
- 修复后真实登录返回 200，session `/api/auth/me` 返回 admin，`/api/complexes` 返回数据库记录。
