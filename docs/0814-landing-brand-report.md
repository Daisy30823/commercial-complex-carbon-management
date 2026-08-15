# 欢迎入口与品牌素材美化报告

## 素材

- 原始素材：`<项目目录>\图片\logo.png`、`<项目目录>\图片\背景图.png`。
- 原图保留不动，复制为 `src/main/webapp/assets/images/brand-logo.png` 和 `src/main/webapp/assets/images/landing-background.png`。
- 两组复制文件 SHA-256 与原文件一致，未压缩、裁剪或重绘。

## 页面改动

- 新增 `src/main/webapp/index.jsp` 和 `assets/css/landing.css`。
- 根地址现在进入全屏欢迎页；已登录 Session 点击“立即进入”直接进入 Dashboard，未登录进入 `login.jsp`。
- `web.xml` welcome-file 改为 `index.jsp`；现有认证过滤器仍只保护 API 和 `app.jsp`，欢迎页及静态资源可公开访问。
- `login.jsp` 改为居中登录卡片，复用 Logo；增加动态 Context Path、版本参数、错误提示、密码显示和响应式布局。

## 真实验收

- 根地址 HTTP 200，背景图和 Logo 均实际加载，图片无 404，桌面/窄屏无横向溢出。
- “立即进入”未登录跳转登录页；使用本机私密管理员凭据登录后进入 `app.jsp#/dashboard`。
- 已登录 Session 从根地址点击“立即进入”直接进入 Dashboard。
- 退出登录后返回登录页。
- 1366×768、1920×1080、768px 窄屏均已检查。
- 本机 Chrome 以 `--incognito --headless=new` 模式额外验证根地址和登录页实际渲染，截图分别为 `landing-page-chrome-incognito.png`、`login-page-chrome-incognito.png`。
- Maven test/package 均 BUILD SUCCESS，Tomcat 已重新部署并保持运行。

## 截图

- `docs/screenshots/landing-page.png`
- `docs/screenshots/login-page-with-logo.png`
- `docs/screenshots/landing-page-chrome-incognito.png`
- `docs/screenshots/login-page-chrome-incognito.png`
