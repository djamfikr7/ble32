#ifndef BLE_SERVICE_H
#define BLE_SERVICE_H

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "config.h"

// Forward declaration
class BLEScaleService;

// Callback handlers
class ServerCallbacks : public BLEServerCallbacks {
private:
  BLEScaleService* service;
public:
  ServerCallbacks(BLEScaleService* svc) : service(svc) {}
  void onConnect(BLEServer* pServer) override;
  void onDisconnect(BLEServer* pServer) override;
};

class TareCallback : public BLECharacteristicCallbacks {
private:
  void (*onTare)();
public:
  TareCallback(void (*callback)()) : onTare(callback) {}
  void onWrite(BLECharacteristic* pChar) override {
    if (onTare) onTare();
  }
};

class CalibrateCallback : public BLECharacteristicCallbacks {
private:
  void (*onCalibrate)(float);
public:
  CalibrateCallback(void (*callback)(float)) : onCalibrate(callback) {}
  void onWrite(BLECharacteristic* pChar) override {
    if (onCalibrate && pChar->getLength() >= 5) {
      uint8_t* data = pChar->getData();
      if (data[0] == 0x01) {  // Calibrate command
        float weight;
        memcpy(&weight, &data[1], 4);
        onCalibrate(weight);
      }
    }
  }
};

class SettingsCallback : public BLECharacteristicCallbacks {
private:
  void (*onSettings)(uint8_t*, size_t);
public:
  SettingsCallback(void (*callback)(uint8_t*, size_t)) : onSettings(callback) {}
  void onWrite(BLECharacteristic* pChar) override {
    if (onSettings) {
      onSettings(pChar->getData(), pChar->getLength());
    }
  }
};

/**
 * BLE GATT Service for the scale.
 */
class BLEScaleService {
private:
  BLEServer* pServer;
  BLEService* pService;
  BLECharacteristic* pWeightChar;
  BLECharacteristic* pTareChar;
  BLECharacteristic* pCalibrateChar;
  BLECharacteristic* pBatteryChar;
  BLECharacteristic* pSettingsChar;
  BLECharacteristic* pStatusChar;
  
  bool deviceConnected;
  bool oldDeviceConnected;
  
  // Callbacks
  void (*tareCallback)();
  void (*calibrateCallback)(float);
  void (*settingsCallback)(uint8_t*, size_t);

public:
  BLEScaleService() 
    : pServer(nullptr),
      pService(nullptr),
      deviceConnected(false),
      oldDeviceConnected(false),
      tareCallback(nullptr),
      calibrateCallback(nullptr),
      settingsCallback(nullptr) {}

  /**
   * Initialize BLE service.
   */
  void begin() {
    // Initialize BLE
    BLEDevice::init(BLE_DEVICE_NAME);
    
    // Create server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks(this));
    
    // Create service
    pService = pServer->createService(SERVICE_UUID);
    
    // Weight characteristic (notify)
    pWeightChar = pService->createCharacteristic(
      WEIGHT_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_NOTIFY
    );
    pWeightChar->addDescriptor(new BLE2902());
    
    // Tare characteristic (write)
    pTareChar = pService->createCharacteristic(
      TARE_CHAR_UUID,
      BLECharacteristic::PROPERTY_WRITE
    );
    if (tareCallback) {
      pTareChar->setCallbacks(new TareCallback(tareCallback));
    }
    
    // Calibrate characteristic (read/write)
    pCalibrateChar = pService->createCharacteristic(
      CALIBRATE_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_WRITE
    );
    if (calibrateCallback) {
      pCalibrateChar->setCallbacks(new CalibrateCallback(calibrateCallback));
    }
    
    // Battery characteristic (read/notify)
    pBatteryChar = pService->createCharacteristic(
      BATTERY_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_NOTIFY
    );
    pBatteryChar->addDescriptor(new BLE2902());
    
    // Settings characteristic (read/write)
    pSettingsChar = pService->createCharacteristic(
      SETTINGS_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_WRITE
    );
    if (settingsCallback) {
      pSettingsChar->setCallbacks(new SettingsCallback(settingsCallback));
    }
    
    // Status characteristic (notify)
    pStatusChar = pService->createCharacteristic(
      STATUS_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_NOTIFY
    );
    pStatusChar->addDescriptor(new BLE2902());
    
    // Start service
    pService->start();
    
    // Start advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  // For iPhone connections
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
    
    Serial.println("BLE Scale service started, advertising...");
  }

  /**
   * Send weight packet over BLE.
   */
  void sendWeight(const WeightPacket& packet) {
    if (deviceConnected) {
      pWeightChar->setValue((uint8_t*)&packet, sizeof(WeightPacket));
      pWeightChar->notify();
    }
  }

  /**
   * Send battery level.
   */
  void sendBattery(uint8_t level) {
    if (deviceConnected) {
      pBatteryChar->setValue(&level, 1);
      pBatteryChar->notify();
    }
  }

  /**
   * Send status message.
   */
  void sendStatus(const char* status) {
    if (deviceConnected) {
      pStatusChar->setValue(status);
      pStatusChar->notify();
    }
  }

  /**
   * Update calibration factor value (for reads).
   */
  void setCalibrationValue(float factor) {
    pCalibrateChar->setValue((uint8_t*)&factor, sizeof(float));
  }

  /**
   * Handle connection state changes.
   */
  void loop() {
    // Reconnection handling
    if (!deviceConnected && oldDeviceConnected) {
      delay(500);  // Give Bluetooth stack time
      pServer->startAdvertising();
      Serial.println("Restarting advertising...");
      oldDeviceConnected = deviceConnected;
    }
    
    if (deviceConnected && !oldDeviceConnected) {
      Serial.println("Device connected!");
      oldDeviceConnected = deviceConnected;
    }
  }

  // Setters for callbacks
  void setTareCallback(void (*cb)()) { 
    tareCallback = cb; 
    if (pTareChar) {
      pTareChar->setCallbacks(new TareCallback(cb));
    }
  }
  
  void setCalibrateCallback(void (*cb)(float)) { 
    calibrateCallback = cb; 
    if (pCalibrateChar) {
      pCalibrateChar->setCallbacks(new CalibrateCallback(cb));
    }
  }
  
  void setSettingsCallback(void (*cb)(uint8_t*, size_t)) { 
    settingsCallback = cb; 
    if (pSettingsChar) {
      pSettingsChar->setCallbacks(new SettingsCallback(cb));
    }
  }

  // Connection state
  bool isConnected() const { return deviceConnected; }
  void setConnected(bool connected) { deviceConnected = connected; }
};

// Implement server callbacks
void ServerCallbacks::onConnect(BLEServer* pServer) {
  service->setConnected(true);
  Serial.println("Client connected");
}

void ServerCallbacks::onDisconnect(BLEServer* pServer) {
  service->setConnected(false);
  Serial.println("Client disconnected");
}

#endif // BLE_SERVICE_H
