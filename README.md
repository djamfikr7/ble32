# 🔋 BLE32 - ESP32 BLE Weight Scale System

<p align="center">
  <img src="https://img.shields.io/badge/ESP32-PlatformIO-blue?style=for-the-badge&logo=espressif" alt="ESP32">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/FastAPI-0.109-009688?style=for-the-badge&logo=fastapi" alt="FastAPI">
  <img src="https://img.shields.io/badge/PostgreSQL-15-336791?style=for-the-badge&logo=postgresql" alt="PostgreSQL">
</p>

A complete **BLE weight measurement system** featuring an ESP32 firmware, Flutter mobile app with neomorphism UI, and FastAPI backend with secure P2P ownership transfer.

---

## ✨ Features

### 📱 Mobile App (Flutter)
- **Neomorphism UI** with premium dark mode
- **Animated weight gauge** with LCD display effect
- **BLE connection** with auto-reconnect
- **Product management** with categories
- **Transaction history** with charts
- **3-step calibration wizard**
- **Secure P2P ownership transfer** with PIN verification

### ⚡ ESP32 Firmware
- **HX711 load cell driver** with Kalman filtering
- **Moving average** for stability detection
- **BLE GATT service** with custom characteristics
- **Battery monitoring** with voltage divider
- **Low power optimizations**

### 🔧 Backend (FastAPI)
- **JWT authentication** with bcrypt
- **PostgreSQL** database with SQLAlchemy
- **RESTful API** for products, transactions, devices
- **Secure transfer** endpoints with time-limited tokens
- **Docker** deployment ready

---

## 📁 Project Structure

```
ble32/
├── firmware/                 # ESP32 PlatformIO project
│   ├── src/
│   │   ├── main.cpp          # Entry point
│   │   ├── config.h          # Pins, UUIDs, settings
│   │   ├── hx711_driver.h    # HX711 with Kalman filter
│   │   ├── ble_service.h     # BLE GATT service
│   │   └── kalman_filter.h   # Noise filtering
│   └── platformio.ini
│
├── mobile-app/               # Flutter application
│   └── lib/
│       ├── core/
│       │   ├── theme/        # Neomorphism design system
│       │   ├── widgets/      # Reusable UI components
│       │   ├── bluetooth/    # BLE service
│       │   └── services/     # Auth, device binding
│       └── features/
│           ├── auth/         # Login/Register
│           ├── scale/        # Weight measurement
│           ├── products/     # Product grid
│           ├── history/      # Transaction charts
│           ├── calibration/  # Setup wizard
│           └── transfer/     # P2P ownership
│
├── backend/                  # FastAPI server
│   ├── app/
│   │   ├── main.py           # API routes
│   │   └── models/           # SQLAlchemy models
│   ├── Dockerfile
│   └── requirements.txt
│
└── docker-compose.yml        # Full stack deployment
```

---

## 🚀 Quick Start

### ESP32 Firmware

1. Install [PlatformIO](https://platformio.org/)
2. Configure pins in `firmware/src/config.h`:
   ```cpp
   #define HX711_DOUT_PIN 16
   #define HX711_SCK_PIN  4
   ```
3. Build and upload:
   ```bash
   cd firmware
   pio run -t upload
   ```

### Flutter App

```bash
cd mobile-app
flutter pub get
flutter run
```

### Backend (Docker)

```bash
docker-compose up -d
# API: http://localhost:8000
# Docs: http://localhost:8000/docs
```

---

## 🔌 Hardware Setup

| Component | ESP32 Pin | Notes |
|-----------|-----------|-------|
| HX711 DOUT | GPIO 16 | Data output |
| HX711 SCK | GPIO 4 | Clock |
| Battery ADC | GPIO 34 | Voltage divider |
| Status LED | GPIO 2 | Built-in LED |

### Wiring Diagram

```
    ┌──────────┐
    │  HX711   │
    │          │
    │ VCC ─────┼── 3.3V
    │ GND ─────┼── GND
    │ DOUT ────┼── GPIO 16
    │ SCK ─────┼── GPIO 4
    └──────────┘
         │
    ┌────┴────┐
    │ Load    │
    │ Cell    │
    └─────────┘
```

---

## 🔐 Secure Ownership Transfer

The P2P transfer binds **phone device ID** with **ESP32 MAC address**:

1. **Sender** generates 6-digit PIN (valid 5 minutes)
2. **Receiver** enters PIN on their device
3. **Backend validates** device binding
4. **Ownership transfers** with audit log

```
┌─────────┐     PIN Code      ┌─────────┐
│ Sender  │ ───────────────▶  │Receiver │
│ (Phone) │                   │ (Phone) │
└────┬────┘                   └────┬────┘
     │                             │
     │ Phone ID + ESP32 MAC        │ Phone ID + ESP32 MAC
     │                             │
     ▼                             ▼
┌─────────────────────────────────────┐
│           Backend API               │
│  - Verify PIN                       │
│  - Check device binding             │
│  - Transfer ownership               │
│  - Log transaction                  │
└─────────────────────────────────────┘
```

---

## 📡 BLE Characteristics

| UUID | Name | Properties |
|------|------|------------|
| `0001` | Weight | Read, Notify |
| `0002` | Tare | Write |
| `0003` | Calibrate | Read, Write |
| `0004` | Battery | Read, Notify |
| `0005` | Settings | Read, Write |
| `0006` | Status | Notify |

---

## 🎨 UI Screenshots

The app features a **neomorphism design** with:
- Soft shadows and depth
- Animated weight gauge with glow
- Premium dark mode
- Gradient buttons with press effects

---

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Create account |
| POST | `/auth/login` | Get JWT token |
| GET | `/products` | List products |
| POST | `/transactions` | Create sale |
| POST | `/transfers/initiate` | Start transfer |
| POST | `/transfers/verify` | Complete transfer |

---

## 🛠️ Development

### Running Tests

```bash
# Flutter
cd mobile-app && flutter test

# Backend
cd backend && pytest
```

### Building for Production

```bash
# Flutter APK
flutter build apk --release

# ESP32 Firmware
pio run -e release
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

---

<p align="center">
  Made with ❤️ for the IoT community
</p>
