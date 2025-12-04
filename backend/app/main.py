"""
FastAPI main application entry point.
"""
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
import os

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# App instance
app = FastAPI(
    title="BLE Scale API",
    description="Backend API for ESP32 BLE Weight Measurement System",
    version="1.0.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =============================================================================
# Pydantic Schemas
# =============================================================================

class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


class UserCreate(BaseModel):
    email: str
    password: str
    full_name: Optional[str] = None


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    role: str
    is_active: bool

    class Config:
        from_attributes = True


class ProductCreate(BaseModel):
    name: str
    sku: Optional[str] = None
    price_per_unit: float
    unit: str = "kg"
    category: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None


class ProductResponse(BaseModel):
    id: int
    name: str
    sku: Optional[str]
    price_per_unit: float
    unit: str
    category: Optional[str]
    icon: Optional[str]
    color: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


class DeviceCreate(BaseModel):
    mac_address: str
    name: str
    firmware_version: Optional[str] = None


class DeviceResponse(BaseModel):
    id: int
    mac_address: str
    name: str
    firmware_version: Optional[str]
    calibration_factor: float
    last_seen: Optional[datetime]
    is_active: bool

    class Config:
        from_attributes = True


class TransactionItemCreate(BaseModel):
    product_id: int
    weight: float
    unit_price: float
    total_price: float


class TransactionCreate(BaseModel):
    items: List[TransactionItemCreate]
    payment_method: Optional[str] = "cash"
    notes: Optional[str] = None


class TransactionResponse(BaseModel):
    id: int
    transaction_number: str
    total_amount: float
    payment_method: Optional[str]
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class MeasurementCreate(BaseModel):
    device_mac: str
    weight: float
    unit: str = "g"
    is_stable: bool = False
    battery_level: Optional[int] = None


# =============================================================================
# Authentication Helpers
# =============================================================================

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# =============================================================================
# API Routes
# =============================================================================

@app.get("/")
async def root():
    return {"message": "BLE Scale API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}


# Auth routes
@app.post("/auth/register", response_model=UserResponse)
async def register(user: UserCreate):
    """Register a new user."""
    # In production, this would use the database
    hashed = get_password_hash(user.password)
    return {
        "id": 1,
        "email": user.email,
        "full_name": user.full_name,
        "role": "operator",
        "is_active": True,
    }


@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Login and get access token."""
    # In production, validate against database
    access_token = create_access_token(
        data={"sub": form_data.username},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}


# Product routes
@app.get("/products", response_model=List[ProductResponse])
async def get_products():
    """Get all products."""
    # Mock data for demo
    return [
        {"id": 1, "name": "Apples", "sku": "APL001", "price_per_unit": 3.50, "unit": "kg", "category": "Fruits", "icon": "🍎", "color": "#FF6B6B", "is_active": True},
        {"id": 2, "name": "Oranges", "sku": "ORG001", "price_per_unit": 4.00, "unit": "kg", "category": "Fruits", "icon": "🍊", "color": "#FFB74D", "is_active": True},
        {"id": 3, "name": "Bananas", "sku": "BAN001", "price_per_unit": 2.80, "unit": "kg", "category": "Fruits", "icon": "🍌", "color": "#FFEB3B", "is_active": True},
    ]


@app.post("/products", response_model=ProductResponse)
async def create_product(product: ProductCreate):
    """Create a new product."""
    return {
        "id": 4,
        **product.model_dump(),
        "is_active": True,
    }


# Device routes
@app.get("/devices", response_model=List[DeviceResponse])
async def get_devices():
    """Get all registered devices."""
    return []


@app.post("/devices", response_model=DeviceResponse)
async def register_device(device: DeviceCreate):
    """Register a new device."""
    return {
        "id": 1,
        **device.model_dump(),
        "calibration_factor": 420.0,
        "last_seen": datetime.utcnow(),
        "is_active": True,
    }


# Transaction routes
@app.get("/transactions", response_model=List[TransactionResponse])
async def get_transactions(skip: int = 0, limit: int = 50):
    """Get transaction history."""
    return []


@app.post("/transactions", response_model=TransactionResponse)
async def create_transaction(transaction: TransactionCreate):
    """Create a new transaction."""
    total = sum(item.total_price for item in transaction.items)
    tx_number = f"TX{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
    
    return {
        "id": 1,
        "transaction_number": tx_number,
        "total_amount": total,
        "payment_method": transaction.payment_method,
        "notes": transaction.notes,
        "created_at": datetime.utcnow(),
    }


# Measurement routes
@app.post("/measurements")
async def record_measurement(measurement: MeasurementCreate):
    """Record a weight measurement from device."""
    return {
        "status": "recorded",
        "device": measurement.device_mac,
        "weight": measurement.weight,
        "timestamp": datetime.utcnow().isoformat(),
    }


# =============================================================================
# Ownership Transfer API
# =============================================================================

# In-memory store for transfer tokens (use Redis in production)
transfer_tokens: dict = {}


class TransferInitRequest(BaseModel):
    device_mac: str
    owner_id: int


class TransferInitResponse(BaseModel):
    transfer_code: str
    expires_at: datetime
    device_mac: str


class TransferVerifyRequest(BaseModel):
    transfer_code: str
    new_owner_id: int
    device_mac: str


class TransferCompleteResponse(BaseModel):
    success: bool
    device_mac: str
    previous_owner_id: int
    new_owner_id: int
    transferred_at: datetime


class TransferLogResponse(BaseModel):
    id: int
    device_mac: str
    from_owner_id: int
    to_owner_id: int
    transferred_at: datetime


@app.post("/transfers/initiate", response_model=TransferInitResponse)
async def initiate_transfer(request: TransferInitRequest):
    """
    Initiate a device ownership transfer.
    Generates a 6-digit transfer code valid for 5 minutes.
    """
    import secrets
    
    # Generate 6-digit code
    code = ''.join([str(secrets.randbelow(10)) for _ in range(6)])
    expires_at = datetime.utcnow() + timedelta(minutes=5)
    
    # Store in memory (use Redis in production)
    transfer_tokens[code] = {
        "device_mac": request.device_mac,
        "owner_id": request.owner_id,
        "expires_at": expires_at,
        "used": False,
    }
    
    return {
        "transfer_code": code,
        "expires_at": expires_at,
        "device_mac": request.device_mac,
    }


@app.post("/transfers/verify", response_model=TransferCompleteResponse)
async def verify_transfer(request: TransferVerifyRequest):
    """
    Verify transfer code and complete ownership transfer.
    """
    token_data = transfer_tokens.get(request.transfer_code)
    
    if not token_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid transfer code"
        )
    
    if token_data["used"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transfer code already used"
        )
    
    if datetime.utcnow() > token_data["expires_at"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transfer code expired"
        )
    
    if token_data["device_mac"] != request.device_mac:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Device MAC mismatch"
        )
    
    if token_data["owner_id"] == request.new_owner_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot transfer to yourself"
        )
    
    # Mark token as used
    token_data["used"] = True
    previous_owner = token_data["owner_id"]
    
    # In production: Update database, transfer device ownership
    # UPDATE devices SET owner_id = new_owner WHERE mac_address = device_mac
    
    return {
        "success": True,
        "device_mac": request.device_mac,
        "previous_owner_id": previous_owner,
        "new_owner_id": request.new_owner_id,
        "transferred_at": datetime.utcnow(),
    }


@app.delete("/transfers/{code}")
async def cancel_transfer(code: str):
    """Cancel a pending transfer."""
    if code in transfer_tokens:
        del transfer_tokens[code]
        return {"status": "cancelled", "code": code}
    raise HTTPException(status_code=404, detail="Transfer not found")


@app.get("/transfers/history", response_model=List[TransferLogResponse])
async def get_transfer_history(device_mac: Optional[str] = None):
    """Get ownership transfer history."""
    # Mock data for demo
    return []


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

