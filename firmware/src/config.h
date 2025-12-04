#ifndef CONFIG_H
#define CONFIG_H

// =============================================================================
// Hardware Configuration
// =============================================================================

// HX711 Load Cell Amplifier pins
#define HX711_DOUT_PIN  16
#define HX711_SCK_PIN   17

// Battery voltage monitoring (ADC)
#define BATTERY_PIN     34
#define BATTERY_MIN_MV  3200  // 0% battery
#define BATTERY_MAX_MV  4200  // 100% battery

// LED indicators (optional)
#define LED_STATUS_PIN  2     // Built-in LED

// =============================================================================
// BLE Configuration
// =============================================================================

#define BLE_DEVICE_NAME "BLE-Scale"

// Custom GATT Service and Characteristic UUIDs
// Service: 4a4e0001-6746-4b4e-8164-656e67696e65
// Format: Vendor-specific (0x4A4E = "JN" prefix)

#define SERVICE_UUID           "4a4e0001-6746-4b4e-8164-656e67696e65"
#define WEIGHT_CHAR_UUID       "4a4e0002-6746-4b4e-8164-656e67696e65"  // Weight data (notify)
#define TARE_CHAR_UUID         "4a4e0003-6746-4b4e-8164-656e67696e65"  // Tare command (write)
#define CALIBRATE_CHAR_UUID    "4a4e0004-6746-4b4e-8164-656e67696e65"  // Calibration (r/w)
#define BATTERY_CHAR_UUID      "4a4e0005-6746-4b4e-8164-656e67696e65"  // Battery level (read)
#define SETTINGS_CHAR_UUID     "4a4e0006-6746-4b4e-8164-656e67696e65"  // Settings (r/w)
#define STATUS_CHAR_UUID       "4a4e0007-6746-4b4e-8164-656e67696e65"  // Status (notify)

// =============================================================================
// Weight Measurement Settings
// =============================================================================

// Calibration defaults
#define DEFAULT_CALIBRATION_FACTOR  420.0f  // Adjust based on your load cell
#define DEFAULT_OFFSET              0

// Filtering
#define KALMAN_Q        0.01f   // Process noise covariance
#define KALMAN_R        0.1f    // Measurement noise covariance
#define MOVING_AVG_SIZE 10      // Number of samples for moving average

// Stability detection
#define STABILITY_THRESHOLD_G    0.5f   // Grams variation threshold
#define STABILITY_SAMPLES        10     // Consecutive stable samples required
#define STABILITY_TIMEOUT_MS     3000   // Max time to wait for stability

// Weight limits
#define MAX_WEIGHT_G    5000.0f  // Maximum weight in grams
#define MIN_WEIGHT_G    -50.0f   // Allow slight under-zero for tare adjustment

// =============================================================================
// MAC Whitelist (Security)
// =============================================================================

// Enable/disable MAC filtering
#define ENABLE_MAC_WHITELIST  false

// Add allowed MAC addresses (uppercase, no colons)
// Example: "AA:BB:CC:DD:EE:FF" -> "AABBCCDDEEFF"
#define MAX_WHITELIST_SIZE    10
const char* MAC_WHITELIST[] = {
  // Add your allowed device MACs here
  // "AABBCCDDEEFF",
};

// =============================================================================
// Timing Configuration
// =============================================================================

#define WEIGHT_UPDATE_INTERVAL_MS   100   // Send weight every 100ms
#define BATTERY_CHECK_INTERVAL_MS   30000 // Check battery every 30s
#define BLE_ADVERTISING_INTERVAL_MS 100   // BLE advertising interval
#define DEEP_SLEEP_TIMEOUT_MS       300000 // Sleep after 5 min inactivity

// =============================================================================
// Weight Data Packet Structure
// =============================================================================
// Sent over BLE as binary data (12 bytes):
// [0-3]   Magic bytes: 0x57 0x45 0x49 0x47 ("WEIG")
// [4-7]   Weight (float32, little-endian, in grams)
// [8]     Unit: 0=g, 1=kg, 2=lb, 3=oz
// [9]     Flags: bit0=stable, bit1=overload, bit2=negative
// [10]    Battery level (0-100%)
// [11]    Error code: 0=OK, 1=sensor error, 2=overload

struct __attribute__((packed)) WeightPacket {
  uint8_t magic[4];      // "WEIG" 
  float weight;          // Weight in grams
  uint8_t unit;          // 0=g, 1=kg, 2=lb, 3=oz
  uint8_t flags;         // Status flags
  uint8_t battery;       // Battery percentage
  uint8_t errorCode;     // Error code
};

// Weight units enum
enum WeightUnit {
  UNIT_GRAMS = 0,
  UNIT_KILOGRAMS = 1,
  UNIT_POUNDS = 2,
  UNIT_OUNCES = 3
};

// Error codes
enum ErrorCode {
  ERROR_NONE = 0,
  ERROR_SENSOR = 1,
  ERROR_OVERLOAD = 2,
  ERROR_CALIBRATION = 3
};

#endif // CONFIG_H
