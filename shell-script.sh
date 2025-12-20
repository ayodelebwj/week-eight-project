#!/bin/bash
set -e

###############################################
# CONFIGURATION
###############################################
DB_NAME="mydb"
DB_USER="myuser"
DB_PASS="mypassword"
APP_DIR="$HOME/fruits-veg_market/backend-api"
PYTHON_VERSION="python3"

###############################################
# UPDATE SYSTEM
###############################################
echo "Updating system..."
sudo apt update -y
sudo apt upgrade -y

###############################################
# INSTALL POSTGRESQL
###############################################
echo "Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

echo "Starting PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

###############################################
# CREATE DATABASE + USER
###############################################
echo "Creating PostgreSQL user and database..."

sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}'
   ) THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
   END IF;
END
\$do\$;

CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

echo "Database and user created."

###############################################
# SETUP PYTHON ENVIRONMENT
###############################################
echo "Installing Python venv..."
sudo apt install -y python3-venv

echo "Creating virtual environment..."
cd "$APP_DIR"
$PYTHON_VERSION -m venv venv

echo "Activating virtual environment..."
source venv/bin/activate

###############################################
# INSTALL PYTHON DEPENDENCIES
###############################################
echo "Installing FastAPI, SQLAlchemy, psycopg2-binary, Uvicorn..."
pip install --upgrade pip
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv

###############################################
# CREATE .env FILE FOR DATABASE URL
###############################################
echo "Creating .env file..."
cat <<EOF > "$APP_DIR/.env"
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}
EOF

###############################################
# RUN FASTAPI SERVER
###############################################
echo "Starting FastAPI server..."
uvicorn main:app --host 0.0.0.0 --port 8000