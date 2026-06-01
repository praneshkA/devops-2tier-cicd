#!/bin/bash

set -e

APP_DIR="/home/ubuntu/devops-2tier-cicd"
REPO_URL="https://github.com/praneshkA/devops-2tier-cicd.git"
SERVICE_NAME="employee-app"

echo "Starting deployment..."

echo "Updating system packages..."
sudo apt update -y

echo "Installing required packages..."
sudo apt install -y python3-pip python3-venv git

echo "Cloning or updating repository..."
if [ -d "$APP_DIR" ]; then
    cd "$APP_DIR"
    git pull origin main
else
    git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR/app"

echo "Creating Python virtual environment..."
python3 -m venv venv

echo "Activating virtual environment and installing dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

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

ExecStart=$APP_DIR/app/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 app:app

Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Restarting application service..."
sudo systemctl restart $SERVICE_NAME

echo "Enabling application service..."
sudo systemctl enable $SERVICE_NAME

echo "Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager

echo "Deployment completed successfully."