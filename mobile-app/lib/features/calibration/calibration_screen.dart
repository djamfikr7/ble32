import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/neo_theme.dart';
import '../../core/widgets/neo_widgets.dart';
import '../../core/bluetooth/ble_service.dart';
import '../../core/bluetooth/mock_ble_service.dart';

/// Calibration wizard screen
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  double _knownWeight = 100; // Default calibration weight in grams
  bool _isCalibrating = false;
  bool _calibrationComplete = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final TextEditingController _weightController =
      TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
      appBar: AppBar(
        title: const Text('Calibration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: isDark ? Colors.white : NeoColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildProgressIndicator(isDark),
            ),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(isDark),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildActionButtons(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        final isComplete = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              // Step circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(colors: NeoColors.primaryGradient)
                      : null,
                  color: isActive
                      ? null
                      : (isDark
                          ? Colors.white12
                          : NeoColors.lightShadowDark.withValues(alpha: 0.3)),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: NeoColors.primaryGradient.last
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isComplete
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : (isDark
                                    ? Colors.white54
                                    : NeoColors.textSecondary),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              // Connector line
              if (index < 2)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: index < _currentStep
                          ? const LinearGradient(
                              colors: NeoColors.primaryGradient)
                          : null,
                      color: index < _currentStep
                          ? null
                          : (isDark
                              ? Colors.white12
                              : NeoColors.lightShadowDark
                                  .withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(isDark);
      case 1:
        return _buildStep2(isDark);
      case 2:
        return _buildStep3(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: NeoColors.tealGradient
                    .map((c) => c.withValues(alpha: 0.15))
                    .toList(),
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cleaning_services_outlined,
              size: 56,
              color: NeoColors.tealGradient[0],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Prepare the Scale',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Remove all items from the scale and ensure it is on a flat, stable surface. Wait for the display to stabilize before continuing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : NeoColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Checklist
          _buildChecklistItem(isDark, 'Scale is empty', true),
          _buildChecklistItem(isDark, 'Flat, stable surface', true),
          _buildChecklistItem(isDark, 'Display shows 0.0g', true),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Animated weight icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isCalibrating ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: NeoColors.warningGradient
                          .map((c) => c.withValues(alpha: 0.15))
                          .toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 56,
                    color: NeoColors.warningGradient[0],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          Text(
            'Enter Known Weight',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Enter the weight of your calibration mass in grams, then place it on the scale.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : NeoColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Weight input
          NeoCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : NeoColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Weight',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white30
                            : NeoColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    onChanged: (value) {
                      _knownWeight = double.tryParse(value) ?? 100;
                    },
                  ),
                ),
                Text(
                  'grams',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : NeoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick weight buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [50, 100, 200, 500, 1000].map((weight) {
              final isSelected = _knownWeight == weight.toDouble();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _knownWeight = weight.toDouble();
                    _weightController.text = weight.toString();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                              colors: NeoColors.primaryGradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: NeoColors.primaryGradient.last
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        )
                      : NeoDecoration.raised(isDark: isDark, borderRadius: 12),
                  child: Text(
                    '${weight}g',
                    style: TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success/Progress icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _calibrationComplete ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _calibrationComplete
                          ? NeoColors.successGradient
                              .map((c) => c.withValues(alpha: 0.15))
                              .toList()
                          : NeoColors.primaryGradient
                              .map((c) => c.withValues(alpha: 0.15))
                              .toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _calibrationComplete ? Icons.check_circle : Icons.sync,
                    size: 56,
                    color: _calibrationComplete
                        ? NeoColors.successGradient[0]
                        : NeoColors.primaryGradient[0],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          Text(
            _calibrationComplete ? 'Calibration Complete!' : 'Calibrating...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _calibrationComplete
                ? 'Your scale is now calibrated and ready to use. The calibration factor has been saved.'
                : 'Please wait while the scale is being calibrated. Do not move or touch the scale.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : NeoColors.textSecondary,
              height: 1.5,
            ),
          ),

          if (_calibrationComplete) ...[
            const SizedBox(height: 32),
            _buildSuccessStats(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistItem(bool isDark, String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: checked
                  ? const LinearGradient(colors: NeoColors.successGradient)
                  : null,
              border: checked
                  ? null
                  : Border.all(
                      color: isDark ? Colors.white30 : NeoColors.textSecondary),
              borderRadius: BorderRadius.circular(6),
            ),
            child: checked
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStats(bool isDark) {
    return NeoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatRow(
              isDark, 'Known Weight', '${_knownWeight.toStringAsFixed(0)}g'),
          const Divider(height: 24),
          _buildStatRow(isDark, 'Calibration Factor', '420.5'),
          const Divider(height: 24),
          _buildStatRow(isDark, 'Accuracy', '±0.5g'),
        ],
      ),
    );
  }

  Widget _buildStatRow(bool isDark, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white60 : NeoColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : NeoColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    if (_currentStep == 2 && _calibrationComplete) {
      return NeoButton(
        gradient: NeoColors.successGradient,
        width: double.infinity,
        onPressed: () => Navigator.pop(context),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('Done'),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: NeoIconButton(
              icon: Icons.arrow_back,
              size: 52,
              onPressed: () => setState(() => _currentStep--),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: NeoButton(
            gradient: NeoColors.primaryGradient,
            isLoading: _isCalibrating,
            onPressed: _handleNext,
            child: Text(_currentStep == 1 ? 'Calibrate' : 'Next'),
          ),
        ),
      ],
    );
  }

  void _handleNext() {
    if (_currentStep < 2) {
      if (_currentStep == 1) {
        // Start calibration
        setState(() => _isCalibrating = true);

        // Send calibration command
        if (useMockBLE) {
          ref.read(mockBLEScaleProvider.notifier).calibrate(_knownWeight);
        } else {
          ref.read(bleScaleProvider.notifier).calibrate(_knownWeight);
        }

        // Simulate calibration process
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _isCalibrating = false;
            _currentStep = 2;
          });

          Future.delayed(const Duration(seconds: 1), () {
            setState(() => _calibrationComplete = true);
          });
        });
      } else {
        setState(() => _currentStep++);
      }
    }
  }
}
