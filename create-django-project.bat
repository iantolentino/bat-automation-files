@echo off
title Django Project Generator

set /p project=Enter Django project name:

mkdir %project%
cd %project%

python -m venv venv
call venv\Scripts\activate

pip install django psycopg2-binary mysqlclient python-dotenv

pip freeze > requirements.txt

django-admin startproject config .

python manage.py startapp core

mkdir core\templates
mkdir core\static

echo Creating .env file...

echo # MySQL XAMPP/WAMP > .env
echo DB_ENGINE=mysql >> .env
echo DB_NAME=%project% >> .env
echo DB_USER=root >> .env
echo DB_PASSWORD= >> .env
echo DB_HOST=localhost >> .env
echo DB_PORT=3306 >> .env
echo. >> .env
echo # PostgreSQL >> .env
echo PG_NAME=%project% >> .env
echo PG_USER=postgres >> .env
echo PG_PASSWORD=password >> .env
echo PG_HOST=localhost >> .env
echo PG_PORT=5432 >> .env

echo.
echo Django project created!
echo Run server with:
echo python manage.py runserver
pause