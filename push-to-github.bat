@echo off
REM ============================================================
REM  Pushes this folder to github.com/gururajseethur/security-automation-platform
REM  Just double-click this file. Git will ask you to sign in to
REM  GitHub in your browser the first time - that is normal.
REM ============================================================
cd /d "%~dp0"

where git >nul 2>nul
if errorlevel 1 (
  echo Git is not installed. Get it from https://git-scm.com/download/win then run this again.
  pause
  exit /b 1
)

if not exist .git (
  git init
  git branch -M main
  git remote add origin https://github.com/gururajseethur/security-automation-platform.git
  git fetch origin main
  git reset --soft origin/main
)

git add -A
git -c user.name="Gururaj Seethuru" -c user.email="gururajseethureducation@gmail.com" commit -m "Add platform source: API, workflows, deployment and CI"
git push origin main

echo.
echo Done. Open https://github.com/gururajseethur/security-automation-platform to check.
pause
