import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Device binding for secure ownership transfer.
/// Binds phone device ID with ESP32 MAC address.
class DeviceBinding {
  final String phoneId; // Phone unique identifier
  final String esp32Mac; // ESP32 BLE MAC address
  final int ownerId; // User who owns this binding
  final DateTime boundAt; // When binding was created

  DeviceBinding({
    required this.phoneId,
    required this.esp32Mac,
    required this.ownerId,
    required this.boundAt,
  });

  Map<String, dynamic> toJson() => {
        'phone_id': phoneId,
        'esp32_mac': esp32Mac,
        'owner_id': ownerId,
        'bound_at': boundAt.toIso8601String(),
      };

  factory DeviceBinding.fromJson(Map<String, dynamic> json) {
    return DeviceBinding(
      phoneId: json['phone_id'] ?? '',
      esp32Mac: json['esp32_mac'] ?? '',
      ownerId: json['owner_id'] ?? 0,
      boundAt: DateTime.parse(json['bound_at']),
    );
  }
}

/// Service to manage phone-ESP32 bindings
class DeviceBindingService {
  static const _boxName = 'device_bindings';

  /// Get unique phone device identifier
  static Future<String> getPhoneDeviceId() async {
    // Use platform-specific device ID
    // On real device, use device_info_plus package
    // For now, generate a stable ID based on platform
    try {
      if (Platform.isAndroid) {
        // Would use AndroidId from device_info_plus
        return 'android_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isIOS) {
        // Would use identifierForVendor from device_info_plus
        return 'ios_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {}
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if phone is authorized to access specific ESP32
  static Future<bool> isPhoneAuthorized(String esp32Mac) async {
    final box = await Hive.openBox<Map>(_boxName);
    final binding = box.get(esp32Mac);

    if (binding == null) return false;

    final currentPhoneId = await getPhoneDeviceId();
    return binding['phone_id'] == currentPhoneId;
  }

  /// Create binding between phone and ESP32
  static Future<DeviceBinding> createBinding({
    required String esp32Mac,
    required int ownerId,
  }) async {
    final phoneId = await getPhoneDeviceId();
    final binding = DeviceBinding(
      phoneId: phoneId,
      esp32Mac: esp32Mac,
      ownerId: ownerId,
      boundAt: DateTime.now(),
    );

    final box = await Hive.openBox<Map>(_boxName);
    await box.put(esp32Mac, binding.toJson());

    return binding;
  }

  /// Transfer binding to new owner
  static Future<bool> transferBinding({
    required String esp32Mac,
    required String transferCode,
    required int newOwnerId,
    required String newPhoneId,
  }) async {
    final box = await Hive.openBox<Map>(_boxName);
    final existingBinding = box.get(esp32Mac);

    if (existingBinding == null) {
      throw Exception('No binding exists for this device');
    }

    // Remove old binding
    await box.delete(esp32Mac);

    // Create new binding for new owner
    final newBinding = DeviceBinding(
      phoneId: newPhoneId,
      esp32Mac: esp32Mac,
      ownerId: newOwnerId,
      boundAt: DateTime.now(),
    );

    await box.put(esp32Mac, newBinding.toJson());
    return true;
  }

  /// Remove binding (for current owner only)
  static Future<void> removeBinding(String esp32Mac) async {
    final isAuthorized = await isPhoneAuthorized(esp32Mac);
    if (!isAuthorized) {
      throw Exception('Unauthorized: only owner can remove binding');
    }

    final box = await Hive.openBox<Map>(_boxName);
    await box.delete(esp32Mac);
  }

  /// Get all bindings for current phone
  static Future<List<DeviceBinding>> getMyBindings() async {
    final phoneId = await getPhoneDeviceId();
    final box = await Hive.openBox<Map>(_boxName);

    final bindings = <DeviceBinding>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null && data['phone_id'] == phoneId) {
        bindings.add(DeviceBinding.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return bindings;
  }

  /// Get binding for specific ESP32
  static Future<DeviceBinding?> getBinding(String esp32Mac) async {
    final box = await Hive.openBox<Map>(_boxName);
    final data = box.get(esp32Mac);
    if (data == null) return null;
    return DeviceBinding.fromJson(Map<String, dynamic>.from(data));
  }
}

/// Transfer request with device verification
class SecureTransferRequest {
  final String esp32Mac;
  final String senderPhoneId;
  final String receiverPhoneId;
  final String transferCode;
  final int senderId;
  final int receiverId;
  final DateTime createdAt;
  final DateTime expiresAt;

  SecureTransferRequest({
    required this.esp32Mac,
    required this.senderPhoneId,
    required this.receiverPhoneId,
    required this.transferCode,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'esp32_mac': esp32Mac,
        'sender_phone_id': senderPhoneId,
        'receiver_phone_id': receiverPhoneId,
        'transfer_code': transferCode,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

/// Provider for device binding operations
final deviceBindingProvider = Provider((ref) => DeviceBindingService());

/// Provider for current phone's bound devices
final myBoundDevicesProvider = FutureProvider<List<DeviceBinding>>((ref) {
  return DeviceBindingService.getMyBindings();
});
