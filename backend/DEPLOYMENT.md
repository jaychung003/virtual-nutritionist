# Backend Deployment Guide

## Environment Variables

Set the following environment variables in your Render Web Service:

```bash
# Anthropic API
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Database (auto-set by Render PostgreSQL)
DATABASE_URL=postgresql://user:pass@host:5432/db

# JWT Configuration
JWT_SECRET_KEY=generate_with_openssl_rand_hex_32
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

# Environment
ENVIRONMENT=production
```

## Generate JWT Secret Key

Run this command locally to generate a secure secret key:

```bash
openssl rand -hex 32
```

Copy the output and set it as `JWT_SECRET_KEY` in Render.

## Database Setup

### 1. Create PostgreSQL Database

In Render:
1. Go to "New +" → "PostgreSQL"
2. Choose free tier
3. Create database
4. Note the connection details

### 2. Link Database to Web Service

In your Web Service settings:
1. Go to "Environment" tab
2. The `DATABASE_URL` should be automatically set
3. If not, manually add it from the PostgreSQL dashboard

### 3. Run Database Migrations

After deploying, run migrations via Render shell:

```bash
# SSH into your Render instance
cd /opt/render/project/src/backend
alembic upgrade head
```

Or run locally against production database:

```bash
# Set DATABASE_URL to production database
export DATABASE_URL="postgresql://user:pass@host:5432/db"
alembic upgrade head
```

## Testing Deployment

### 1. Health Check

```bash
curl https://your-app.onrender.com/
```

Expected response:
```json
{"status": "healthy", "service": "IBD Menu Scanner API"}
```

### 2. Register User

```bash
curl -X POST https://your-app.onrender.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234"}'
```

### 3. Login

```bash
curl -X POST https://your-app.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234"}'
```

Save the `access_token` from the response.

### 4. Test Protected Endpoint

```bash
curl -X GET https://your-app.onrender.com/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Local Development

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Setup Local Database

Option A: Use PostgreSQL locally
```bash
# Install PostgreSQL
brew install postgresql

# Create database
createdb virtual_nutritionist

# Set DATABASE_URL
export DATABASE_URL="postgresql://localhost/virtual_nutritionist"
```

Option B: Use SQLite for development (requires code modification)
```python
# In db/base.py, change engine creation to:
engine = create_engine("sqlite:///./virtual_nutritionist.db")
```

### 3. Run Migrations

```bash
alembic upgrade head
```

### 4. Create .env File

```bash
ANTHROPIC_API_KEY=your_key_here
DATABASE_URL=postgresql://localhost/virtual_nutritionist
JWT_SECRET_KEY=development-secret-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30
```

### 5. Run Development Server

```bash
cd backend
uvicorn main:app --reload --port 8000
```

## Troubleshooting

### Database Connection Errors

If you see "could not connect to server":
1. Verify `DATABASE_URL` is set correctly
2. Check PostgreSQL is running (Render) or locally
3. Verify firewall rules allow connection

### Migration Errors

If migrations fail:
1. Check database exists and is accessible
2. Verify Alembic configuration in `alembic.ini`
3. Run `alembic current` to see current migration state
4. Run `alembic history` to see all migrations

### JWT Token Errors

If authentication fails:
1. Verify `JWT_SECRET_KEY` is set and matches across requests
2. Check token hasn't expired (60 min for access tokens)
3. Verify token format is correct (Bearer scheme)

## Security Notes

- **NEVER** commit `.env` file or expose `JWT_SECRET_KEY`
- Use strong passwords (min 8 chars, letter + digit)
- Set `JWT_SECRET_KEY` to a cryptographically secure random value in production
- Enable HTTPS (automatic on Render)
- Regularly rotate JWT secret key
- Monitor rate limits to prevent abuse
