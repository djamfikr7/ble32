import 'package:uuid/uuid.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String productIcon;
  final double pricePerKg;
  final double weightGrams;
  final String? customerName;
  final DateTime createdAt;

  CartItem({
    String? id,
    required this.productId,
    required this.productName,
    required this.productIcon,
    required this.pricePerKg,
    required this.weightGrams,
    this.customerName,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get weightKg => weightGrams / 1000;
  double get totalPrice => weightKg * pricePerKg;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productIcon': productIcon,
      'pricePerKg': pricePerKg,
      'weightGrams': weightGrams,
      'customerName': customerName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      productIcon: map['productIcon'],
      pricePerKg: map['pricePerKg'],
      weightGrams: map['weightGrams'],
      customerName: map['customerName'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
