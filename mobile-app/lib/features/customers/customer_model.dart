import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final DateTime createdAt;

  Customer({
    String? id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
