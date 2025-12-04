import 'package:flutter/material.dart';
import '../theme/neo_theme.dart';

/// Animated Neomorphism Card with press effect
class NeoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool animate;

  const NeoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.animate = true,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shadowDark =
        isDark ? const Color(0xFF15151F) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF404055) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF2A2A3C) : NeoColors.lightSurface;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.animate ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: widget.margin ?? const EdgeInsets.all(8),
              padding: widget.padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: _isPressed
                    ? [
                        // Pressed - inset shadow effect
                        BoxShadow(
                          color: shadowDark.withValues(alpha: 0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 5,
                        ),
                      ]
                    : [
                        // Normal - raised shadow effect
                        BoxShadow(
                          color:
                              shadowDark.withValues(alpha: isDark ? 0.7 : 0.5),
                          offset: const Offset(6, 6),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: shadowLight.withValues(
                              alpha: isDark ? 0.06 : 0.85),
                          offset: const Offset(-6, -6),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Animated gradient button with glow effect
class NeoButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color>? gradient;
  final double borderRadius;
  final EdgeInsets? padding;
  final bool isLoading;
  final double? width;

  const NeoButton({
    super.key,
    this.onPressed,
    required this.child,
    this.gradient,
    this.borderRadius = 16,
    this.padding,
    this.isLoading = false,
    this.width,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradient ?? NeoColors.primaryGradient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: colors.last
                        .withValues(alpha: 0.5 * _glowAnimation.value),
                    offset: Offset(0, 6 * _glowAnimation.value),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 1,
                  ),
                  if (isDark)
                    BoxShadow(
                      color: colors.first
                          .withValues(alpha: 0.3 * _glowAnimation.value),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      child: widget.child,
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated neomorphism icon button with press effect
class NeoIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final List<Color>? gradient;

  const NeoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 54,
    this.iconColor,
    this.gradient,
  });

  @override
  State<NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<NeoIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasGradient = widget.gradient != null;

    final shadowDark =
        isDark ? const Color(0xFF15151F) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF404055) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF2A2A3C) : NeoColors.lightSurface;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: widget.size,
              height: widget.size,
              decoration: hasGradient
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradient!,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient!.last
                              .withValues(alpha: _isPressed ? 0.3 : 0.5),
                          offset: const Offset(0, 4),
                          blurRadius: _isPressed ? 8 : 15,
                        ),
                      ],
                    )
                  : BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      boxShadow: _isPressed
                          ? [
                              BoxShadow(
                                color: shadowDark.withValues(alpha: 0.25),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: shadowDark.withValues(
                                    alpha: isDark ? 0.65 : 0.45),
                                offset: const Offset(5, 5),
                                blurRadius: 12,
                              ),
                              BoxShadow(
                                color: shadowLight.withValues(
                                    alpha: isDark ? 0.05 : 0.8),
                                offset: const Offset(-5, -5),
                                blurRadius: 12,
                              ),
                            ],
                    ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.iconColor ??
                      (hasGradient
                          ? Colors.white
                          : (isDark ? Colors.white70 : NeoColors.textPrimary)),
                  size: widget.size * 0.45,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Stat card for dashboard
class NeoStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final List<Color>? iconGradient;

  const NeoStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = iconGradient ?? NeoColors.primaryGradient;

    return NeoCard(
      onTap: null,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors.map((c) => c.withValues(alpha: 0.2)).toList(),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor ?? colors.first,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NeoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : NeoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge
class NeoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSmall;
  final bool glow;

  const NeoBadge({
    super.key,
    required this.label,
    required this.color,
    this.isSmall = false,
    this.glow = false,
  });

  factory NeoBadge.success({String label = 'EN STOCK', bool glow = false}) =>
      NeoBadge(label: label, color: NeoColors.badgeSuccess, glow: glow);
  factory NeoBadge.gold({String label = 'GOLD'}) =>
      NeoBadge(label: label, color: NeoColors.badgeGold);
  factory NeoBadge.connected({String label = 'CONNECTED'}) =>
      NeoBadge(label: label, color: NeoColors.connected, glow: true);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
