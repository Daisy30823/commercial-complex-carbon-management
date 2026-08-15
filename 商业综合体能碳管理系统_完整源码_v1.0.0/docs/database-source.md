# 数据库事实来源

本项目唯一数据库事实来源是根目录的 `2025333541001戴哲语.sql`。该脚本包含 23 张 InnoDB 表、3 个视图、3 个函数、27 个存储过程、8 个触发器以及设备、能耗、预警和日志模拟数据生成过程。

原始脚本保持不变。登录演示密码修复放在 `database/patches/auth_seed.sql`；课程验收统计脚本为 `database/verify_requirements.sql`。PowerShell 终端显示的中文注释可能因本机代码页出现乱码，导入 MySQL 时请使用 UTF-8（`mysql --default-character-set=utf8mb4`）。
