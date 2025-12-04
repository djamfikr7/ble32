#ifndef HX711_DRIVER_H
#define HX711_DRIVER_H

#include <HX711.h>
#include "config.h"
#include "kalman_filter.h"

/**
 * Advanced HX711 driver with filtering and stability detection.
 */
class HX711Driver {
private:
  HX711 scale;
  KalmanFilter kalman;
  MovingAverage<MOVING_AVG_SIZE> movingAvg;
  
  float calibrationFactor;
  long offset;
  float lastWeight;
  float lastStableWeight;
  
  // Stability detection
  float stabilityHistory[STABILITY_SAMPLES];
  int stabilityIndex;
  bool isStable;
  unsigned long stabilityStartTime;
  
  // Current unit
  WeightUnit currentUnit;
  
  // Error state
  ErrorCode errorCode;
  bool sensorReady;

public:
  HX711Driver() 
    : kalman(KALMAN_Q, KALMAN_R),
      calibrationFactor(DEFAULT_CALIBRATION_FACTOR),
      offset(DEFAULT_OFFSET),
      lastWeight(0),
      lastStableWeight(0),
      stabilityIndex(0),
      isStable(false),
      stabilityStartTime(0),
      currentUnit(UNIT_GRAMS),
      errorCode(ERROR_NONE),
      sensorReady(false) {
    
    for (int i = 0; i < STABILITY_SAMPLES; i++) {
      stabilityHistory[i] = 0;
    }
  }

  /**
   * Initialize the HX711 sensor.
   * @return true if successful
   */
  bool begin() {
    scale.begin(HX711_DOUT_PIN, HX711_SCK_PIN);
    
    // Wait for sensor to be ready
    unsigned long startTime = millis();
    while (!scale.is_ready()) {
      if (millis() - startTime > 2000) {
        errorCode = ERROR_SENSOR;
        sensorReady = false;
        return false;
      }
      delay(10);
    }
    
    scale.set_scale(calibrationFactor);
    scale.set_offset(offset);
    
    sensorReady = true;
    errorCode = ERROR_NONE;
    return true;
  }

  /**
   * Read and filter weight.
   * @return Filtered weight in grams
   */
  float readWeight() {
    if (!sensorReady) {
      errorCode = ERROR_SENSOR;
      return 0;
    }
    
    if (!scale.is_ready()) {
      return lastWeight;
    }
    
    // Get raw reading
    float rawWeight = scale.get_units(1);
    
    // Clamp to valid range
    if (rawWeight > MAX_WEIGHT_G) {
      errorCode = ERROR_OVERLOAD;
      rawWeight = MAX_WEIGHT_G;
    } else if (rawWeight < MIN_WEIGHT_G) {
      rawWeight = 0;
    } else {
      errorCode = ERROR_NONE;
    }
    
    // Apply Kalman filter
    float kalmanWeight = kalman.update(rawWeight);
    
    // Apply moving average
    float smoothWeight = movingAvg.add(kalmanWeight);
    
    // Update stability
    updateStability(smoothWeight);
    
    lastWeight = smoothWeight;
    return smoothWeight;
  }

  /**
   * Update stability detection.
   */
  void updateStability(float weight) {
    stabilityHistory[stabilityIndex] = weight;
    stabilityIndex = (stabilityIndex + 1) % STABILITY_SAMPLES;
    
    // Calculate variance
    float min = stabilityHistory[0];
    float max = stabilityHistory[0];
    
    for (int i = 1; i < STABILITY_SAMPLES; i++) {
      if (stabilityHistory[i] < min) min = stabilityHistory[i];
      if (stabilityHistory[i] > max) max = stabilityHistory[i];
    }
    
    float range = max - min;
    
    if (range <= STABILITY_THRESHOLD_G) {
      if (!isStable) {
        if (stabilityStartTime == 0) {
          stabilityStartTime = millis();
        } else if (millis() - stabilityStartTime > 200) {
          isStable = true;
          lastStableWeight = weight;
        }
      }
    } else {
      isStable = false;
      stabilityStartTime = 0;
    }
  }

  /**
   * Tare the scale (zero offset).
   */
  void tare() {
    if (!sensorReady) return;
    
    scale.tare(10);  // Average 10 readings
    kalman.reset(0);
    movingAvg.reset();
    lastWeight = 0;
    lastStableWeight = 0;
    
    for (int i = 0; i < STABILITY_SAMPLES; i++) {
      stabilityHistory[i] = 0;
    }
  }

  /**
   * Calibrate with known weight.
   * @param knownWeight Weight in grams of calibration mass
   */
  void calibrate(float knownWeight) {
    if (!sensorReady || knownWeight <= 0) return;
    
    // Get raw value (no scaling)
    scale.set_scale(1);
    float rawValue = scale.get_units(20);  // Average 20 readings
    
    // Calculate new calibration factor
    calibrationFactor = rawValue / knownWeight;
    scale.set_scale(calibrationFactor);
    
    // Reset filters
    kalman.reset(knownWeight);
    movingAvg.reset();
  }

  /**
   * Convert weight to current unit.
   */
  float convertWeight(float grams) {
    switch (currentUnit) {
      case UNIT_KILOGRAMS:
        return grams / 1000.0f;
      case UNIT_POUNDS:
        return grams * 0.00220462f;
      case UNIT_OUNCES:
        return grams * 0.035274f;
      default:
        return grams;
    }
  }

  /**
   * Create weight packet for BLE transmission.
   */
  WeightPacket getWeightPacket(uint8_t batteryLevel) {
    WeightPacket packet;
    
    // Magic bytes
    packet.magic[0] = 'W';
    packet.magic[1] = 'E';
    packet.magic[2] = 'I';
    packet.magic[3] = 'G';
    
    // Weight in grams (always)
    packet.weight = lastWeight;
    
    // Unit
    packet.unit = currentUnit;
    
    // Flags
    packet.flags = 0;
    if (isStable) packet.flags |= 0x01;
    if (errorCode == ERROR_OVERLOAD) packet.flags |= 0x02;
    if (lastWeight < 0) packet.flags |= 0x04;
    
    // Battery and error
    packet.battery = batteryLevel;
    packet.errorCode = errorCode;
    
    return packet;
  }

  // Getters
  bool getIsStable() const { return isStable; }
  float getLastWeight() const { return lastWeight; }
  float getLastStableWeight() const { return lastStableWeight; }
  ErrorCode getErrorCode() const { return errorCode; }
  bool isReady() const { return sensorReady; }
  float getCalibrationFactor() const { return calibrationFactor; }
  
  // Setters
  void setUnit(WeightUnit unit) { currentUnit = unit; }
  void setCalibrationFactor(float factor) { 
    calibrationFactor = factor; 
    scale.set_scale(calibrationFactor);
  }
};

#endif // HX711_DRIVER_H
