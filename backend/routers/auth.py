"""Authentication endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, validator
from datetime import datetime, timedelta
from typing import Optional
import hashlib
import re

from db.session import get_db
from db.models import User, UserPreference, RefreshToken
from auth.password import hash_password, verify_password
from auth.jwt import create_access_token, create_refresh_token, verify_token

router = APIRouter(prefix="/auth", tags=["Authentication"])


# Request/Response Models
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str

    @validator("password")
    def validate_password(cls, v):
        """Validate password meets security requirements."""
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        if not re.search(r"[A-Za-z]", v):
            raise ValueError("Password must contain at least one letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain at least one digit")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: dict


class MessageResponse(BaseModel):
    message: str


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, db: Session = Depends(get_db)):
    """
    Register a new user account.

    - **email**: Valid email address (unique)
    - **password**: At least 8 characters, contains letter and digit

    Returns access token, refresh token, and user info.
    """
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == request.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create new user
    hashed_password = hash_password(request.password)
    new_user = User(
        email=request.email,
        password_hash=hashed_password,
        is_active=True
    )
    db.add(new_user)
    db.flush()  # Flush to get user ID

    # Create default preferences (empty protocols list)
    preferences = UserPreference(
        user_id=new_user.id,
        selected_protocols=[]
    )
    db.add(preferences)

    # Generate tokens
    access_token = create_access_token(data={"sub": str(new_user.id)})
    refresh_token = create_refresh_token(data={"sub": str(new_user.id)})

    # Store refresh token hash in database
    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
    refresh_token_record = RefreshToken(
        user_id=new_user.id,
        token_hash=token_hash,
        expires_at=datetime.utcnow() + timedelta(days=30)
    )
    db.add(refresh_token_record)

    db.commit()
    db.refresh(new_user)

    return AuthResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user={
            "id": str(new_user.id),
            "email": new_user.email,
            "created_at": new_user.created_at.isoformat()
        }
    )


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Login with email and password.

    - **email**: Registered email address
    - **password**: Account password

    Returns access token, refresh token, and user info.
    """
    # Find user by email
    user = db.query(User).filter(User.email == request.email).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    # Verify password
    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    # Generate tokens
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    # Store refresh token hash in database
    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
    refresh_token_record = RefreshToken(
        user_id=user.id,
        token_hash=token_hash,
        expires_at=datetime.utcnow() + timedelta(days=30)
    )
    db.add(refresh_token_record)
    db.commit()

    return AuthResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user={
            "id": str(user.id),
            "email": user.email,
            "created_at": user.created_at.isoformat()
        }
    )


@router.post("/refresh", response_model=AuthResponse)
async def refresh(request: RefreshRequest, db: Session = Depends(get_db)):
    """
    Exchange refresh token for new access token.

    - **refresh_token**: Valid refresh token

    Returns new access token, refresh token, and user info.
    """
    # Verify refresh token
    payload = verify_token(request.refresh_token, token_type="refresh")
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )

    # Check if refresh token exists and is not revoked
    token_hash = hashlib.sha256(request.refresh_token.encode()).hexdigest()
    token_record = db.query(RefreshToken).filter(
        RefreshToken.token_hash == token_hash,
        RefreshToken.is_revoked == False,
        RefreshToken.expires_at > datetime.utcnow()
    ).first()

    if not token_record:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or revoked refresh token"
        )

    # Get user
    user = db.query(User).filter(User.id == token_record.user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )

    # Generate new tokens
    new_access_token = create_access_token(data={"sub": str(user.id)})
    new_refresh_token = create_refresh_token(data={"sub": str(user.id)})

    # Revoke old refresh token
    token_record.is_revoked = True

    # Store new refresh token
    new_token_hash = hashlib.sha256(new_refresh_token.encode()).hexdigest()
    new_token_record = RefreshToken(
        user_id=user.id,
        token_hash=new_token_hash,
        expires_at=datetime.utcnow() + timedelta(days=30)
    )
    db.add(new_token_record)
    db.commit()

    return AuthResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        user={
            "id": str(user.id),
            "email": user.email,
            "created_at": user.created_at.isoformat()
        }
    )


@router.post("/logout", response_model=MessageResponse)
async def logout(request: RefreshRequest, db: Session = Depends(get_db)):
    """
    Logout by revoking refresh token.

    - **refresh_token**: Refresh token to revoke
    """
    # Hash the token to find it in database
    token_hash = hashlib.sha256(request.refresh_token.encode()).hexdigest()

    # Find and revoke the token
    token_record = db.query(RefreshToken).filter(
        RefreshToken.token_hash == token_hash,
        RefreshToken.is_revoked == False
    ).first()

    if token_record:
        token_record.is_revoked = True
        db.commit()

    # Return success even if token not found (already logged out)
    return MessageResponse(message="Successfully logged out")
