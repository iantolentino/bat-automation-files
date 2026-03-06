@echo off
title FastAPI Fullstack Project Generator

echo ================================
echo FASTAPI FULLSTACK GENERATOR
echo ================================
echo.

set /p project=Enter Project Name: 

echo.
echo Creating project folder...
mkdir %project%
cd %project%

echo Creating backend structure...

mkdir backend
mkdir backend\app
mkdir backend\app\api
mkdir backend\app\models
mkdir backend\app\schemas
mkdir backend\app\crud
mkdir backend\app\core
mkdir backend\app\db
mkdir backend\app\services

echo Creating frontend structure...

mkdir frontend
mkdir frontend\public
mkdir frontend\src
mkdir frontend\src\components
mkdir frontend\src\pages
mkdir frontend\src\services
mkdir frontend\src\assets

echo Creating shared folders...

mkdir docs
mkdir scripts

echo Creating Python virtual environment...

cd backend
python -m venv venv

echo Activating venv...
call venv\Scripts\activate

echo Installing backend dependencies...

pip install fastapi uvicorn sqlalchemy psycopg2-binary pymysql python-dotenv pydantic alembic

pip freeze > requirements.txt

echo Creating environment config...

echo DATABASE_URL=postgresql://postgres:password@localhost:5432/%project% > .env
echo MYSQL_URL=mysql+pymysql://root:@localhost:3306/%project% >> .env
echo SECRET_KEY=changeme >> .env

echo Creating main FastAPI app...

echo from fastapi import FastAPI > app\main.py
echo from app.api import routes >> app\main.py
echo. >> app\main.py
echo app = FastAPI(title="%project% API") >> app\main.py
echo. >> app\main.py
echo app.include_router(routes.router) >> app\main.py

echo Creating API router...

echo from fastapi import APIRouter > app\api\routes.py
echo. >> app\api\routes.py
echo router = APIRouter() >> app\api\routes.py
echo. >> app\api\routes.py
echo @router.get("/") >> app\api\routes.py
echo def root(): >> app\api\routes.py
echo     return {"message":"FastAPI Fullstack API Running"} >> app\api\routes.py

echo Creating database config...

echo import os > app\db\database.py
echo from sqlalchemy import create_engine >> app\db\database.py
echo from sqlalchemy.orm import sessionmaker >> app\db\database.py
echo from dotenv import load_dotenv >> app\db\database.py
echo. >> app\db\database.py
echo load_dotenv() >> app\db\database.py
echo DATABASE_URL = os.getenv("DATABASE_URL") >> app\db\database.py
echo. >> app\db\database.py
echo engine = create_engine(DATABASE_URL) >> app\db\database.py
echo SessionLocal = sessionmaker(bind=engine) >> app\db\database.py

echo Creating gitignore...

echo venv/ > ..\.gitignore
echo __pycache__/ >> ..\.gitignore
echo *.pyc >> ..\.gitignore
echo .env >> ..\.gitignore
echo node_modules/ >> ..\.gitignore

echo Creating frontend placeholder...

cd ..\frontend

echo ^<!DOCTYPE html^> > public\index.html
echo ^<html^> >> public\index.html
echo ^<head^> >> public\index.html
echo ^<title^>%project%^</title^> >> public\index.html
echo ^</head^> >> public\index.html
echo ^<body^> >> public\index.html
echo ^<h1^>FastAPI Fullstack App^</h1^> >> public\index.html
echo ^</body^> >> public\index.html
echo ^</html^> >> public\index.html

cd ..

echo Creating run script...

echo @echo off > run_backend.bat
echo cd backend >> run_backend.bat
echo call venv\Scripts\activate >> run_backend.bat
echo uvicorn app.main:app --reload >> run_backend.bat
echo pause >> run_backend.bat

echo.
echo ================================
echo PROJECT CREATED SUCCESSFULLY
echo ================================
echo.

echo Backend start command:
echo run_backend.bat

echo API Docs:
echo http://127.0.0.1:8000/docs

pause