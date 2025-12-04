/**
 * ESP32 BLE Scale Firmware
 * 
 * Main entry point for the BLE weight measurement system.
 * Handles HX711 weight sensor, BLE communication, and battery monitoring.
 */

#include <Arduino.h>
#include "config.h"
#include "hx711_driver.h"
#include "ble_service.h"

// Global instances
HX711Driver weightSensor;
BLEScaleService bleService;

// Timing
unsigned long lastWeightUpdate = 0;
unsigned long lastBatteryCheck = 0;
unsigned long lastActivityTime = 0;

// Battery level
uint8_t batteryLevel = 100;

// =============================================================================
// Battery Monitoring
// =============================================================================

uint8_t readBatteryLevel() {
  // Read ADC value
  int rawValue = analogRead(BATTERY_PIN);
  
  // Convert to millivolts (ESP32 ADC is 12-bit, 0-4095)
  // With default attenuation, max is ~3.3V
  // Using voltage divider if battery is >3.3V
  float voltage = (rawValue / 4095.0f) * 3.3f * 2.0f;  // *2 for voltage divider
  int milliVolts = (int)(voltage * 1000);
  
  // Map to percentage
  if (milliVolts >= BATTERY_MAX_MV) return 100;
  if (milliVolts <= BATTERY_MIN_MV) return 0;
  
  return (uint8_t)((milliVolts - BATTERY_MIN_MV) * 100 / (BATTERY_MAX_MV - BATTERY_MIN_MV));
}

// =============================================================================
// BLE Callbacks
// =============================================================================

void onTare() {
  Serial.println("Tare command received");
  weightSensor.tare();
  lastActivityTime = millis();
}

void onCalibrate(float knownWeight) {
  Serial.printf("Calibrate command received: %.2f g\n", knownWeight);
  weightSensor.calibrate(knownWeight);
  bleService.setCalibrationValue(weightSensor.getCalibrationFactor());
  lastActivityTime = millis();
}

void onSettings(uint8_t* data, size_t len) {
  Serial.println("Settings update received");
  
  if (len >= 1) {
    // First byte is unit setting
    WeightUnit unit = (WeightUnit)data[0];
    weightSensor.setUnit(unit);
    Serial.printf("Unit set to: %d\n", unit);
  }
  
  lastActivityTime = millis();
}

// =============================================================================
// Setup
// =============================================================================

void setup() {
  Serial.begin(115200);
  Serial.println("\n=================================");
  Serial.println("ESP32 BLE Scale Firmware v1.0");
  Serial.println("=================================\n");
  
  // Configure LED
  pinMode(LED_STATUS_PIN, OUTPUT);
  digitalWrite(LED_STATUS_PIN, LOW);
  
  // Configure battery ADC
  pinMode(BATTERY_PIN, INPUT);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  
  // Initialize HX711
  Serial.println("Initializing HX711...");
  if (weightSensor.begin()) {
    Serial.println("HX711 initialized successfully!");
    digitalWrite(LED_STATUS_PIN, HIGH);
  } else {
    Serial.println("ERROR: HX711 initialization failed!");
    // Blink LED to indicate error
    for (int i = 0; i < 10; i++) {
      digitalWrite(LED_STATUS_PIN, !digitalRead(LED_STATUS_PIN));
      delay(200);
    }
  }
  
  // Read initial battery level
  batteryLevel = readBatteryLevel();
  Serial.printf("Battery level: %d%%\n", batteryLevel);
  
  // Set BLE callbacks
  bleService.setTareCallback(onTare);
  bleService.setCalibrateCallback(onCalibrate);
  bleService.setSettingsCallback(onSettings);
  
  // Initialize BLE
  Serial.println("Starting BLE service...");
  bleService.begin();
  
  lastActivityTime = millis();
  Serial.println("\nReady! Waiting for connections...\n");
}

// =============================================================================
// Main Loop
// =============================================================================

void loop() {
  unsigned long currentTime = millis();
  
  // Handle BLE connection state
  bleService.loop();
  
  // Read and send weight at regular intervals
  if (currentTime - lastWeightUpdate >= WEIGHT_UPDATE_INTERVAL_MS) {
    lastWeightUpdate = currentTime;
    
    // Read weight
    float weight = weightSensor.readWeight();
    
    // Create and send packet
    WeightPacket packet = weightSensor.getWeightPacket(batteryLevel);
    bleService.sendWeight(packet);
    
    // Debug output
    if (bleService.isConnected()) {
      Serial.printf("Weight: %.1f g | Stable: %s | Battery: %d%%\n",
        weight,
        weightSensor.getIsStable() ? "YES" : "NO",
        batteryLevel
      );
    }
    
    // Update activity time if weight changed significantly
    if (abs(weight - weightSensor.getLastStableWeight()) > 5.0f) {
      lastActivityTime = currentTime;
    }
    
    // Status LED blink when connected
    if (bleService.isConnected()) {
      static bool ledState = false;
      static unsigned long lastLedToggle = 0;
      if (currentTime - lastLedToggle > 1000) {
        ledState = !ledState;
        digitalWrite(LED_STATUS_PIN, ledState);
        lastLedToggle = currentTime;
      }
    }
  }
  
  // Check battery at regular intervals
  if (currentTime - lastBatteryCheck >= BATTERY_CHECK_INTERVAL_MS) {
    lastBatteryCheck = currentTime;
    batteryLevel = readBatteryLevel();
    bleService.sendBattery(batteryLevel);
  }
  
  // Visual feedback based on stability
  if (weightSensor.getIsStable() && weightSensor.getLastWeight() > 10) {
    // Brief LED flash when stable with weight
    digitalWrite(LED_STATUS_PIN, HIGH);
  }
  
  // Small delay to prevent CPU hogging
  delay(10);
}
