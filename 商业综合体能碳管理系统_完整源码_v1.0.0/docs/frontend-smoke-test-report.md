# 前端冒烟测试报告

脚本：`scripts/frontend-smoke-test.ps1`。脚本使用 PowerShell 会话保持 Cookie，调用真实登录接口、模块入口和关键 API，不依赖 Node/npm。

执行命令：

```powershell
.\scripts\frontend-smoke-test.ps1
```

2026-08-14 已通过浏览器使用本机私密管理员凭据实际登录，首页自动显示综合体、统计日期、KPI 和图表；Hash 路由刷新、个人中心、专题查询和多综合体计量树已回归验证。完整脚本可在本机 Tomcat 启动后重复执行。

实际输出：登录 `true`；dashboard、complexes、buildings、areas、merchants、meters、devices、energy、carbon、budget、alerts、tasks、projects、queries、logs、profile 共 16 个入口均 HTTP 200；关键 API 均 `success=true`；错误列表为空。
