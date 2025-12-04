import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neo_theme.dart';

/// Animated circular weight gauge with LCD display
class AnimatedWeightGauge extends StatefulWidget {
  final double weight;
  final double maxWeight;
  final bool isStable;
  final String unit;
  final double size;

  const AnimatedWeightGauge({
    super.key,
    required this.weight,
    this.maxWeight = 5000,
    this.isStable = false,
    this.unit = 'g',
    this.size = 280,
  });

  @override
  State<AnimatedWeightGauge> createState() => _AnimatedWeightGaugeState();
}

class _AnimatedWeightGaugeState extends State<AnimatedWeightGauge>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  double _previousWeight = 0;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedWeightGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weight != widget.weight) {
      _animateToWeight(widget.weight);
    }
  }

  void _animateToWeight(double newWeight) {
    _progressAnimation = Tween<double>(
      begin: _previousWeight / widget.maxWeight,
      end: newWeight / widget.maxWeight,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    _progressController.forward(from: 0);
    _previousWeight = newWeight;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor =
        widget.isStable ? NeoColors.stable : NeoColors.warningGradient[0];

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_progressAnimation, _pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow effect
              if (!widget.isStable)
                Container(
                  width: widget.size + 20,
                  height: widget.size + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withValues(
                            alpha: _glowAnimation.value * 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

              // Outer raised circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: _buildOuterDecoration(isDark),
              ),

              // Progress arc
              SizedBox(
                width: widget.size - 35,
                height: widget.size - 35,
                child: CustomPaint(
                  painter: _AnimatedGaugeArcPainter(
                    progress: _progressAnimation.value.clamp(0.0, 1.0),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : NeoColors.lightShadowDark.withValues(alpha: 0.25),
                    progressColor: progressColor,
                    strokeWidth: 14,
                    isDark: isDark,
                  ),
                ),
              ),

              // Inner circle with LCD display
              Transform.scale(
                scale:
                    widget.isStable ? 1.0 : _pulseAnimation.value * 0.02 + 0.98,
                child: Container(
                  width: widget.size - 75,
                  height: widget.size - 75,
                  decoration: _buildInnerDecoration(isDark),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LCD Weight Display
                      _buildLCDDisplay(isDark),
                      const SizedBox(height: 12),
                      // Stability indicator
                      _buildStabilityBadge(isDark, progressColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _buildOuterDecoration(bool isDark) {
    final shadowDark =
        isDark ? const Color(0xFF15151F) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF404055) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF2A2A3C) : NeoColors.lightSurface;

    return BoxDecoration(
      shape: BoxShape.circle,
      color: bgColor,
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.8 : 0.5),
          offset: const Offset(10, 10),
          blurRadius: 25,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.08 : 0.9),
          offset: const Offset(-10, -10),
          blurRadius: 25,
          spreadRadius: 2,
        ),
      ],
    );
  }

  BoxDecoration _buildInnerDecoration(bool isDark) {
    final shadowDark =
        isDark ? const Color(0xFF15151F) : NeoColors.lightShadowDark;
    final bgColor = isDark ? const Color(0xFF252535) : NeoColors.lightSurface;

    return BoxDecoration(
      shape: BoxShape.circle,
      color: bgColor,
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: 0.4),
          offset: const Offset(5, 5),
          blurRadius: 15,
          spreadRadius: -3,
        ),
      ],
    );
  }

  Widget _buildLCDDisplay(bool isDark) {
    final lcdBg = isDark ? const Color(0xFF1A1A24) : const Color(0xFFD8E8D8);
    final lcdText = isDark ? const Color(0xFF00FF88) : const Color(0xFF1B5E20);
    final lcdBorder =
        isDark ? const Color(0xFF3A3A4A) : const Color(0xFFB0C8B0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: lcdBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: lcdBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          if (isDark)
            BoxShadow(
              color: lcdText.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.weight.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: lcdText,
              letterSpacing: 3,
              shadows: isDark
                  ? [
                      Shadow(
                        color: lcdText.withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          Text(
            widget.unit,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: lcdText.withValues(alpha: 0.7),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityBadge(bool isDark, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: widget.isStable
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isStable ? Icons.check_circle : Icons.sync,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            widget.isStable ? 'STABLE' : 'MEASURING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated gauge arc
class _AnimatedGaugeArcPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;
  final bool isDark;

  _AnimatedGaugeArcPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 14,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = 135 * math.pi / 180;
    const sweepAngle = 270 * math.pi / 180;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Gradient progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle * progress,
        colors: [
          progressColor.withValues(alpha: 0.6),
          progressColor,
          progressColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
          rect, startAngle, sweepAngle * progress, false, progressPaint);

      // Glowing endpoint
      final angle = startAngle + sweepAngle * progress;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Glow
      canvas.drawCircle(
        dotCenter,
        strokeWidth / 2 + 6,
        Paint()
          ..color = progressColor.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // White highlight
      canvas.drawCircle(
        dotCenter,
        strokeWidth / 2 + 2,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );

      // Colored center
      canvas.drawCircle(
        dotCenter,
        strokeWidth / 2 - 2,
        Paint()..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedGaugeArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
