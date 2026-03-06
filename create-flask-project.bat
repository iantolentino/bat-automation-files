@echo off
title Flask Project Generator

set /p project=Enter Flask project name: 

echo Creating project structure...
mkdir %project%
cd %project%

mkdir app
mkdir app\routes
mkdir app\models
mkdir app\templates
mkdir app\static

echo Creating virtual environment...
python -m venv venv

call venv\Scripts\activate

echo Installing dependencies...
pip install flask flask_sqlalchemy python-dotenv pymysql psycopg2-binary

echo Creating requirements.txt
pip freeze > requirements.txt

echo Creating starter files...

echo from flask import Flask > app\__init__.py
echo from .routes import main >> app\__init__.py
echo. >> app\__init__.py
echo def create_app(): >> app\__init__.py
echo     app = Flask(__name__) >> app\__init__.py
echo     app.config['SECRET_KEY'] = 'devkey' >> app\__init__.py
echo     main.init_app(app) >> app\__init__.py
echo     return app >> app\__init__.py

echo from flask import Blueprint > app\routes\main.py
echo main = Blueprint('main', __name__) >> app\routes\main.py
echo. >> app\routes\main.py
echo @main.route("/") >> app\routes\main.py
echo def home(): >> app\routes\main.py
echo     return {"message":"Flask API Running"} >> app\routes\main.py

echo from app import create_app > run.py
echo app = create_app() >> run.py
echo. >> run.py
echo if __name__ == "__main__": >> run.py
echo     app.run(debug=True) >> run.py

echo Creating database config...

echo # MySQL (XAMPP/WAMP) > .env
echo DATABASE_URL=mysql+pymysql://root:@localhost:3306/%project% >> .env
echo. >> .env
echo # PostgreSQL >> .env
echo POSTGRES_URL=postgresql://postgres:password@localhost:5432/%project% >> .env

echo.
echo Flask project created successfully!
echo Run with:
echo call venv\Scripts\activate
echo python run.py
pause