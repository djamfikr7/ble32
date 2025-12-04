#ifndef KALMAN_FILTER_H
#define KALMAN_FILTER_H

/**
 * Simple Kalman Filter for weight measurement noise reduction.
 * Provides smooth weight readings while maintaining responsiveness.
 */
class KalmanFilter {
private:
  float q;  // Process noise covariance
  float r;  // Measurement noise covariance
  float x;  // Estimated value
  float p;  // Estimation error covariance
  float k;  // Kalman gain

public:
  /**
   * Initialize Kalman filter with noise parameters.
   * @param processNoise Process noise covariance (Q) - lower = smoother, higher = more responsive
   * @param measurementNoise Measurement noise covariance (R) - higher = smoother
   */
  KalmanFilter(float processNoise = 0.01f, float measurementNoise = 0.1f) 
    : q(processNoise), r(measurementNoise), x(0), p(1.0f), k(0) {}

  /**
   * Update filter with new measurement.
   * @param measurement New sensor reading
   * @return Filtered value
   */
  float update(float measurement) {
    // Prediction update
    p = p + q;
    
    // Measurement update
    k = p / (p + r);
    x = x + k * (measurement - x);
    p = (1 - k) * p;
    
    return x;
  }

  /**
   * Reset filter to a specific value.
   * @param value Initial value
   */
  void reset(float value = 0) {
    x = value;
    p = 1.0f;
  }

  /**
   * Get current filtered value.
   */
  float getValue() const {
    return x;
  }

  /**
   * Adjust noise parameters dynamically.
   */
  void setNoiseParams(float processNoise, float measurementNoise) {
    q = processNoise;
    r = measurementNoise;
  }
};

/**
 * Moving average filter for additional smoothing.
 */
template<size_t SIZE>
class MovingAverage {
private:
  float samples[SIZE];
  size_t index;
  size_t count;
  float sum;

public:
  MovingAverage() : index(0), count(0), sum(0) {
    for (size_t i = 0; i < SIZE; i++) {
      samples[i] = 0;
    }
  }

  /**
   * Add new sample and return average.
   */
  float add(float sample) {
    // Remove oldest sample from sum
    sum -= samples[index];
    
    // Add new sample
    samples[index] = sample;
    sum += sample;
    
    // Update index
    index = (index + 1) % SIZE;
    
    // Track sample count
    if (count < SIZE) {
      count++;
    }
    
    return getAverage();
  }

  /**
   * Get current average.
   */
  float getAverage() const {
    if (count == 0) return 0;
    return sum / count;
  }

  /**
   * Reset filter.
   */
  void reset() {
    index = 0;
    count = 0;
    sum = 0;
    for (size_t i = 0; i < SIZE; i++) {
      samples[i] = 0;
    }
  }

  /**
   * Check if filter is fully populated.
   */
  bool isFull() const {
    return count >= SIZE;
  }
};

#endif // KALMAN_FILTER_H
