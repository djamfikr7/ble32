import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'ble_service.dart';

/// Mock BLE Scale for testing without hardware.
/// Can connect to Python emulator via WebSocket or run standalone simulation.
class MockBLEScaleNotifier extends StateNotifier<BLEScaleState> {
  MockBLEScaleNotifier() : super(BLEScaleState()) {
    // Try connecting to emulator first
    _connectToEmulator();
  }

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;

  // Fallback simulation state (used if emulator not connected)
  Timer? _simTimer;
  final Random _random = Random();
  double _simWeight = 0.0;
  double _simTarget = 0.0;
  bool _useInternalSim = true;

  /// Connect to Python emulator
  void _connectToEmulator() {
    try {
      // Use localhost for Android emulator (10.0.2.2) or standard localhost
      // For web/desktop, localhost works. For Android emulator, use 10.0.2.2
      const url = 'ws://localhost:8765';

      print('🔌 Connecting to emulator at $url...');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          _useInternalSim = false; // Emulator is active!
          _parseEmulatorMessage(message);
        },
        onError: (error) {
          print('❌ Emulator error: $error');
          _useInternalSim = true;
          _scheduleReconnect();
        },
        onDone: () {
          print('🔌 Emulator disconnected');
          _useInternalSim = true;
          _scheduleReconnect();
        },
      );

      // Auto-connect BLE state when emulator connects
      state = state.copyWith(connectionState: BLEConnectionState.connected);
    } catch (e) {
      print('❌ Connection failed: $e');
      _useInternalSim = true;
      _scheduleReconnect();
    }

    // Start fallback simulation just in case
    _startInternalSimulation();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connectToEmulator);
  }

  void _parseEmulatorMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      if (data['type'] == 'weight') {
        final weight = (data['weight'] as num).toDouble();
        final isStable = data['stable'] as bool;
        final battery = data['battery'] as int;

        state = state.copyWith(
          weightData: WeightData(
            weight: weight,
            unit: WeightUnit.grams,
            isStable: isStable,
            batteryLevel: battery,
            errorCode: 0,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Error parsing emulator data: $e');
    }
  }

  // ==========================================================================
  // PUBLIC METHODS (Same as original MockBLE)
  // ==========================================================================

  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 3)}) async {
    state = state.copyWith(connectionState: BLEConnectionState.scanning);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(connectionState: BLEConnectionState.connected);
  }

  Future<void> stopScan() async {}

  Future<void> connect(dynamic device) async {
    state = state.copyWith(connectionState: BLEConnectionState.connected);
  }

  Future<void> disconnect() async {
    state = state.copyWith(connectionState: BLEConnectionState.disconnected);
  }

  Future<void> tare() async {
    if (_channel != null && !_useInternalSim) {
      _channel!.sink.add(jsonEncode({'command': 'tare'}));
    } else {
      _simWeight = 0; // Simple tare for internal sim
    }
  }

  Future<void> calibrate(double knownWeight) async {
    if (_channel != null && !_useInternalSim) {
      _channel!.sink
          .add(jsonEncode({'command': 'calibrate', 'weight': knownWeight}));
    }
  }

  // Called by Debug Panel slider
  void simulateWeight(double grams) {
    if (_channel != null && !_useInternalSim) {
      _channel!.sink
          .add(jsonEncode({'command': 'set_weight', 'weight': grams}));
    } else {
      _simTarget = grams;
    }
  }

  void addFluctuation() {
    simulateWeight(_simTarget + (_random.nextDouble() * 100 - 50));
  }

  // ==========================================================================
  // INTERNAL SIMULATION (Fallback)
  // ==========================================================================

  void _startInternalSimulation() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_useInternalSim) return;

      // Smooth move
      final diff = _simTarget - _simWeight;
      _simWeight += diff * 0.3;

      // Noise
      final noise = (_random.nextDouble() - 0.5) * 0.5;
      final displayWeight = _simWeight + noise;

      state = state.copyWith(
        weightData: WeightData(
          weight: displayWeight.clamp(0, 50000),
          unit: WeightUnit.grams,
          isStable: (displayWeight - state.weightData.weight).abs() < 1.0,
          batteryLevel: 85,
          errorCode: 0,
        ),
      );
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER CONFIGURATION
// ============================================================================

/// Set to true to use mock BLE (internal or WebSocket), false for real hardware
const bool useMockBLE = true;

final mockBLEScaleProvider =
    StateNotifierProvider<MockBLEScaleNotifier, BLEScaleState>((ref) {
  return MockBLEScaleNotifier();
});

final bleStateProvider = Provider<BLEScaleState>((ref) {
  if (useMockBLE) {
    return ref.watch(mockBLEScaleProvider);
  } else {
    return ref.watch(bleScaleProvider);
  }
});
