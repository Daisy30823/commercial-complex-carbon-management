@echo off
chcp 65001 >nul
setlocal EnableExtensions
cd /d "%~dp0"

echo ===== 系统检查与安全修复 =====
where java >nul 2>&1 || (echo [失败] 未找到 Java，请安装 Java 17 并设置 JAVA_HOME。 & exit /b 1)
java -version 2>&1 | findstr /C:"17." >nul || (echo [失败] 当前 Java 不是 Java 17。 & exit /b 1)
sc query mysql80 | findstr /I "RUNNING" >nul || (echo [失败] mysql80 服务未运行。 & exit /b 1)
if not exist "src\main\resources\db.properties" (
  echo [失败] 缺少 src\main\resources\db.properties。
  echo 请复制 db.properties.example 后填写本机数据库连接。
  exit /b 1
)
call mvnw.cmd test || exit /b 1
call mvnw.cmd clean package || exit /b 1
if not exist "target\commercial-complex-carbon.war" (echo [失败] WAR 未生成。 & exit /b 1)
echo [通过] Java、MySQL、数据库配置、测试和 WAR 构建均正常。
echo [说明] 本脚本不会重建、清空或删除数据库。
endlocal
