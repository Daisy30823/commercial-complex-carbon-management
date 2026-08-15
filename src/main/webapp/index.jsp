<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%
  boolean authenticated = session.getAttribute("user") != null;
  String target = request.getContextPath() + (authenticated ? "/app.jsp#/dashboard" : "/login.jsp");
%>
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>商业综合体能耗与碳排放数智管理系统</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/landing.css?v=20260814">
</head>
<body>
  <main class="landing-page">
    <section class="landing-content">
      <div class="brand-lockup">
        <img id="brandLogo" src="${pageContext.request.contextPath}/assets/images/brand-logo.png?v=20260814" alt="商业综合体低碳管理标志">
        <span id="brandFallback">碳智管</span>
      </div>
      <p class="landing-eyebrow">COMMERCIAL COMPLEX · CARBON INTELLIGENCE</p>
      <h1>商业综合体能耗与碳排放<br>数智管理系统</h1>
      <h2>全景看能 · 深入析碳 · 高效管碳</h2>
      <p class="landing-description">汇聚能耗监测、碳核算、碳预算、预警整改与节能项目评价，<br>助力商业综合体低碳运营。</p>
      <a class="enter-button" href="<%= target %>">立即进入 <span aria-hidden="true">→</span></a>
    </section>
  </main>
  <script>
    document.getElementById('brandLogo').addEventListener('error', event => {
      console.error('欢迎页品牌图片加载失败');
      event.currentTarget.hidden = true;
      document.getElementById('brandFallback').style.display = 'inline-flex';
    });
  </script>
</body>
</html>
