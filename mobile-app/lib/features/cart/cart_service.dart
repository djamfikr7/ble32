import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_model.dart';

class CartService extends StateNotifier<List<CartItem>> {
  CartService() : super([]);

  void addItem(CartItem item) {
    state = [...state, item];
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearCart() {
    state = [];
  }

  void updateItemWeight(String id, double newWeight) {
    state = [
      for (final item in state)
        if (item.id == id)
          CartItem(
            id: item.id,
            productId: item.productId,
            productName: item.productName,
            productIcon: item.productIcon,
            pricePerKg: item.pricePerKg,
            weightGrams: newWeight,
            customerName: item.customerName,
            createdAt: item.createdAt,
          )
        else
          item
    ];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount => state.length;
}

final cartServiceProvider =
    StateNotifierProvider<CartService, List<CartItem>>((ref) {
  return CartService();
});

// Computed providers for convenience
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartServiceProvider);
  return items.fold(0, (sum, item) => sum + item.totalPrice);
});

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartServiceProvider).length;
});
