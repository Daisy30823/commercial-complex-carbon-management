@echo off
setlocal
cd /d "%~dp0.."
call mvnw.cmd clean package
if errorlevel 1 exit /b %errorlevel%
echo WAR: target\commercial-complex-carbon.war
