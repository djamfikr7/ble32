import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'customer_model.dart';

class CustomerService extends StateNotifier<List<Customer>> {
  CustomerService() : super([]) {
    _init();
  }

  late Box _box;

  Future<void> _init() async {
    _box = await Hive.openBox('customers');
    final customers = _box.values.map((e) {
      return Customer.fromMap(Map<String, dynamic>.from(e));
    }).toList();
    // Sort by name
    customers.sort((a, b) => a.name.compareTo(b.name));
    state = customers;
  }

  Future<void> addCustomer(Customer customer) async {
    await _box.put(customer.id, customer.toMap());
    state = [...state, customer]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> updateCustomer(Customer customer) async {
    await _box.put(customer.id, customer.toMap());
    state = [
      for (final c in state)
        if (c.id == customer.id) customer else c
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> deleteCustomer(String id) async {
    await _box.delete(id);
    state = state.where((c) => c.id != id).toList();
  }
}

final customerServiceProvider =
    StateNotifierProvider<CustomerService, List<Customer>>((ref) {
  return CustomerService();
});
