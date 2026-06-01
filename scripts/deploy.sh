#!/bin/bash

set -e

APP_DIR="/home/ubuntu/devops-2tier-cicd"
REPO_URL="https://github.com/praneshkA/devops-2tier-cicd.git"
SERVICE_NAME="employee-app"

echo "Starting deployment..."

if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
    echo "ERROR: Database environment variables are missing."
    echo "Required: DB_HOST, DB_USER, DB_PASSWORD, DB_NAME"
    exit 1
fi

echo "Updating system packages..."
sudo apt update -y

echo "Installing required packages..."
sudo apt install -y python3-pip python3-venv git default-mysql-client nginx

echo "Cloning or updating repository..."
if [ -d "$APP_DIR/.git" ]; then
    cd "$APP_DIR"
    git fetch origin main
    git reset --hard origin/main
else
    rm -rf "$APP_DIR"
    git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR/app"

echo "Creating Python virtual environment..."
python3 -m venv venv

echo "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "Initializing database table if not exists..."
mysql -h "$DB_HOST" -P 3306 -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" <<SQL
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    department VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SQL

echo "Creating systemd service..."

sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Employee Management Flask App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR/app

Environment="DB_HOST=$DB_HOST"
Environment="DB_USER=$DB_USER"
Environment="DB_PASSWORD=$DB_PASSWORD"
Environment="DB_NAME=$DB_NAME"

ExecStart=$APP_DIR/app/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 app:app

Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Configuring Nginx reverse proxy..."

sudo tee /etc/nginx/sites-available/employee-app > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/employee-app /etc/nginx/sites-enabled/employee-app
sudo rm -f /etc/nginx/sites-enabled/default

echo "Testing Nginx configuration..."
sudo nginx -t

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Restarting application service..."
sudo systemctl restart $SERVICE_NAME
sudo systemctl enable $SERVICE_NAME

echo "Restarting Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "Checking application service..."
sudo systemctl status $SERVICE_NAME --no-pager

echo "Running local health check..."
curl -f http://127.0.0.1:5000 > /dev/null

echo "Deployment completed successfully."