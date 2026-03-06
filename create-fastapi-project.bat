@echo off
title FastAPI Project Generator

set /p project=Enter FastAPI project name:

mkdir %project%
cd %project%

mkdir app
mkdir app\routes
mkdir app\models
mkdir app\database

python -m venv venv
call venv\Scripts\activate

pip install fastapi uvicorn sqlalchemy python-dotenv pymysql psycopg2-binary

pip freeze > requirements.txt

echo from fastapi import FastAPI > app\main.py
echo app = FastAPI() >> app\main.py
echo. >> app\main.py
echo @app.get("/") >> app\main.py
echo def root(): >> app\main.py
echo     return {"message":"FastAPI running"} >> app\main.py

echo from sqlalchemy import create_engine > app\database\db.py
echo from sqlalchemy.orm import sessionmaker >> app\database\db.py
echo import os >> app\database\db.py
echo from dotenv import load_dotenv >> app\database\db.py
echo. >> app\database\db.py
echo load_dotenv() >> app\database\db.py
echo DATABASE_URL = os.getenv("DATABASE_URL") >> app\database\db.py
echo engine = create_engine(DATABASE_URL) >> app\database\db.py
echo SessionLocal = sessionmaker(bind=engine) >> app\database\db.py

echo # MySQL > .env
echo DATABASE_URL=mysql+pymysql://root:@localhost:3306/%project% >> .env
echo. >> .env
echo # PostgreSQL >> .env
echo POSTGRES_URL=postgresql://postgres:password@localhost:5432/%project% >> .env

echo.
echo FastAPI project ready!
echo Run server with:
echo uvicorn app.main:app --reload
pause