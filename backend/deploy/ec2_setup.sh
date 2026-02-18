#!/bin/bash
# =============================================================================
# EC2 Setup Script for Virtual Nutritionist (DietWatch) Backend
# Run this on a fresh Ubuntu 22.04 EC2 instance
# Usage: bash ec2_setup.sh
# =============================================================================

set -e

echo "========================================="
echo "  DietWatch EC2 Setup"
echo "========================================="

# --- Collect configuration ---
read -p "PostgreSQL database name [dietwatch]: " DB_NAME
DB_NAME=${DB_NAME:-dietwatch}

read -p "PostgreSQL username [dietwatch]: " DB_USER
DB_USER=${DB_USER:-dietwatch}

read -sp "PostgreSQL password: " DB_PASS
echo
if [ -z "$DB_PASS" ]; then
    echo "Error: PostgreSQL password is required."
    exit 1
fi

read -p "Anthropic API key: " ANTHROPIC_API_KEY
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: Anthropic API key is required."
    exit 1
fi

read -p "Google Places API key: " GOOGLE_PLACES_API_KEY
if [ -z "$GOOGLE_PLACES_API_KEY" ]; then
    echo "Error: Google Places API key is required."
    exit 1
fi

read -p "JWT Secret Key (leave blank to auto-generate): " JWT_SECRET_KEY
if [ -z "$JWT_SECRET_KEY" ]; then
    JWT_SECRET_KEY=$(openssl rand -hex 32)
    echo "Generated JWT secret: $JWT_SECRET_KEY"
fi

read -p "GitHub repo URL [https://github.com/jaychung003/virtual-nutritionist.git]: " REPO_URL
REPO_URL=${REPO_URL:-https://github.com/jaychung003/virtual-nutritionist.git}

APP_DIR="/home/ubuntu/virtual-nutritionist"

echo ""
echo "========================================="
echo "  1/7  Installing system packages"
echo "========================================="

sudo apt update && sudo apt upgrade -y

# Python 3.11
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# PostgreSQL 15
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-15

# Nginx and other tools
sudo apt install -y nginx git curl

echo ""
echo "========================================="
echo "  2/7  Setting up PostgreSQL"
echo "========================================="

sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" 2>/dev/null || \
    sudo -u postgres psql -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" 2>/dev/null || \
    echo "Database ${DB_NAME} already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

echo ""
echo "========================================="
echo "  3/7  Cloning repository"
echo "========================================="

if [ -d "$APP_DIR" ]; then
    echo "Directory exists, pulling latest..."
    cd "$APP_DIR" && git pull
else
    git clone "$REPO_URL" "$APP_DIR"
fi

echo ""
echo "========================================="
echo "  4/7  Setting up Python environment"
echo "========================================="

cd "$APP_DIR/backend"

python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "========================================="
echo "  5/7  Creating .env file"
echo "========================================="

cat > "$APP_DIR/backend/.env" << EOF
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
GOOGLE_PLACES_API_KEY=${GOOGLE_PLACES_API_KEY}
JWT_SECRET_KEY=${JWT_SECRET_KEY}
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
ENVIRONMENT=production
EOF

chmod 600 "$APP_DIR/backend/.env"

echo ""
echo "========================================="
echo "  6/7  Running database migrations"
echo "========================================="

cd "$APP_DIR/backend"
source venv/bin/activate
alembic upgrade head

echo ""
echo "========================================="
echo "  7/7  Setting up systemd & nginx"
echo "========================================="

# Install systemd service
sudo cp "$APP_DIR/backend/deploy/dietwatch.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable dietwatch
sudo systemctl start dietwatch

# Install nginx config
sudo cp "$APP_DIR/backend/deploy/nginx.conf" /etc/nginx/sites-available/dietwatch
sudo ln -sf /etc/nginx/sites-available/dietwatch /etc/nginx/sites-enabled/dietwatch
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

# Open firewall ports (if ufw is active)
if sudo ufw status | grep -q "active"; then
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 8000/tcp
fi

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Service status:"
sudo systemctl status dietwatch --no-pager
echo ""
echo "Test the API:"
echo "  curl http://localhost/"
echo "  curl http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '<EC2_PUBLIC_IP>')/"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status dietwatch   - Check service status"
echo "  sudo systemctl restart dietwatch   - Restart the app"
echo "  sudo journalctl -u dietwatch -f    - View live logs"
