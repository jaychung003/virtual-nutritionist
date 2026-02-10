"""SQLAlchemy database models."""
from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey, Text, ARRAY
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from .base import Base


class User(Base):
    """User account model."""
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    preferences = relationship("UserPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")
    scan_history = relationship("ScanHistory", back_populates="user", cascade="all, delete-orphan")
    bookmarks = relationship("Bookmark", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User {self.email}>"


class UserPreference(Base):
    """User dietary preferences model."""
    __tablename__ = "user_preferences"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    selected_protocols = Column(ARRAY(Text), nullable=False, default=list)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="preferences")

    def __repr__(self):
        return f"<UserPreference user_id={self.user_id}, protocols={self.selected_protocols}>"


class ScanHistory(Base):
    """Scan history model for storing menu analysis results."""
    __tablename__ = "scan_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    protocols_used = Column(ARRAY(Text), nullable=False)
    menu_items = Column(JSONB, nullable=False)  # Stores array of menu items with analysis
    restaurant_name = Column(String(255), nullable=True)  # Optional restaurant name
    image_data = Column(Text, nullable=True)  # Base64 encoded image of the scanned menu
    scanned_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)

    # Relationships
    user = relationship("User", back_populates="scan_history")

    def __repr__(self):
        return f"<ScanHistory id={self.id}, user_id={self.user_id}, scanned_at={self.scanned_at}>"


class Bookmark(Base):
    """Bookmark model for saving favorite menu items."""
    __tablename__ = "bookmarks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    menu_item_name = Column(String(500), nullable=False)
    safety_rating = Column(String(50), nullable=False)  # "safe", "caution", "avoid"
    triggers = Column(ARRAY(Text), nullable=False, default=list)
    notes = Column(Text, nullable=True)  # User's personal notes
    restaurant_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)

    # Relationships
    user = relationship("User", back_populates="bookmarks")

    def __repr__(self):
        return f"<Bookmark id={self.id}, item={self.menu_item_name}, rating={self.safety_rating}>"


class RefreshToken(Base):
    """Refresh token model for JWT token refresh mechanism."""
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String(255), nullable=False, unique=True, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    is_revoked = Column(Boolean, default=False, nullable=False)

    # Relationships
    user = relationship("User", back_populates="refresh_tokens")

    def __repr__(self):
        return f"<RefreshToken id={self.id}, user_id={self.user_id}, expires_at={self.expires_at}>"


class Restaurant(Base):
    """Restaurant model - canonical reference from Google Places."""
    __tablename__ = "restaurants"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Google Places identity
    google_place_id = Column(String(255), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False, index=True)

    # Location
    address = Column(String(500), nullable=True)
    city = Column(String(100), nullable=True, index=True)
    state = Column(String(50), nullable=True, index=True)
    country = Column(String(50), default="US")
    latitude = Column(String(50), nullable=True)  # Store as string for precision
    longitude = Column(String(50), nullable=True)

    # Metadata
    cuisine_type = Column(String(100), nullable=True)
    price_level = Column(String(10), nullable=True)  # Store as string: "$", "$$", etc.
    phone = Column(String(50), nullable=True)
    website = Column(String(500), nullable=True)

    # Menu tracking
    menu_last_scanned = Column(DateTime(timezone=True), nullable=True)
    total_scans = Column(String(10), default="0")  # Store as string to avoid int issues

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    menu_items = relationship("RestaurantMenuItem", back_populates="restaurant", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Restaurant {self.name} ({self.google_place_id})>"


class RestaurantMenuItem(Base):
    """Menu items at a specific restaurant."""
    __tablename__ = "restaurant_menu_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    restaurant_id = Column(UUID(as_uuid=True), ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False, index=True)

    # Item details
    name = Column(String(500), nullable=False)
    description = Column(Text, nullable=True)
    price = Column(String(50), nullable=True)
    category = Column(String(100), nullable=True)

    # Scan metadata
    first_seen = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    last_seen = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    times_seen = Column(String(10), default="1")  # Store as string

    # Status
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    restaurant = relationship("Restaurant", back_populates="menu_items")

    def __repr__(self):
        return f"<RestaurantMenuItem {self.name} at restaurant_id={self.restaurant_id}>"
