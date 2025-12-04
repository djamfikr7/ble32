import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ble_service.dart';

/// Mock BLE Scale for testing without hardware.
/// Simulates ESP32 weight readings, tare, and calibration.
class MockBLEScaleNotifier extends StateNotifier<BLEScaleState> {
  MockBLEScaleNotifier() : super(BLEScaleState()) {
    // Auto-start simulation and connection for immediate feedback
    _startWeightSimulation();
    _startBatteryDrain();
    // Auto-connect after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      state = state.copyWith(connectionState: BLEConnectionState.connected);
    });
  }

  Timer? _weightTimer;
  Timer? _batteryTimer;
  final Random _random = Random();

  // Simulation state
  double _tareOffset = 0.0; // Tare offset
  double _calibrationFactor = 1.0; // Calibration multiplier
  int _batteryLevel = 87; // Simulated battery %
  bool _isSimulating = true; // Start simulating immediately

  // Simulate adding/removing weight over time
  double _targetWeight = 0.0;
  double _currentWeight = 0.0;

  /// Start scanning (simulates finding devices)
  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 3)}) async {
    state = state.copyWith(
      connectionState: BLEConnectionState.scanning,
      scannedDevices: [],
    );

    // Simulate finding devices after a delay
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(connectionState: BLEConnectionState.connected);
  }

  /// Stop scanning
  Future<void> stopScan() async {
    if (state.connectionState == BLEConnectionState.scanning) {
      state = state.copyWith(connectionState: BLEConnectionState.disconnected);
    }
  }

  /// Connect to mock device
  Future<void> connect(dynamic device) async {
    state = state.copyWith(connectionState: BLEConnectionState.connected);
    _startWeightSimulation();
    _startBatteryDrain();
  }

  /// Disconnect
  Future<void> disconnect() async {
    _stopSimulation();
    state = state.copyWith(
      connectionState: BLEConnectionState.disconnected,
      weightData: WeightData.empty(),
    );
  }

  /// Tare the scale (zero out current weight)
  Future<void> tare() async {
    _tareOffset = _currentWeight;
    _updateWeight();
  }

  /// Calibrate with known weight
  Future<void> calibrate(double knownWeight) async {
    if (_currentWeight > 10) {
      _calibrationFactor = knownWeight / _currentWeight;
    }
  }

  /// Simulate placing weight on scale
  void simulateWeight(double grams) {
    _targetWeight = grams;
  }

  /// Simulate removing all weight
  void clearWeight() {
    _targetWeight = 0;
  }

  /// Add random weight fluctuation
  void addFluctuation() {
    _targetWeight += _random.nextDouble() * 100 - 50;
    if (_targetWeight < 0) _targetWeight = 0;
  }

  void _startWeightSimulation() {
    _isSimulating = true;
    _weightTimer?.cancel();

    // Update weight every 100ms (10 Hz like real scale)
    _weightTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isSimulating) return;

      // Smoothly move towards target weight
      final diff = _targetWeight - _currentWeight;
      _currentWeight += diff * 0.3; // Ease towards target

      // Add small noise for realism
      final noise = (_random.nextDouble() - 0.5) * 0.5;

      _updateWeight(noise: noise);
    });
  }

  void _startBatteryDrain() {
    _batteryTimer?.cancel();
    // Simulate slow battery drain
    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_batteryLevel > 5) {
        _batteryLevel--;
        _updateWeight();
      }
    });
  }

  void _updateWeight({double noise = 0}) {
    final displayWeight =
        (_currentWeight - _tareOffset) * _calibrationFactor + noise;
    final isStable = (displayWeight - state.weightData.weight).abs() < 1.0;

    final weightData = WeightData(
      weight: displayWeight.clamp(0, 50000), // Max 50kg
      unit: WeightUnit.grams,
      isStable: isStable,
      batteryLevel: _batteryLevel,
      errorCode: 0,
    );

    state = state.copyWith(weightData: weightData);
  }

  void _stopSimulation() {
    _isSimulating = false;
    _weightTimer?.cancel();
    _batteryTimer?.cancel();
    _currentWeight = 0;
    _targetWeight = 0;
    _tareOffset = 0;
  }

  @override
  void dispose() {
    _stopSimulation();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER CONFIGURATION
// ============================================================================

/// Set to true to use mock BLE, false for real hardware (or laptop emulator)
const bool useMockBLE = false;

/// Mock BLE provider (for testing)
final mockBLEScaleProvider =
    StateNotifierProvider<MockBLEScaleNotifier, BLEScaleState>((ref) {
  return MockBLEScaleNotifier();
});

/// Unified state provider that works with both mock and real
final bleStateProvider = Provider<BLEScaleState>((ref) {
  if (useMockBLE) {
    return ref.watch(mockBLEScaleProvider);
  } else {
    return ref.watch(bleScaleProvider);
  }
});
