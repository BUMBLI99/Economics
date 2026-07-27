@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0render_exchange_site.ps1" %*
