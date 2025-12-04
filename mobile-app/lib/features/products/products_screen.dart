import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/neo_theme.dart';
import '../../core/widgets/neo_widgets.dart';

/// Products management screen
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Product> _products = [
    Product(
        id: '1',
        name: 'Apples',
        price: 3.50,
        unit: 'kg',
        category: 'Fruits',
        icon: '🍎',
        color: const Color(0xFFFF6B6B)),
    Product(
        id: '2',
        name: 'Oranges',
        price: 4.00,
        unit: 'kg',
        category: 'Fruits',
        icon: '🍊',
        color: const Color(0xFFFF9800)),
    Product(
        id: '3',
        name: 'Bananas',
        price: 2.80,
        unit: 'kg',
        category: 'Fruits',
        icon: '🍌',
        color: const Color(0xFFFBC02D)),
    Product(
        id: '4',
        name: 'Grapes',
        price: 6.50,
        unit: 'kg',
        category: 'Fruits',
        icon: '🍇',
        color: const Color(0xFF7B1FA2)),
    Product(
        id: '5',
        name: 'Carrots',
        price: 2.20,
        unit: 'kg',
        category: 'Vegetables',
        icon: '🥕',
        color: const Color(0xFFFF7043)),
    Product(
        id: '6',
        name: 'Tomatoes',
        price: 3.00,
        unit: 'kg',
        category: 'Vegetables',
        icon: '🍅',
        color: const Color(0xFFE53935)),
    Product(
        id: '7',
        name: 'Potatoes',
        price: 1.80,
        unit: 'kg',
        category: 'Vegetables',
        icon: '🥔',
        color: const Color(0xFF8D6E63)),
    Product(
        id: '8',
        name: 'Lettuce',
        price: 2.50,
        unit: 'kg',
        category: 'Vegetables',
        icon: '🥬',
        color: const Color(0xFF66BB6A)),
  ];

  List<String> get _categories =>
      ['All', ..._products.map((p) => p.category).toSet()];

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: NeoColors.primaryGradient),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: NeoColors.primaryGradient.last.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddProductDialog(isDark),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NeoColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_products.length} items',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? Colors.white60 : NeoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(isDark),
                ),
              ),

              // Category chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _buildCategoryChips(isDark),
                ),
              ),

              // Products grid
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildProductCard(_filteredProducts[index], isDark),
                    childCount: _filteredProducts.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF32324A) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF252536) : NeoColors.lightSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.5 : 0.3),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.03 : 0.6),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: isDark ? Colors.white : NeoColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(
              color: isDark ? Colors.white38 : NeoColors.textSecondary),
          border: InputBorder.none,
          icon: Icon(Icons.search,
              color: isDark ? Colors.white54 : NeoColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                          colors: NeoColors.primaryGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: NeoColors.primaryGradient.last
                              .withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    )
                  : NeoDecoration.raised(
                      isDark: isDark, borderRadius: 12, intensity: 0.7),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : NeoColors.textPrimary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDark) {
    return NeoCard(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(14),
      onTap: () => _showEditProductDialog(product, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child:
                      Text(product.icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white54 : NeoColors.textSecondary,
                  size: 20,
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    setState(() => _products.remove(product));
                  }
                },
              ),
            ],
          ),
          const Spacer(),
          // Name
          Text(
            product.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Category
          Text(
            product.category,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : NeoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [product.color, product.color.withValues(alpha: 0.7)],
                ).createShader(bounds),
                child: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '/${product.unit}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : NeoColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(bool isDark) {
    // TODO: Implement add product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add product dialog'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditProductDialog(Product product, bool isDark) {
    // TODO: Implement edit product dialog
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String unit;
  final String category;
  final String icon;
  final Color color;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.category,
    required this.icon,
    required this.color,
  });
}
