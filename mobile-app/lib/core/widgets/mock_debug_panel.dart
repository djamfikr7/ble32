import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bluetooth/mock_ble_service.dart';
import '../bluetooth/ble_service.dart';
import '../theme/neo_theme.dart';

/// Debug panel for testing mock BLE scale
/// Shows simulation controls when useMockBLE is true
class MockBLEDebugPanel extends ConsumerStatefulWidget {
  const MockBLEDebugPanel({super.key});

  @override
  ConsumerState<MockBLEDebugPanel> createState() => _MockBLEDebugPanelState();
}

class _MockBLEDebugPanelState extends ConsumerState<MockBLEDebugPanel> {
  double _sliderWeight = 0;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!useMockBLE) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(mockBLEScaleProvider);

    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expand/Collapse button
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isExpanded
                      ? NeoColors.errorGradient
                      : NeoColors.tealGradient,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isExpanded
                            ? NeoColors.errorGradient[0]
                            : NeoColors.tealGradient[0])
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded ? Icons.close : Icons.bug_report,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isExpanded ? 'Close' : 'Mock BLE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panel content
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.settings_input_antenna,
                        color: NeoColors.tealGradient[0],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mock BLE Debug',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NeoColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Connection status
                  _buildStatusRow(
                    'Status',
                    state.connectionState.name.toUpperCase(),
                    state.connectionState == BLEConnectionState.connected
                        ? Colors.green
                        : Colors.orange,
                    isDark,
                  ),

                  const SizedBox(height: 8),

                  // Current weight display
                  _buildStatusRow(
                    'Weight',
                    '${state.weightData.weight.toStringAsFixed(1)} g',
                    NeoColors.primaryGradient[0],
                    isDark,
                  ),

                  const SizedBox(height: 8),

                  // Stability
                  _buildStatusRow(
                    'Stable',
                    state.weightData.isStable ? 'YES' : 'NO',
                    state.weightData.isStable ? Colors.green : Colors.red,
                    isDark,
                  ),

                  const Divider(height: 24),

                  // Weight slider
                  Text(
                    'Simulate Weight: ${_sliderWeight.toStringAsFixed(0)}g',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : NeoColors.textSecondary,
                    ),
                  ),
                  Slider(
                    value: _sliderWeight,
                    min: 0,
                    max: 5000,
                    divisions: 100,
                    activeColor: NeoColors.primaryGradient[0],
                    onChanged: (value) {
                      setState(() => _sliderWeight = value);
                      ref
                          .read(mockBLEScaleProvider.notifier)
                          .simulateWeight(value);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Quick weight buttons
                  Row(
                    children: [
                      _buildQuickButton('0g', 0, isDark),
                      _buildQuickButton('100g', 100, isDark),
                      _buildQuickButton('500g', 500, isDark),
                      _buildQuickButton('1kg', 1000, isDark),
                      _buildQuickButton('5kg', 5000, isDark),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Connect',
                          Icons.bluetooth_connected,
                          NeoColors.successGradient,
                          () async {
                            final notifier =
                                ref.read(mockBLEScaleProvider.notifier);
                            await notifier.startScan();
                            if (state.scannedDevices.isNotEmpty) {
                              await notifier
                                  .connect(state.scannedDevices.first);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Disconnect',
                          Icons.bluetooth_disabled,
                          NeoColors.errorGradient,
                          () => ref
                              .read(mockBLEScaleProvider.notifier)
                              .disconnect(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Tare',
                          Icons.restart_alt,
                          NeoColors.blueGradient,
                          () => ref.read(mockBLEScaleProvider.notifier).tare(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Fluctuate',
                          Icons.waves,
                          NeoColors.warningGradient,
                          () => ref
                              .read(mockBLEScaleProvider.notifier)
                              .addFluctuation(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : NeoColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, double weight, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _sliderWeight = weight);
          ref.read(mockBLEScaleProvider.notifier).simulateWeight(weight);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE8E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : NeoColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    List<Color> gradient,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
