@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
echo ===== 商业综合体能耗与碳排放数智管理系统 =====
set "JAVA_EXE="
if defined JAVA_HOME set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
if not defined JAVA_EXE for /f "delims=" %%J in ('where java 2^>nul') do if not defined JAVA_EXE set "JAVA_EXE=%%J"
if not defined JAVA_EXE (
  echo [错误] 未找到 Java，请安装 Java 17 或设置 JAVA_HOME。
  exit /b 1
)
"%JAVA_EXE%" -version 2^>^&1 | findstr /C:"17.0" >nul
if errorlevel 1 (
  echo [错误] 当前 Java 不是 Java 17：
  "%JAVA_EXE%" -version
  exit /b 1
)
echo [通过] Java 17 检查。
sc query mysql80 | findstr /I "RUNNING" >nul
if errorlevel 1 (
  echo [提示] mysql80 未运行，尝试启动服务...
  net start mysql80 >nul 2>&1
  if errorlevel 1 (
    echo [错误] mysql80 服务未运行且无法自动启动。
    exit /b 1
  )
)
echo [通过] mysql80 服务正在运行。
if not exist "%~dp0src\main\resources\db.properties" (
  echo [错误] 缺少 src\main\resources\db.properties，请先按部署文档配置数据库。
  exit /b 1
)
echo [通过] 数据库配置文件存在。
echo [1/3] 构建 WAR...
call mvnw.cmd clean package
if errorlevel 1 (
  echo [失败] Maven 构建失败。
  exit /b 1
)
if not exist "%~dp0target\commercial-complex-carbon.war" (
  echo [错误] WAR 未生成。
  exit /b 1
)
set "TOMCAT_HOME="
set /p "TOMCAT_HOME=请输入 Tomcat 10.1 安装路径："
if "%TOMCAT_HOME%"=="" exit /b 1
if not exist "%TOMCAT_HOME%\bin\startup.bat" (
  echo [错误] 无效的 Tomcat 路径。
  exit /b 1
)
set "CATALINA_HOME=%TOMCAT_HOME%"
set "CATALINA_BASE=%TOMCAT_HOME%"
echo [2/3] 部署 WAR...
if exist "%TOMCAT_HOME%\webapps\commercial-complex-carbon" rmdir /s /q "%TOMCAT_HOME%\webapps\commercial-complex-carbon"
copy /Y "%~dp0target\commercial-complex-carbon.war" "%TOMCAT_HOME%\webapps\commercial-complex-carbon.war" >nul
if errorlevel 1 exit /b 1
echo [3/3] 启动 Tomcat...
call "%TOMCAT_HOME%\bin\startup.bat"
echo 等待网站启动...
set "APP_URL=http://localhost:8080/commercial-complex-carbon/"
for /L %%N in (1,1,30) do (
  powershell -NoProfile -Command "try { $r=Invoke-WebRequest -UseBasicParsing -Uri '%APP_URL%' -TimeoutSec 2; if($r.StatusCode -ge 200){exit 0}else{exit 1} } catch { exit 1 }" >nul 2>&1
  if not errorlevel 1 (
    echo [成功] 网站已启动：%APP_URL%
    start "" "%APP_URL%"
    endlocal
    exit /b 0
  )
  timeout /t 2 /nobreak >nul
)
echo [提示] Tomcat 已启动，但网站尚未在 60 秒内返回，请查看 logs\catalina.out。
start "" "%APP_URL%"
endlocal
