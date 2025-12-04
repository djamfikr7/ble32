import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/neo_theme.dart';
import '../../core/widgets/neo_widgets.dart';
import '../../core/widgets/weight_gauge.dart';
import '../../core/widgets/mock_debug_panel.dart';
import '../../core/bluetooth/ble_service.dart';
import '../../core/bluetooth/mock_ble_service.dart';
import '../customers/customer_model.dart';
import '../customers/customer_list_screen.dart';
import '../cart/cart_model.dart';
import '../cart/cart_service.dart';
import '../cart/cart_screen.dart';

class ScaleScreen extends ConsumerStatefulWidget {
  const ScaleScreen({super.key});

  @override
  ConsumerState<ScaleScreen> createState() => _ScaleScreenState();
}

class _ScaleScreenState extends ConsumerState<ScaleScreen>
    with TickerProviderStateMixin {
  String? _selectedProductId;
  Customer? selectedCustomer;
  late AnimationController _headerAnimController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  // Demo products
  final List<Product> _products = [
    Product(
        id: '1',
        name: 'Apples',
        price: 3.50,
        unit: 'kg',
        icon: '🍎',
        colors: [const Color(0xFFFF6B6B), const Color(0xFFEE5A5A)]),
    Product(
        id: '2',
        name: 'Oranges',
        price: 4.00,
        unit: 'kg',
        icon: '🍊',
        colors: [const Color(0xFFFFB74D), const Color(0xFFFF9800)]),
    Product(
        id: '3',
        name: 'Bananas',
        price: 2.80,
        unit: 'kg',
        icon: '🍌',
        colors: [const Color(0xFFFFEB3B), const Color(0xFFFBC02D)]),
    Product(
        id: '4',
        name: 'Grapes',
        price: 6.50,
        unit: 'kg',
        icon: '🍇',
        colors: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)]),
    Product(
        id: '5',
        name: 'Lemons',
        price: 5.00,
        unit: 'kg',
        icon: '🍋',
        colors: [const Color(0xFFC0CA33), const Color(0xFFAFB42B)]),
    Product(
        id: '6',
        name: 'Tomatoes',
        price: 3.00,
        unit: 'kg',
        icon: '🍅',
        colors: [const Color(0xFFE53935), const Color(0xFFD32F2F)]),
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
          parent: _headerAnimController, curve: Curves.easeOutCubic),
    );
    _headerFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bleState = ref.watch(bleStateProvider);
    final weight = bleState.weightData.weight;
    final isStable = bleState.weightData.isStable;
    final isConnected =
        bleState.connectionState == BLEConnectionState.connected;

    final selectedProduct = _selectedProductId != null
        ? _products.firstWhere((p) => p.id == _selectedProductId)
        : null;
    final totalPrice =
        selectedProduct != null ? (weight / 1000) * selectedProduct.price : 0.0;

    return Scaffold(
      backgroundColor:
          isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Header
                  _buildAnimatedHeader(
                      isDark, isConnected, bleState.weightData.batteryLevel),

                  const SizedBox(height: 28),

                  // Weight Gauge - Centered
                  Center(
                    child: AnimatedWeightGauge(
                      weight: weight,
                      maxWeight: 5000,
                      isStable: isStable,
                      unit: 'g',
                      size: 290,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Control Buttons Row
                  _buildControlButtons(isDark),

                  const SizedBox(height: 28),

                  // Customer Selection
                  _buildCustomerSection(isDark),

                  const SizedBox(height: 28),

                  // Product Selection
                  _buildProductSection(isDark),

                  const SizedBox(height: 20),

                  // Price Display
                  if (selectedProduct != null)
                    _buildPriceCard(
                        isDark, selectedProduct, weight, totalPrice),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(isDark, totalPrice),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Mock BLE Debug Panel (only shows when useMockBLE is true)
          const MockBLEDebugPanel(),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NeoColors.textPrimary,
                ),
              ),
              if (selectedCustomer != null)
                GestureDetector(
                  onTap: () => setState(() => selectedCustomer = null),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: NeoColors.primaryGradient[0],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push<Customer>(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerListScreen(isSelectionMode: true),
              ),
            );
            if (result != null) {
              setState(() => selectedCustomer = result);
            }
          },
          child: NeoCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedCustomer != null
                          ? NeoColors.blueGradient
                          : [
                              isDark ? Colors.white10 : Colors.grey.shade200,
                              isDark ? Colors.white10 : Colors.grey.shade200,
                            ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedCustomer != null
                        ? Icons.person
                        : Icons.person_add_alt_1,
                    color: selectedCustomer != null
                        ? Colors.white
                        : (isDark ? Colors.white54 : NeoColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCustomer?.name ?? 'Select Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : NeoColors.textPrimary,
                        ),
                      ),
                      if (selectedCustomer != null)
                        Text(
                          selectedCustomer!.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : NeoColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white54 : NeoColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader(bool isDark, bool isConnected, int batteryLevel) {
    return AnimatedBuilder(
      animation: _headerAnimController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Opacity(
            opacity: _headerFadeAnimation.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Scale',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NeoColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? NeoColors.connected
                                : NeoColors.disconnected,
                            shape: BoxShape.circle,
                            boxShadow: isConnected
                                ? [
                                    BoxShadow(
                                      color: NeoColors.connected
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white60
                                : NeoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Battery indicator
                    _buildBatteryIndicator(isDark, batteryLevel),
                    const SizedBox(width: 14),
                    // BLE scan button
                    NeoIconButton(
                      icon: Icons.bluetooth_searching,
                      size: 48,
                      gradient: isConnected ? null : NeoColors.blueGradient,
                      onPressed: () => _showConnectionDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBatteryIndicator(bool isDark, int level) {
    final color = level > 20 ? NeoColors.stable : NeoColors.error;
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF32324A) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF252536) : NeoColors.lightSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.4),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.04 : 0.7),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            level > 50
                ? Icons.battery_full
                : level > 20
                    ? Icons.battery_5_bar
                    : Icons.battery_alert,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$level%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tare button
        NeoIconButton(
          icon: Icons.restart_alt,
          size: 58,
          gradient: NeoColors.warningGradient,
          onPressed: () {
            if (useMockBLE) {
              ref.read(mockBLEScaleProvider.notifier).tare();
            } else {
              ref.read(bleScaleProvider.notifier).tare();
            }
          },
        ),
        const SizedBox(width: 28),
        // Calibrate button
        NeoIconButton(
          icon: Icons.tune,
          size: 58,
          onPressed: () => _showCalibrationDialog(),
        ),
        const SizedBox(width: 28),
        // Unit toggle button
        NeoIconButton(
          icon: Icons.swap_horiz,
          size: 58,
          onPressed: () => _cycleUnit(),
        ),
      ],
    );
  }

  Widget _buildProductSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Product',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : NeoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final isSelected = _selectedProductId == product.id;

              return GestureDetector(
                onTap: () => setState(() => _selectedProductId = product.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 85,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            colors: product.colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: product.colors.last.withValues(alpha: 0.5),
                              offset: const Offset(0, 5),
                              blurRadius: 15,
                            ),
                          ],
                        )
                      : NeoDecoration.raised(isDark: isDark, borderRadius: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.icon,
                        style: TextStyle(fontSize: isSelected ? 32 : 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white70
                                  : NeoColors.textPrimary),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(
      bool isDark, Product product, double weight, double totalPrice) {
    return NeoCard(
      animate: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product:',
                style: TextStyle(
                  color: isDark ? Colors.white60 : NeoColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Text(product.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : NeoColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Unit Price:',
                  style: TextStyle(
                      color:
                          isDark ? Colors.white60 : NeoColors.textSecondary)),
              Text(
                '\$${product.price.toStringAsFixed(2)}/${product.unit}',
                style: TextStyle(
                    color: isDark ? Colors.white : NeoColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weight:',
                  style: TextStyle(
                      color:
                          isDark ? Colors.white60 : NeoColors.textSecondary)),
              Text(
                '${(weight / 1000).toStringAsFixed(3)} kg',
                style: TextStyle(
                    color: isDark ? Colors.white : NeoColors.textPrimary),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.white24 : NeoColors.textSecondary)
                        .withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NeoColors.textPrimary,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: product.colors,
                ).createShader(bounds),
                child: Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, double totalPrice) {
    final cartCount = ref.watch(cartCountProvider);
    final selectedProduct = _selectedProductId != null
        ? _products.firstWhere((p) => p.id == _selectedProductId)
        : null;
    final weight = ref.watch(bleStateProvider).weightData.weight;

    return Column(
      children: [
        // Add to Cart button
        NeoButton(
          gradient: NeoColors.primaryGradient,
          width: double.infinity,
          onPressed: selectedProduct != null && weight > 0
              ? () => _addToCart(selectedProduct, weight)
              : null,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('Add to Cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // View Cart button with badge
            Expanded(
              child: NeoButton(
                gradient: NeoColors.successGradient,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart,
                            color: Colors.white, size: 22),
                        if (cartCount > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text('Cart ($cartCount)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Quick Save
            Expanded(
              child: NeoButton(
                gradient: NeoColors.blueGradient,
                onPressed: totalPrice > 0 ? () => _saveTransaction() : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_alt, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text('Quick Save',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addToCart(Product product, double weight) {
    final cartItem = CartItem(
      productId: product.id,
      productName: product.name,
      productIcon: product.icon,
      pricePerKg: product.price,
      weightGrams: weight,
      customerName: selectedCustomer?.name,
    );
    ref.read(cartServiceProvider.notifier).addItem(cartItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        backgroundColor: NeoColors.successGradient[0],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showConnectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const BLEConnectionSheet(),
    );
  }

  void _showCalibrationDialog() {
    // TODO: Implement calibration dialog
  }

  void _cycleUnit() {
    // TODO: Implement unit cycling
  }

  void _saveTransaction() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction saved!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: NeoColors.successGradient[0],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _printReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Printing receipt...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: NeoColors.blueGradient[0],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Product model
class Product {
  final String id;
  final String name;
  final double price;
  final String unit;
  final String icon;
  final List<Color> colors;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.icon,
    required this.colors,
  });
}

/// BLE Connection Bottom Sheet
class BLEConnectionSheet extends ConsumerWidget {
  const BLEConnectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bleState = ref.watch(bleScaleProvider);
    final bleNotifier = ref.read(bleScaleProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white24 : Colors.black26),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connect Scale',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NeoColors.textPrimary,
                ),
              ),
              NeoIconButton(
                icon: bleState.connectionState == BLEConnectionState.scanning
                    ? Icons.stop
                    : Icons.refresh,
                size: 44,
                gradient:
                    bleState.connectionState == BLEConnectionState.scanning
                        ? NeoColors.errorGradient
                        : NeoColors.blueGradient,
                onPressed: () {
                  if (bleState.connectionState == BLEConnectionState.scanning) {
                    bleNotifier.stopScan();
                  } else {
                    bleNotifier.startScan();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (bleState.connectionState == BLEConnectionState.scanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),

          if (bleState.scannedDevices.isEmpty &&
              bleState.connectionState != BLEConnectionState.scanning)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 56,
                    color: isDark ? Colors.white30 : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No devices found',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeoButton(
                    gradient: NeoColors.blueGradient,
                    onPressed: () => bleNotifier.startScan(),
                    child: const Text('Start Scanning'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

          ...bleState.scannedDevices.map((device) => NeoCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () {
                  bleNotifier.connect(device);
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: NeoColors.blueGradient
                              .map((c) => c.withValues(alpha: 0.2))
                              .toList(),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bluetooth,
                        color: NeoColors.blueGradient[0],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.platformName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : NeoColors.textPrimary,
                            ),
                          ),
                          Text(
                            device.remoteId.str,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : NeoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bleState.device?.remoteId == device.remoteId)
                      NeoBadge.connected(),
                  ],
                ),
              )),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
