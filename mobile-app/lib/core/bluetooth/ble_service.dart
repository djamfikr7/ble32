import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// BLE Service UUIDs (matching ESP32 firmware)
class BLEUUIDs {
  static const String scaleService = "4a4e0001-6746-4b4e-8164-656e67696e65";
  static const String weightChar = "4a4e0002-6746-4b4e-8164-656e67696e65";
  static const String tareChar = "4a4e0003-6746-4b4e-8164-656e67696e65";
  static const String calibrateChar = "4a4e0004-6746-4b4e-8164-656e67696e65";
  static const String batteryChar = "4a4e0005-6746-4b4e-8164-656e67696e65";
  static const String settingsChar = "4a4e0006-6746-4b4e-8164-656e67696e65";
  static const String statusChar = "4a4e0007-6746-4b4e-8164-656e67696e65";
}

/// Weight data packet from ESP32
class WeightData {
  final double weight;
  final WeightUnit unit;
  final bool isStable;
  final int batteryLevel;
  final int errorCode;
  final DateTime timestamp;

  WeightData({
    required this.weight,
    required this.unit,
    required this.isStable,
    required this.batteryLevel,
    required this.errorCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WeightData.fromBytes(List<int> bytes) {
    if (bytes.length < 12) {
      return WeightData.empty();
    }

    // Parse according to ESP32 packet structure
    final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);

    return WeightData(
      weight: buffer.getFloat32(4, Endian.little),
      unit: WeightUnit.fromInt(bytes[8]),
      isStable: bytes[9] == 1,
      batteryLevel: bytes[10],
      errorCode: bytes[11],
    );
  }

  factory WeightData.empty() {
    return WeightData(
      weight: 0.0,
      unit: WeightUnit.grams,
      isStable: false,
      batteryLevel: 100,
      errorCode: 0,
    );
  }

  String get formattedWeight {
    switch (unit) {
      case WeightUnit.grams:
        return '${weight.toStringAsFixed(1)} g';
      case WeightUnit.kilograms:
        return '${(weight / 1000).toStringAsFixed(3)} kg';
      case WeightUnit.pounds:
        return '${(weight * 0.00220462).toStringAsFixed(3)} lb';
      case WeightUnit.ounces:
        return '${(weight * 0.035274).toStringAsFixed(2)} oz';
    }
  }
}

enum WeightUnit {
  grams,
  kilograms,
  pounds,
  ounces;

  static WeightUnit fromInt(int value) {
    return WeightUnit.values[value.clamp(0, 3)];
  }
}

/// BLE connection state
enum BLEConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// BLE Scale State
class BLEScaleState {
  final BLEConnectionState connectionState;
  final BluetoothDevice? device;
  final WeightData weightData;
  final String? errorMessage;
  final List<BluetoothDevice> scannedDevices;

  BLEScaleState({
    this.connectionState = BLEConnectionState.disconnected,
    this.device,
    WeightData? weightData,
    this.errorMessage,
    this.scannedDevices = const [],
  }) : weightData = weightData ?? WeightData.empty();

  BLEScaleState copyWith({
    BLEConnectionState? connectionState,
    BluetoothDevice? device,
    WeightData? weightData,
    String? errorMessage,
    List<BluetoothDevice>? scannedDevices,
  }) {
    return BLEScaleState(
      connectionState: connectionState ?? this.connectionState,
      device: device ?? this.device,
      weightData: weightData ?? this.weightData,
      errorMessage: errorMessage,
      scannedDevices: scannedDevices ?? this.scannedDevices,
    );
  }
}

/// BLE Scale Service Provider
class BLEScaleNotifier extends StateNotifier<BLEScaleState> {
  BLEScaleNotifier() : super(BLEScaleState());

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _weightSubscription;
  BluetoothCharacteristic? _weightCharacteristic;
  BluetoothCharacteristic? _tareCharacteristic;
  BluetoothCharacteristic? _calibrateCharacteristic;

  // MAC address whitelist (configurable)
  final Set<String> _allowedMACs = {};

  void setAllowedMACs(List<String> macs) {
    _allowedMACs.clear();
    _allowedMACs.addAll(macs.map((m) => m.toUpperCase()));
  }

  /// Start scanning for BLE devices
  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      state = state.copyWith(
        connectionState: BLEConnectionState.scanning,
        scannedDevices: [],
      );

      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        state = state.copyWith(
          connectionState: BLEConnectionState.error,
          errorMessage: 'Bluetooth is turned off',
        );
        return;
      }

      // Start scan
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(BLEUUIDs.scaleService)],
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final devices = results
            .where((r) => r.device.platformName.isNotEmpty)
            .map((r) => r.device)
            .where((d) {
          // Filter by whitelist if configured
          if (_allowedMACs.isEmpty) return true;
          return _allowedMACs.contains(d.remoteId.str.toUpperCase());
        }).toList();

        state = state.copyWith(scannedDevices: devices);
      });

      // Auto-stop after timeout
      Future.delayed(timeout, () {
        if (state.connectionState == BLEConnectionState.scanning) {
          stopScan();
        }
      });
    } catch (e) {
      state = state.copyWith(
        connectionState: BLEConnectionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();

    if (state.connectionState == BLEConnectionState.scanning) {
      state = state.copyWith(connectionState: BLEConnectionState.disconnected);
    }
  }

  /// Connect to a device
  Future<void> connect(BluetoothDevice device) async {
    try {
      await stopScan();

      state = state.copyWith(
        connectionState: BLEConnectionState.connecting,
        device: device,
      );

      // Connect with auto-reconnect
      await device.connect(autoConnect: true);

      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.disconnected) {
          state =
              state.copyWith(connectionState: BLEConnectionState.disconnected);
          _weightSubscription?.cancel();
        }
      });

      // Discover services
      final services = await device.discoverServices();
      final scaleService = services.firstWhere(
        (s) =>
            s.uuid.toString().toLowerCase() ==
            BLEUUIDs.scaleService.toLowerCase(),
        orElse: () => throw Exception('Scale service not found'),
      );

      // Get characteristics
      for (final char in scaleService.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();

        if (uuid == BLEUUIDs.weightChar.toLowerCase()) {
          _weightCharacteristic = char;
          // Subscribe to weight notifications
          await char.setNotifyValue(true);
          _weightSubscription = char.lastValueStream.listen(_onWeightData);
        } else if (uuid == BLEUUIDs.tareChar.toLowerCase()) {
          _tareCharacteristic = char;
        } else if (uuid == BLEUUIDs.calibrateChar.toLowerCase()) {
          _calibrateCharacteristic = char;
        }
      }

      state = state.copyWith(connectionState: BLEConnectionState.connected);
    } catch (e) {
      state = state.copyWith(
        connectionState: BLEConnectionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    _weightSubscription?.cancel();
    _connectionSubscription?.cancel();

    await state.device?.disconnect();

    state = state.copyWith(
      connectionState: BLEConnectionState.disconnected,
      device: null,
    );
  }

  /// Send tare command
  Future<void> tare() async {
    if (_tareCharacteristic == null) return;

    try {
      await _tareCharacteristic!.write([0x01]); // Tare command
    } catch (e) {
      state = state.copyWith(errorMessage: 'Tare failed: $e');
    }
  }

  /// Send calibration command
  Future<void> calibrate(double knownWeight) async {
    if (_calibrateCharacteristic == null) return;

    try {
      final buffer = ByteData(5);
      buffer.setUint8(0, 0x01); // Calibrate command
      buffer.setFloat32(1, knownWeight, Endian.little);

      await _calibrateCharacteristic!.write(buffer.buffer.asUint8List());
    } catch (e) {
      state = state.copyWith(errorMessage: 'Calibration failed: $e');
    }
  }

  void _onWeightData(List<int> data) {
    final weightData = WeightData.fromBytes(data);
    state = state.copyWith(weightData: weightData);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _weightSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}

/// Provider for BLE Scale Service
final bleScaleProvider =
    StateNotifierProvider<BLEScaleNotifier, BLEScaleState>((ref) {
  return BLEScaleNotifier();
});
