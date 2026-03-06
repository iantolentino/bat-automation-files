@echo off
echo Setting up Python environment...

IF NOT EXIST venv (
	echo Creating virtual environment...
	python -m venv venv
)

echo Activating venv...
call venv\Scripts\activate

echo Installing Dependencies...
pip install -r requirements.txt

echo Starting application
python app.py

pause