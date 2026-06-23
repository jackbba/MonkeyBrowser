@echo off
REM MonkeyBrowser GitHub Actions 构建助手
REM 在 Windows 上触发远程构建并下载 IPA

echo ==========================================
echo   MonkeyBrowser IPA Builder (GitHub Actions)
echo ==========================================
echo.

REM 检查 gh CLI
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] 未找到 GitHub CLI
    echo.
    echo 请安装 GitHub CLI:
    echo https://cli.github.com/
    echo.
    echo 或者手动操作:
    echo 1. 访问 https://github.com/YOUR_USERNAME/MonkeyBrowser/actions
    echo 2. 点击 "Build IPA"
    echo 3. 等待构建完成
    echo 4. 下载 Artifact 中的 IPA
    echo.
    pause
    exit /b 1
)

echo [1/3] 登录 GitHub...
gh auth status
if %errorlevel% neq 0 (
    gh auth login
)

echo.
echo [2/3] 触发构建...
gh workflow run build.yml

echo.
echo [3/3] 等待构建完成...
echo (这可能需要几分钟时间)
echo.

:check_status
timeout /t 30 /nobreak >nul
gh run list --workflow=build.yml --limit=1
set STATUS=%errorlevel%

if %STATUS%==0 (
    echo.
    echo ==========================================
    echo   构建完成!
    echo ==========================================
    echo.
    echo 下载 IPA:
    echo gh run download --name MonkeyBrowser
    echo.
    echo 或访问: https://github.com/YOUR_USERNAME/MonkeyBrowser/actions
    echo.
    pause
) else (
    echo 构建中... 再次检查中
    goto check_status
)
