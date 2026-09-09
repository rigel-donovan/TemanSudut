@echo off
cd /d "%~dp0backend"
php artisan serve --host=0.0.0.0 --port=8000
