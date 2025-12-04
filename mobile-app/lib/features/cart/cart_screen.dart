import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/neo_theme.dart';
import '../../core/widgets/neo_widgets.dart';
import 'cart_model.dart';
import 'cart_service.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartItems = ref.watch(cartServiceProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor:
          isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : NeoColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmClearCart(context, ref),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(isDark)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCartItemCard(
                            context, ref, isDark, cartItems[index]),
                      );
                    },
                  ),
                ),
                _buildTotalSection(context, ref, isDark, cartTotal),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white54 : NeoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products from the scale screen',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : NeoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
      BuildContext context, WidgetRef ref, bool isDark, CartItem item) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Product Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: NeoColors.primaryGradient
                    .map((c) => c.withValues(alpha: 0.15))
                    .toList(),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.productIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : NeoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.weightGrams.toStringAsFixed(0)}g @ \$${item.pricePerKg.toStringAsFixed(2)}/kg',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : NeoColors.textSecondary,
                  ),
                ),
                if (item.customerName != null)
                  Text(
                    'Customer: ${item.customerName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : NeoColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Price & Delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: NeoColors.successGradient[0],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    ref.read(cartServiceProvider.notifier).removeItem(item.id),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(
      BuildContext context, WidgetRef ref, bool isDark, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NeoColors.darkSurface : NeoColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : NeoColors.textPrimary,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: NeoColors.successGradient,
                  ).createShader(bounds),
                  child: Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    gradient: NeoColors.successGradient,
                    onPressed: () => _checkout(context, ref),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Checkout'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeoButton(
                    gradient: NeoColors.blueGradient,
                    onPressed: () => _printReceipt(context, ref),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Print'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartServiceProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _checkout(BuildContext context, WidgetRef ref) {
    ref.read(cartServiceProvider.notifier).clearCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction completed!'),
        backgroundColor: NeoColors.successGradient[0],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  void _printReceipt(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Printing receipt...'),
        backgroundColor: NeoColors.blueGradient[0],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
