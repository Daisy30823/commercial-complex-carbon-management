# Railway 云部署指南

本文档只执行代码准备后的控制台操作。不要把真实数据库密码、管理员密码或 `.env` 提交到 GitHub。

## 1. 上传 GitHub

1. 登录 GitHub，点击右上角 `+`，选择 `New repository`。
2. 填写仓库名，选择 `Public`，不要勾选自动创建 README、LICENSE 或 `.gitignore`。
3. 在本项目实际源码根目录初始化 Git 并上传。应上传包含 `pom.xml`、`Dockerfile`、`railway.toml`、`src`、`database` 的这一层，不要上传其外层同名目录。
4. 上传前确认 `git status` 中没有 `.env`、`db.properties`、WAR、ZIP、dump、日志、Tomcat 或 MySQL 数据目录。

## 2. 创建 Railway 项目与 MySQL

1. 登录 Railway，点击 `New Project`。
2. 选择 `Deploy MySQL`，等待 MySQL 服务就绪。
3. 打开 MySQL 服务的 `Settings` / `Networking`，确认没有启用 Public Networking 或 TCP Proxy。Web 服务通过 Railway 私有网络访问 MySQL。
4. 不需要在 Railway Data 页面手工粘贴 36 MB SQL；Web 服务首次启动会安全执行一次初始化。

## 3. 创建 Web Service

1. 在同一 Railway 项目画布点击 `New`，选择 `GitHub Repo`。
2. 授权 Railway 访问刚创建的仓库并选择该仓库。
3. Railway 将读取根目录的 `railway.toml`，按 `Dockerfile` 构建 Tomcat 镜像。
4. 打开 Web 服务的 `Variables`，添加下列变量引用。若 MySQL 服务名不是 `MySQL`，把引用中的服务名改为实际名称。

```text
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_NAME=${{MySQL.MYSQLDATABASE}}
DB_USER=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
ADMIN_USERNAME=<自行设置，不提交仓库>
ADMIN_INITIAL_PASSWORD=<自行生成的至少 12 位强密码，不提交仓库>
SESSION_COOKIE_SECURE=true
TZ=Asia/Shanghai
```

也可以将五个 `DB_*` 键替换为同名的 `MYSQLHOST`、`MYSQLPORT`、`MYSQLDATABASE`、`MYSQLUSER`、`MYSQLPASSWORD` 引用。不要设置公网数据库地址。

## 4. 首次初始化过程

容器启动后，`scripts/railway-db-init.sh` 会执行以下保护流程：

1. 等待私网 MySQL 可连接，最长 300 秒。
2. 创建 `schema_migration_history`。
3. 若 `cloud-baseline-v1.0.0` 已成功，立即跳过数据库导入。
4. 若数据库已有业务对象但没有成功迁移记录，拒绝初始化，防止覆盖数据。
5. 仅对空数据库导入 `database/cloud/railway_init.sql`。
6. 使用容器内 Java 与 BCrypt 12 轮散列 `ADMIN_INITIAL_PASSWORD`，激活 `ADMIN_USERNAME` 对应的管理员，并分配 `admin` 角色。
7. 写入成功迁移记录，再启动 Tomcat。

发布包中的其他预置业务账号均处于停用状态且没有可用密码。后续注册账号只获得 `registered_user` 普通只读角色。

如果首次导入中断，迁移记录会保持未成功状态，后续启动将停止而不会清空或覆盖数据库。此时查看 MySQL 和 Web 服务日志；对于尚未投入使用的首次部署，可删除失败的 MySQL 服务并重新创建一个空 MySQL 服务后再部署。

## 5. 健康检查与公网域名

1. Web 服务部署日志出现数据库初始化成功和 Tomcat 启动信息后，打开 `Settings`。
2. `railway.toml` 已配置健康检查 `/api/health`、300 秒启动超时和失败自动重启。
3. 打开 `Settings` / `Networking` / `Public Networking`，点击 `Generate Domain`。
4. Railway 生成的 `*.up.railway.app` 域名即 Web 公网入口。只要不删除服务、域名或项目，该域名用于后续部署，不依赖本地电脑。
5. 访问 `https://<生成域名>/api/health`，预期数据库正常时返回：

```json
{
  "success": true,
  "data": {
    "application": "commercial-complex-carbon",
    "database": "up"
  }
}
```

随后访问根路径 `/`，用环境变量中设置的管理员账号登录，并测试注册一个普通账号。出于安全原因，文档和页面不会显示管理员密码。

## 6. 后续部署与密码处理

- GitHub 推送触发 Web 服务重新构建时，初始化脚本会看到成功迁移记录并跳过 SQL，不会重置管理员、注册用户或业务数据。
- 首次成功后可从 Web 服务变量中删除 `ADMIN_INITIAL_PASSWORD`；后续启动在确认成功迁移后不会再读取或重置管理员密码。
- 如需更改管理员密码，请登录系统后在个人中心修改，不能通过重新部署重置。
- 数据库备份应使用 Railway 提供的备份能力或受控导出，并存放在私有位置，不提交 GitHub。

## 7. 故障排查

- `Missing required environment variable`：检查 Web 服务变量及跨服务引用名称。
- `Existing database objects found`：连接的不是空数据库，脚本为防止覆盖而停止。
- `previous initialization is incomplete`：首次导入中断，查看此前错误日志，不要手工将迁移标记改为成功。
- 健康检查失败：检查 MySQL 服务状态、私网变量引用和 Web 服务日志。
- 本地 HTTP 无法保持登录：仅本地设置 `SESSION_COOKIE_SECURE=false`；Railway 必须保持 `true`。
