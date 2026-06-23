@echo off
chcp 65001 >nul
echo ==========================================
echo   MonkeyBrowser 一键部署脚本
echo ==========================================
echo.

REM 检查 Git
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] 未找到 Git，请先安装:
    echo     https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

REM 检查 GitHub CLI
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [*] 安装 GitHub CLI...
    winget install GitHub.cli
)

echo.
echo [1/5] 登录 GitHub...
gh auth status >nul 2>nul
if %errorlevel% neq 0 (
    gh auth login
)

echo.
echo [2/5] 初始化 Git 仓库...
cd /d "%~dp0"
if not exist ".git" (
    git init
    git add .
    git commit -m "Initial commit: MonkeyBrowser"
) else (
    git add .
    git commit -m "Update: %date%" 2>nul
)

echo.
echo [3/5] 请输入你的 GitHub 仓库 URL:
echo      (如果还没有，先去 https://github.com/new 创建)
echo.
set /p REPO_URL="仓库URL: "

if "%REPO_URL%"=="" (
    echo [!] URL不能为空
    pause
    exit /b 1
)

git remote remove origin 2>nul
git remote add origin %REPO_URL%
git push -u origin main

echo.
echo [4/5] 触发自动构建...
gh workflow run build.yml

echo.
echo [5/5] 等待构建完成（约5-10分钟）...
echo.

:check
timeout /t 15 /nobreak >nul
for /f "tokens=*" %%i in ('gh run list --workflow=build.yml --limit=1 --json status -q ".[0].status"') do set STATUS=%%i

if "%STATUS%"=="completed" (
    echo.
    echo ==========================================
    echo   构建完成!
    echo ==========================================
    echo.
    echo 正在下载 IPA...
    gh run download --name MonkeyBrowser
    echo.
    echo IPA 已保存到当前目录!
    dir *.ipa
    echo.
    pause
) else (
    echo 构建中... %STATUS%
    goto check
)
