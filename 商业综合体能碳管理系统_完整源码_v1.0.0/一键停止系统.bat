@echo off
chcp 65001 >nul
setlocal
set "TOMCAT_HOME="
set /p "TOMCAT_HOME=请输入 Tomcat 10.1 安装路径："
if "%TOMCAT_HOME%"=="" exit /b 1
if not exist "%TOMCAT_HOME%\bin\shutdown.bat" (
  echo [错误] 无效的 Tomcat 路径。
  exit /b 1
)
set "CATALINA_HOME=%TOMCAT_HOME%"
set "CATALINA_BASE=%TOMCAT_HOME%"
call "%TOMCAT_HOME%\bin\shutdown.bat"
echo [成功] 已请求停止 Tomcat；mysql80 服务和数据库保持运行。
endlocal
