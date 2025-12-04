import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/neo_theme.dart';
import 'core/services/auth_service.dart';
import 'features/scale/scale_screen.dart';
import 'features/products/products_screen.dart';
import 'features/history/history_screen.dart';
import 'features/transfer/transfer_ownership_screen.dart';
import 'features/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(const ProviderScope(child: BLEScaleApp()));
}

class BLEScaleApp extends ConsumerWidget {
  const BLEScaleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return MaterialApp(
      title: 'BLE Scale',
      debugShowCheckedModeBanner: false,
      theme: NeoTheme.lightTheme,
      darkTheme: NeoTheme.darkTheme,
      themeMode: themeMode,
      home: isAuthenticated ? const MainNavigation() : const AuthScreen(),
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          ScaleScreen(),
          ProductsScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? NeoColors.darkSurface : NeoColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? NeoColors.darkShadowDark : NeoColors.lightShadowDark)
                    .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.scale, 'Scale', isDark),
              _buildNavItem(1, Icons.inventory_2, 'Products', isDark),
              _buildNavItem(2, Icons.history, 'History', isDark),
              _buildNavItem(3, Icons.settings, 'Settings', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white54 : NeoColors.textSecondary),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Settings Screen with theme toggle
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor:
          isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NeoColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Theme toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: NeoDecoration.raised(isDark: isDark),
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: NeoColors.primaryGradient[0],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : NeoColors.textPrimary,
                            ),
                          ),
                          Text(
                            isDark ? 'Currently enabled' : 'Currently disabled',
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
                    Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).state =
                            value ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeThumbColor: NeoColors.primaryGradient[0],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Language setting
              Container(
                padding: const EdgeInsets.all(16),
                decoration: NeoDecoration.raised(isDark: isDark),
                child: Row(
                  children: [
                    Icon(Icons.language, color: NeoColors.tealGradient[0]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Language',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : NeoColors.textPrimary,
                            ),
                          ),
                          Text(
                            'English',
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
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white54 : NeoColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // About
              Container(
                padding: const EdgeInsets.all(16),
                decoration: NeoDecoration.raised(isDark: isDark),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: NeoColors.blueGradient[0]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : NeoColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Version 1.0.0',
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
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white54 : NeoColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Transfer Ownership
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransferOwnershipScreen(
                        deviceMac: 'AA:BB:CC:DD:EE:FF',
                        deviceName: 'BLE-Scale',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: NeoDecoration.raised(isDark: isDark),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz,
                          color: NeoColors.warningGradient[0]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transfer Ownership',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : NeoColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Send or receive scale',
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
                      Icon(
                        Icons.chevron_right,
                        color:
                            isDark ? Colors.white54 : NeoColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
