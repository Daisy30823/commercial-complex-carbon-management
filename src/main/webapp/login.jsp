<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>商业综合体能耗与碳排放数智管理系统 · 登录</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/login.css?v=20260814b">
</head>
<body>
  <main class="login-page">
    <section class="login-card">
      <a class="back-link" href="${pageContext.request.contextPath}/">← 返回欢迎页</a>
      <img id="loginLogo" class="login-logo" src="${pageContext.request.contextPath}/assets/images/brand-logo.png?v=20260814" alt="商业综合体低碳管理标志">
      <div id="loginLogoFallback" class="login-logo-fallback">碳智管</div>
      <div class="login-heading">
        <span>系统登录</span>
        <h1>商业综合体能耗与碳排放<br>数智管理系统</h1>
        <p>请输入账号信息进入管理平台</p>
      </div>
      <form id="loginForm" novalidate>
        <label for="username">用户名</label>
        <input id="username" name="username" required autocomplete="username">
        <label for="password">密码</label>
        <div class="password-field">
          <input id="password" name="password" type="password" required autocomplete="current-password">
          <button id="togglePassword" type="button" aria-label="显示密码">显示</button>
        </div>
        <button id="loginButton" class="login-button" type="submit">登录系统</button>
        <div id="loginError" class="form-error" role="alert" aria-live="polite"></div>
      </form>
      <p class="auth-switch">还没有账号？<a href="${pageContext.request.contextPath}/register.jsp">注册只读账号</a></p>
    </section>
  </main>
  <script>
    const contextPath = '${pageContext.request.contextPath}';
    const form = document.getElementById('loginForm');
    const errorBox = document.getElementById('loginError');
    const loginButton = document.getElementById('loginButton');
    document.getElementById('loginLogo').addEventListener('error', event => {
      console.error('登录页品牌图片加载失败');
      event.currentTarget.hidden = true;
      document.getElementById('loginLogoFallback').style.display = 'grid';
    });
    document.getElementById('togglePassword').addEventListener('click', event => {
      const password = document.getElementById('password');
      const visible = password.type === 'text';
      password.type = visible ? 'password' : 'text';
      event.currentTarget.textContent = visible ? '显示' : '隐藏';
      event.currentTarget.setAttribute('aria-label', visible ? '显示密码' : '隐藏密码');
    });
    form.addEventListener('submit', async event => {
      event.preventDefault();
      errorBox.textContent = '';
      if (!form.reportValidity()) return;
      loginButton.disabled = true;
      loginButton.textContent = '正在登录…';
      try {
        const response = await fetch(contextPath + '/api/auth/login', {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(Object.fromEntries(new FormData(form)))});
        const result = await response.json();
        if (!result.success) throw new Error(result.message || '用户名或密码错误');
        location.href = contextPath + '/app.jsp#/dashboard';
      } catch (error) {
        errorBox.textContent = error.message || '登录失败，请检查网络连接';
      } finally {
        loginButton.disabled = false;
        loginButton.textContent = '登录系统';
      }
    });
  </script>
</body>
</html>
