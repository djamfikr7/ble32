# ESP32 BLE Weight Measurement System

A comprehensive BLE weight measurement system with neomorphism-themed Flutter mobile app, ESP32 firmware, and FastAPI backend.

## 📱 Features

### Lite Version
- BLE connection to ESP32 weight scale
- Real-time weight display with animated dial
- Stability detection indicator
- Tare and calibration functions
- Product management with price calculation
- Receipt printing (Bluetooth thermal)
- Transaction history
- Multi-language support (EN/FR/AR)

### Pro Version (Coming Soon)
- Multi-scale network support
- Automatic product recognition (Barcode/Image/RFID)
- Inventory management
- Legal metrology calibration
- Advanced analytics dashboard

## 🏗️ Project Structure

```
├── firmware/          # ESP32 Arduino/PlatformIO project
├── mobile-app/        # Flutter application
├── backend/           # FastAPI + PostgreSQL backend
└── docs/              # Documentation
```

## 🚀 Quick Start

### ESP32 Firmware
```bash
cd firmware
pio run --target upload
```

### Mobile App
```bash
cd mobile-app
flutter pub get
flutter run
```

### Backend
```bash
cd backend
docker-compose up -d
```

## 📋 Requirements

- ESP32 development board
- HX711 load cell amplifier + load cell
- Flutter SDK 3.0+
- Docker & Docker Compose
- PostgreSQL 14+

## 📄 License

MIT License
