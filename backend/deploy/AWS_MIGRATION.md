# Migrating DietWatch Backend from Render to AWS EC2

## Prerequisites

- AWS account (free tier eligible)
- Your API keys: `ANTHROPIC_API_KEY`, `GOOGLE_PLACES_API_KEY`
- (Optional) Access to your Render PostgreSQL database for data export

## Step 1: Launch an EC2 Instance

1. Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2/)
2. Click **Launch Instance**
3. Configure:
   - **Name**: `dietwatch-backend`
   - **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance type**: `t2.micro` (Free tier eligible)
   - **Key pair**: Create a new key pair or select existing one. Download the `.pem` file.
   - **Network settings**: Create a new security group with these rules:
     - SSH (port 22) — your IP only
     - HTTP (port 80) — anywhere (0.0.0.0/0)
     - Custom TCP (port 8000) — anywhere (0.0.0.0/0)
   - **Storage**: 20 GB gp3 (free tier allows up to 30 GB)
4. Click **Launch Instance**
5. Note the **Public IPv4 address** from the instance details

## Step 2: Connect via SSH

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

## Step 3: Run the Setup Script

```bash
# Clone the repo (or copy the script manually)
git clone https://github.com/jaychung003/virtual-nutritionist.git
cd virtual-nutritionist/backend/deploy

# Run the setup script
bash ec2_setup.sh
```

The script will prompt you for:
- PostgreSQL database name and credentials
- Anthropic API key
- Google Places API key
- JWT secret key (auto-generates if blank)

The script installs everything: Python 3.11, PostgreSQL 15, nginx, creates the database, runs migrations, and starts the service.

## Step 4: Verify the API

```bash
# From the EC2 instance
curl http://localhost/

# From your local machine
curl http://<EC2_PUBLIC_IP>/
# Expected: {"status":"healthy","service":"IBD Menu Scanner API"}

curl http://<EC2_PUBLIC_IP>/protocols
# Expected: list of dietary protocols
```

## Step 5: Export Data from Render (Optional)

If you have existing user data on Render that you want to keep:

### On your local machine (or any machine with psql):

```bash
# Get your Render DATABASE_URL from the Render dashboard
# Format: postgresql://user:password@host:port/dbname

# Export data
pg_dump "YOUR_RENDER_DATABASE_URL" --data-only --no-owner --no-acl > render_data.sql

# Copy to EC2
scp -i your-key.pem render_data.sql ubuntu@<EC2_PUBLIC_IP>:/tmp/
```

### On the EC2 instance:

```bash
# Import data (the schema was already created by Alembic migrations)
psql postgresql://dietwatch:<YOUR_DB_PASSWORD>@localhost:5432/dietwatch < /tmp/render_data.sql

# Clean up
rm /tmp/render_data.sql
```

## Step 6: Update the iOS App

In Xcode, update the base URL in both files:

**`Services/APIService.swift`** (line 9):
```swift
private let baseURL = "http://<EC2_PUBLIC_IP>"
```

**`Services/AuthService.swift`** (line 36):
```swift
private let baseURL = "http://<EC2_PUBLIC_IP>"
```

Since we're using HTTP (no SSL), you need to allow insecure connections in Info.plist. Add this under the top-level `<dict>`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

Then build and run the app to test.

## Step 7: Test Everything

1. Health check: `curl http://<EC2_PUBLIC_IP>/`
2. Protocols: `curl http://<EC2_PUBLIC_IP>/protocols`
3. iOS app: Register a new account, log in, scan a menu, check bookmarks

## Useful Commands

```bash
# Check service status
sudo systemctl status dietwatch

# Restart the service
sudo systemctl restart dietwatch

# View live logs
sudo journalctl -u dietwatch -f

# Check nginx status
sudo systemctl status nginx

# Restart nginx
sudo systemctl restart nginx

# Check PostgreSQL status
sudo systemctl status postgresql

# Connect to the database
psql postgresql://dietwatch:<password>@localhost:5432/dietwatch

# Pull latest code and restart
cd /home/ubuntu/virtual-nutritionist && git pull
cd backend && source venv/bin/activate && pip install -r requirements.txt
alembic upgrade head
sudo systemctl restart dietwatch
```

## Troubleshooting

**Service won't start:**
```bash
sudo journalctl -u dietwatch -n 50 --no-pager
```

**502 Bad Gateway from nginx:**
- The FastAPI app isn't running. Check `sudo systemctl status dietwatch`.

**Database connection error:**
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check the DATABASE_URL in `/home/ubuntu/virtual-nutritionist/backend/.env`

**iOS app can't connect:**
- Verify the EC2 security group allows inbound traffic on port 80
- Verify you're using `http://` (not `https://`) in the base URL
- Check that `NSAllowsArbitraryLoads` is set in Info.plist
