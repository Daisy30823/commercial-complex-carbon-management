@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
echo [1/2] 使用 Maven Wrapper 执行 clean package...
call mvnw.cmd clean package
if errorlevel 1 (
  echo [失败] Maven 构建失败。
  exit /b 1
)
if not exist "target\commercial-complex-carbon.war" (
  echo [失败] 未找到 target\commercial-complex-carbon.war
  exit /b 1
)
echo [成功] target\commercial-complex-carbon.war 已生成。
endlocal
