@echo off
chcp 65001 >nul
setlocal EnableExtensions
cd /d "%~dp0"
set "WAR=%~dp0target\commercial-complex-carbon.war"
if not exist "%WAR%" (
  echo [错误] 未找到 WAR，请先运行“一键构建.bat”。
  exit /b 1
)
set "TOMCAT_HOME="
set /p "TOMCAT_HOME=请输入 Tomcat 10.1 安装路径："
if "%TOMCAT_HOME%"=="" (
  echo [错误] Tomcat 路径不能为空。
  exit /b 1
)
if not exist "%TOMCAT_HOME%\bin\startup.bat" (
  echo [错误] 路径不是有效的 Tomcat：%TOMCAT_HOME%
  exit /b 1
)
if not exist "%TOMCAT_HOME%\webapps" mkdir "%TOMCAT_HOME%\webapps"
if exist "%TOMCAT_HOME%\webapps\commercial-complex-carbon" (
  echo [提示] 删除旧的展开目录...
  rmdir /s /q "%TOMCAT_HOME%\webapps\commercial-complex-carbon"
)
copy /Y "%WAR%" "%TOMCAT_HOME%\webapps\commercial-complex-carbon.war" >nul
if errorlevel 1 (
  echo [失败] WAR 复制失败。
  exit /b 1
)
echo [成功] 已部署到 "%TOMCAT_HOME%\webapps"。
echo [提示] 本脚本不会修改或重建 MySQL 数据库。
endlocal
