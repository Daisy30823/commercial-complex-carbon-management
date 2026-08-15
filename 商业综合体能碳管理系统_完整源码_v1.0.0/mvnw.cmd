@echo off
chcp 65001 >nul
setlocal
set "MAVEN_OPTS=%MAVEN_OPTS% -Dfile.encoding=UTF-8"
set "MAVEN_PROJECTBASEDIR=%~dp0."
if not defined JAVA_HOME (
  for /f "delims=" %%J in ('where java 2^>nul') do if not defined JAVA_EXE set "JAVA_EXE=%%J"
  if not defined JAVA_EXE if exist "C:\Program Files\Amazon Corretto\jdk17.0.20_8\bin\java.exe" set "JAVA_EXE=C:\Program Files\Amazon Corretto\jdk17.0.20_8\bin\java.exe"
  if not defined JAVA_EXE if exist "C:\Program Files\Java\jdk-17\bin\java.exe" set "JAVA_EXE=C:\Program Files\Java\jdk-17\bin\java.exe"
) else (
  set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
)
if not defined JAVA_EXE (
  echo [错误] 未找到 Java。请安装 Java 17，或设置 JAVA_HOME。
  exit /b 1
)
if not exist "%JAVA_EXE%" (
  echo [错误] Java 路径不存在：%JAVA_EXE%
  exit /b 1
)
"%JAVA_EXE%" -version 2>&1 | findstr /C:"17.0" >nul
if errorlevel 1 (
  echo [错误] Maven Wrapper 需要 Java 17，当前 Java 版本不满足要求。
  "%JAVA_EXE%" -version
  exit /b 1
)
set "WRAPPER_JAR=%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.jar"
if not exist "%WRAPPER_JAR%" (
  echo [错误] 缺少 %WRAPPER_JAR%
  exit /b 1
)
"%JAVA_EXE%" -Dmaven.multiModuleProjectDirectory="%MAVEN_PROJECTBASEDIR%" -classpath "%WRAPPER_JAR%" org.apache.maven.wrapper.MavenWrapperMain %*
exit /b %ERRORLEVEL%
