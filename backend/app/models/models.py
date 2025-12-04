"""
SQLAlchemy database models for the BLE Scale system.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Enum
from sqlalchemy.orm import relationship, declarative_base
import enum

Base = declarative_base()


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    OPERATOR = "operator"
    VIEWER = "viewer"


class WeightUnit(str, enum.Enum):
    GRAMS = "g"
    KILOGRAMS = "kg"
    POUNDS = "lb"
    OUNCES = "oz"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))
    role = Column(Enum(UserRole), default=UserRole.OPERATOR)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    devices = relationship("Device", back_populates="owner")
    transactions = relationship("Transaction", back_populates="created_by")


class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    mac_address = Column(String(17), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    firmware_version = Column(String(20))
    calibration_factor = Column(Float, default=420.0)
    last_seen = Column(DateTime)
    is_active = Column(Boolean, default=True)
    owner_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    owner = relationship("User", back_populates="devices")
    measurements = relationship("Measurement", back_populates="device")
    calibrations = relationship("Calibration", back_populates="device")


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    sku = Column(String(50), unique=True, index=True)
    price_per_unit = Column(Float, nullable=False)
    unit = Column(Enum(WeightUnit), default=WeightUnit.KILOGRAMS)
    category = Column(String(50))
    icon = Column(String(10))  # Emoji or icon code
    color = Column(String(7))  # Hex color
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    transaction_items = relationship("TransactionItem", back_populates="product")


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    transaction_number = Column(String(20), unique=True, index=True, nullable=False)
    total_amount = Column(Float, nullable=False)
    payment_method = Column(String(20))
    notes = Column(String(500))
    created_by_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    created_by = relationship("User", back_populates="transactions")
    items = relationship("TransactionItem", back_populates="transaction")


class TransactionItem(Base):
    __tablename__ = "transaction_items"

    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(Integer, ForeignKey("transactions.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    weight = Column(Float, nullable=False)  # in grams
    unit_price = Column(Float, nullable=False)
    total_price = Column(Float, nullable=False)

    # Relationships
    transaction = relationship("Transaction", back_populates="items")
    product = relationship("Product", back_populates="transaction_items")


class Measurement(Base):
    __tablename__ = "measurements"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(Integer, ForeignKey("devices.id"), nullable=False)
    weight = Column(Float, nullable=False)
    unit = Column(Enum(WeightUnit), default=WeightUnit.GRAMS)
    is_stable = Column(Boolean, default=False)
    battery_level = Column(Integer)
    timestamp = Column(DateTime, default=datetime.utcnow)

    # Relationships
    device = relationship("Device", back_populates="measurements")


class Calibration(Base):
    __tablename__ = "calibrations"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(Integer, ForeignKey("devices.id"), nullable=False)
    known_weight = Column(Float, nullable=False)
    raw_value = Column(Float, nullable=False)
    calibration_factor = Column(Float, nullable=False)
    performed_by = Column(String(100))
    timestamp = Column(DateTime, default=datetime.utcnow)

    # Relationships
    device = relationship("Device", back_populates="calibrations")
