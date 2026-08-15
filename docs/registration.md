# 用户注册与只读权限

## 功能入口

- 页面：`/register.jsp`
- 接口：`post /api/auth/register`
- 登录页提供“注册只读账号”入口。

## 注册字段与校验

| 字段 | 规则 |
| --- | --- |
| `username` | 4-30 位字母、数字或下划线；忽略大小写检查重复 |
| `realName` | 必填，最长 60 字符 |
| `phone` | 可选，最长 30 字符 |
| `email` | 可选，必须符合邮箱格式；忽略大小写检查重复 |
| `password` | 必填，不少于 8 位 |
| `confirmPassword` | 必须与密码一致 |

密码使用项目既有 `org.mindrot.jbcrypt.BCrypt` 生成 BCrypt 哈希，不保存或记录明文。用户、角色关系和注册日志在同一数据库事务中写入，任一步失败均回滚。

## 默认角色

执行 `database/patches/050_registration_default_role.sql` 创建幂等角色：

- 角色编码：`registered_user`
- 中文名称：注册用户
- 权限：只读业务数据，可编辑自己的资料和密码

后端根据 Session 中的角色编码阻止注册用户执行业务 `post`、`put`、`delete`。前端同步隐藏新增、编辑、停用和业务处理按钮。现有管理员及业务角色逻辑保持不变。

## 请求示例

```json
{
  "username": "demo_reader",
  "realName": "课程访客",
  "phone": "",
  "email": "demo_reader@example.local",
  "password": "示例密码不少于8位",
  "confirmPassword": "示例密码不少于8位"
}
```

成功后返回用户 ID、用户名和 `registered_user` 角色编码，不自动建立登录 Session。
