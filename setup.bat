@echo off
REM Quick Setup Script for Manufacturing Data Pipeline Project
REM Run this script to set up your local development environment

echo ========================================
echo Manufacturing Data Pipeline Setup
echo ========================================

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ and try again
    exit /b 1
)

echo ✓ Python found

REM Create virtual environment
echo Creating virtual environment...
python -m venv venv
if %errorlevel% neq 0 (
    echo ERROR: Failed to create virtual environment
    exit /b 1
)

echo ✓ Virtual environment created

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install required packages
echo Installing required Python packages...
pip install pandas numpy matplotlib seaborn great-expectations databricks-cli snowflake-connector-python boto3 awscli

if %errorlevel% neq 0 (
    echo ERROR: Failed to install packages
    exit /b 1
)

echo ✓ Python packages installed

REM Create local config directory
if not exist "config" mkdir config

REM Create sample environment file
echo Creating sample environment configuration...
(
echo # Manufacturing Data Pipeline Configuration
echo # Copy this file to .env and update with your actual values
echo.
echo # AWS Configuration
echo AWS_REGION=us-east-1
echo AWS_ACCOUNT_ID=123456789012
echo S3_BUCKET_PREFIX=manufacturing-data-pipeline
echo.
echo # Databricks Configuration
echo DATABRICKS_HOST=https://your-workspace.cloud.databricks.com
echo DATABRICKS_TOKEN=your-access-token
echo.
echo # Snowflake Configuration
echo SNOWFLAKE_ACCOUNT=your-account.snowflakecomputing.com
echo SNOWFLAKE_USER=your-username
echo SNOWFLAKE_PASSWORD=your-password
echo SNOWFLAKE_DATABASE=MANUFACTURING_DW
echo SNOWFLAKE_WAREHOUSE=COMPUTE_WH
) > config\environment.template

echo ✓ Environment template created

REM Generate sample data
echo Generating sample manufacturing data...
cd 08-sample-data
python data_generator.py
cd ..

if %errorlevel% neq 0 (
    echo WARNING: Sample data generation failed, but setup can continue
) else (
    echo ✓ Sample data generated
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Copy config\environment.template to config\.env
echo 2. Update .env with your actual credentials
echo 3. Review the PROJECT_SUMMARY.md for detailed instructions
echo 4. Follow the deployment guide in 10-deployment\deployment-guide.md
echo.
echo To activate the virtual environment in future sessions:
echo   venv\Scripts\activate.bat
echo.
echo To generate sample data again:
echo   cd 08-sample-data
echo   python data_generator.py
echo.
echo For detailed architecture information, see:
echo   01-architecture\architecture-overview.md
echo.
echo Happy data engineering! 🚀

pause
