@echo off
setlocal
cd /d "%~dp0.."
if "%TOMCAT_HOME%"=="" (echo 请设置 TOMCAT_HOME && exit /b 1)
set WAR=%~1
if "%WAR%"=="" set WAR=target\commercial-complex-carbon.war
if exist "%TOMCAT_HOME%\webapps\commercial-complex-carbon" rmdir /s /q "%TOMCAT_HOME%\webapps\commercial-complex-carbon"
copy /Y "%WAR%" "%TOMCAT_HOME%\webapps\commercial-complex-carbon.war"
echo 已部署到 %TOMCAT_HOME%\webapps
