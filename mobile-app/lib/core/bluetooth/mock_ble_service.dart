import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ble_service.dart';

/// Mock BLE Scale for testing without hardware.
/// Simulates ESP32 weight readings, tare, and calibration.
class MockBLEScaleNotifier extends StateNotifier<BLEScaleState> {
  MockBLEScaleNotifier() : super(BLEScaleState());

  Timer? _weightTimer;
  Timer? _batteryTimer;
  final Random _random = Random();

  // Simulation state
  double _baseWeight = 0.0; // Current base weight (after tare)
  double _tareOffset = 0.0; // Tare offset
  double _calibrationFactor = 1.0; // Calibration multiplier
  int _batteryLevel = 87; // Simulated battery %
  bool _isSimulating = false;

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
    await Future.delayed(const Duration(milliseconds: 800));

    // Create mock devices
    final mockDevices = <dynamic>[
      _MockBluetoothDevice('BLE-Scale-001', 'AA:BB:CC:DD:EE:01'),
      _MockBluetoothDevice('BLE-Scale-002', 'AA:BB:CC:DD:EE:02'),
      _MockBluetoothDevice('BLE-Scale-Demo', 'AA:BB:CC:DD:EE:FF'),
    ];

    // Emit devices one by one
    for (var i = 0; i < mockDevices.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        scannedDevices: [...state.scannedDevices, mockDevices[i]],
      );
    }

    // Stop scanning after timeout
    await Future.delayed(timeout);
    if (state.connectionState == BLEConnectionState.scanning) {
      state = state.copyWith(connectionState: BLEConnectionState.disconnected);
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    if (state.connectionState == BLEConnectionState.scanning) {
      state = state.copyWith(connectionState: BLEConnectionState.disconnected);
    }
  }

  /// Connect to mock device
  Future<void> connect(dynamic device) async {
    state = state.copyWith(
      connectionState: BLEConnectionState.connecting,
    );

    // Simulate connection delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Get device name
    String deviceName = 'Unknown';
    if (device is _MockBluetoothDevice) {
      deviceName = device.name;
    }

    state = state.copyWith(
      connectionState: BLEConnectionState.connected,
      device: null, // Real device would be set here
    );

    // Start simulating weight data
    _startWeightSimulation();
    _startBatteryDrain();

    print('🔗 Mock BLE: Connected to $deviceName');
  }

  /// Disconnect
  Future<void> disconnect() async {
    _stopSimulation();

    state = state.copyWith(
      connectionState: BLEConnectionState.disconnected,
      device: null,
      weightData: WeightData.empty(),
    );

    print('🔌 Mock BLE: Disconnected');
  }

  /// Tare the scale (zero out current weight)
  Future<void> tare() async {
    _tareOffset = _currentWeight;
    print('⚖️ Mock BLE: Tare set to ${_tareOffset.toStringAsFixed(1)}g');

    // Immediate feedback
    _updateWeight();
  }

  /// Calibrate with known weight
  Future<void> calibrate(double knownWeight) async {
    if (_currentWeight > 10) {
      // Need some weight on scale
      _calibrationFactor = knownWeight / _currentWeight;
      print(
          '🔧 Mock BLE: Calibrated with factor ${_calibrationFactor.toStringAsFixed(4)}');
    }
  }

  /// Simulate placing weight on scale
  void simulateWeight(double grams) {
    _targetWeight = grams;
    print('📦 Mock BLE: Simulating ${grams}g on scale');
  }

  /// Simulate removing all weight
  void clearWeight() {
    _targetWeight = 0;
    print('📦 Mock BLE: Weight removed');
  }

  /// Add random weight fluctuation
  void addFluctuation() {
    _targetWeight += _random.nextDouble() * 100 - 50;
    if (_targetWeight < 0) _targetWeight = 0;
  }

  void _startWeightSimulation() {
    _isSimulating = true;

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

/// Mock Bluetooth Device (mimics BluetoothDevice interface)
class _MockBluetoothDevice {
  final String name;
  final String macAddress;

  _MockBluetoothDevice(this.name, this.macAddress);

  String get platformName => name;
  _MockRemoteId get remoteId => _MockRemoteId(macAddress);

  @override
  String toString() => name;
}

class _MockRemoteId {
  final String str;
  _MockRemoteId(this.str);
}

// ============================================================================
// PROVIDER CONFIGURATION
// ============================================================================

/// Set to true to use mock BLE, false for real hardware
const bool useMockBLE = true;

/// Mock BLE provider (for testing)
final mockBLEScaleProvider =
    StateNotifierProvider<MockBLEScaleNotifier, BLEScaleState>((ref) {
  return MockBLEScaleNotifier();
});

/// Active BLE provider - switch between mock and real
final activeBLEScaleProvider = Provider<StateNotifier<BLEScaleState>>((ref) {
  if (useMockBLE) {
    return ref.watch(mockBLEScaleProvider.notifier);
  } else {
    return ref.watch(bleScaleProvider.notifier);
  }
});

/// Unified state provider that works with both mock and real
final bleStateProvider = Provider<BLEScaleState>((ref) {
  if (useMockBLE) {
    return ref.watch(mockBLEScaleProvider);
  } else {
    return ref.watch(bleScaleProvider);
  }
});

/// Extension to get mock-specific controls
extension MockBLEControls on WidgetRef {
  /// Get mock notifier for simulation controls
  MockBLEScaleNotifier? get mockBLE {
    if (useMockBLE) {
      return read(mockBLEScaleProvider.notifier);
    }
    return null;
  }
}
