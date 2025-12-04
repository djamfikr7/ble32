import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/neo_theme.dart';
import '../../core/widgets/neo_widgets.dart';

/// Transaction History Screen with charts
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  String _selectedPeriod = 'week';

  // Demo transactions
  final List<Transaction> _transactions = [
    Transaction(
      id: 'TX001',
      product: 'Apples',
      icon: '🍎',
      weight: 1250,
      price: 4.38,
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Transaction(
      id: 'TX002',
      product: 'Oranges',
      icon: '🍊',
      weight: 800,
      price: 3.20,
      date: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Transaction(
      id: 'TX003',
      product: 'Bananas',
      icon: '🍌',
      weight: 1500,
      price: 4.20,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: 'TX004',
      product: 'Grapes',
      icon: '🍇',
      weight: 650,
      price: 4.23,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: 'TX005',
      product: 'Lemons',
      icon: '🍋',
      weight: 400,
      price: 2.00,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
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
                        'History',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NeoColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Transaction records',
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

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsRow(isDark),
                ),
              ),

              // Period Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildPeriodSelector(isDark),
                ),
              ),

              // Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildChart(isDark),
                ),
              ),

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NeoColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: NeoColors.primaryGradient[0],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildTransactionCard(_transactions[index], isDark),
                    childCount: _transactions.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark,
            icon: Icons.receipt_long,
            value: '24',
            label: 'Transactions',
            colors: NeoColors.blueGradient,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            isDark,
            icon: Icons.scale,
            value: '18.5 kg',
            label: 'Total Weight',
            colors: NeoColors.tealGradient,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            isDark,
            icon: Icons.attach_money,
            value: '\$86',
            label: 'Revenue',
            colors: NeoColors.successGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDark, {
    required IconData icon,
    required String value,
    required String label,
    required List<Color> colors,
  }) {
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF32324A) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF252536) : NeoColors.lightSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: colors.map((c) => c.withValues(alpha: 0.2)).toList()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors[0], size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : NeoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final periods = ['day', 'week', 'month', 'year'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return GestureDetector(
          onTap: () => setState(() => _selectedPeriod = period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: isSelected
                ? BoxDecoration(
                    gradient:
                        const LinearGradient(colors: NeoColors.primaryGradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: NeoColors.primaryGradient.last
                            .withValues(alpha: 0.4),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  )
                : NeoDecoration.raised(isDark: isDark, borderRadius: 12),
            child: Text(
              period[0].toUpperCase() + period.substring(1),
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
    );
  }

  Widget _buildChart(bool isDark) {
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF32324A) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF252536) : NeoColors.lightSurface;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.4),
            offset: const Offset(5, 5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.04 : 0.7),
            offset: const Offset(-5, -5),
            blurRadius: 14,
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white12 : Colors.black12,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];
                  return Text(
                    days[value.toInt() % 7],
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : NeoColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 30),
                FlSpot(1, 45),
                FlSpot(2, 35),
                FlSpot(3, 60),
                FlSpot(4, 50),
                FlSpot(5, 70),
                FlSpot(6, 55),
              ],
              isCurved: true,
              gradient: const LinearGradient(colors: NeoColors.primaryGradient),
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: NeoColors.primaryGradient
                      .map((c) => c.withValues(alpha: 0.2))
                      .toList(),
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx, bool isDark) {
    return NeoCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => _showTransactionDetails(tx),
      child: Row(
        children: [
          // Product icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: NeoColors.primaryGradient
                    .map((c) => c.withValues(alpha: 0.15))
                    .toList(),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(tx.icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.product,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : NeoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(tx.weight / 1000).toStringAsFixed(2)} kg • ${_formatDate(tx.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : NeoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Price
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: NeoColors.successGradient,
            ).createShader(bounds),
            child: Text(
              '\$${tx.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  void _showTransactionDetails(Transaction tx) {
    // TODO: Show transaction details sheet
  }
}

class Transaction {
  final String id;
  final String product;
  final String icon;
  final double weight;
  final double price;
  final DateTime date;

  Transaction({
    required this.id,
    required this.product,
    required this.icon,
    required this.weight,
    required this.price,
    required this.date,
  });
}
