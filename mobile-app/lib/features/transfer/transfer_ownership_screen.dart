import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../core/theme/neo_theme.dart';
import '../../core/widgets/neo_widgets.dart';

/// P2P Ownership Transfer Screen
/// Allows secure transfer of scale ownership between users
class TransferOwnershipScreen extends ConsumerStatefulWidget {
  final String deviceMac;
  final String deviceName;

  const TransferOwnershipScreen({
    super.key,
    required this.deviceMac,
    required this.deviceName,
  });

  @override
  ConsumerState<TransferOwnershipScreen> createState() =>
      _TransferOwnershipScreenState();
}

class _TransferOwnershipScreenState
    extends ConsumerState<TransferOwnershipScreen>
    with TickerProviderStateMixin {
  bool _isTransferMode = false; // false = initiate, true = receive
  String? _transferCode;
  DateTime? _codeExpiry;
  bool _isLoading = false;
  bool _transferComplete = false;

  final TextEditingController _codeController = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _codeController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
      appBar: AppBar(
        title: const Text('Transfer Ownership'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: isDark ? Colors.white : NeoColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Mode toggle
              if (!_transferComplete) _buildModeToggle(isDark),

              const SizedBox(height: 32),

              // Content based on mode
              if (_transferComplete)
                _buildTransferComplete(isDark)
              else if (_isTransferMode)
                _buildReceiveMode(isDark)
              else
                _buildInitiateMode(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(bool isDark) {
    return NeoCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTransferMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: !_isTransferMode
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                            colors: NeoColors.primaryGradient),
                        borderRadius: BorderRadius.circular(14),
                      )
                    : null,
                child: Text(
                  'Send',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_isTransferMode
                        ? Colors.white
                        : (isDark ? Colors.white60 : NeoColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTransferMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: _isTransferMode
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                            colors: NeoColors.tealGradient),
                        borderRadius: BorderRadius.circular(14),
                      )
                    : null,
                child: Text(
                  'Receive',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isTransferMode
                        ? Colors.white
                        : (isDark ? Colors.white60 : NeoColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiateMode(bool isDark) {
    return Column(
      children: [
        // Icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _transferCode != null ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: NeoColors.primaryGradient
                        .map((c) => c.withValues(alpha: 0.15))
                        .toList(),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _transferCode != null ? Icons.qr_code_2 : Icons.send_outlined,
                  size: 56,
                  color: NeoColors.primaryGradient[0],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        Text(
          _transferCode != null
              ? 'Transfer Code Ready'
              : 'Transfer Scale Ownership',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : NeoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          _transferCode != null
              ? 'Share this code with the new owner. It expires in ${_getRemainingTime()}.'
              : 'Generate a secure transfer code to send this scale to another user.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white60 : NeoColors.textSecondary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        // Device info card
        NeoCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: NeoColors.blueGradient
                        .map((c) => c.withValues(alpha: 0.2))
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.scale, color: NeoColors.blueGradient[0]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.deviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NeoColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.deviceMac,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : NeoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Transfer code display
        if (_transferCode != null) ...[
          _buildTransferCodeDisplay(isDark),
          const SizedBox(height: 24),

          // Security warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeoColors.warningGradient[0].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: NeoColors.warningGradient[0].withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: NeoColors.warningGradient[0]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'After transfer, you will lose access to this scale and all local data.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : NeoColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cancel button
          NeoButton(
            gradient: NeoColors.errorGradient,
            width: double.infinity,
            onPressed: () => setState(() {
              _transferCode = null;
              _codeExpiry = null;
            }),
            child: const Text('Cancel Transfer'),
          ),
        ] else ...[
          // Generate button
          NeoButton(
            gradient: NeoColors.primaryGradient,
            width: double.infinity,
            isLoading: _isLoading,
            onPressed: _generateTransferCode,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key, color: Colors.white),
                SizedBox(width: 10),
                Text('Generate Transfer Code'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransferCodeDisplay(bool isDark) {
    return NeoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'TRANSFER CODE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: isDark ? Colors.white54 : NeoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Code display with copy button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _transferCode!.split('').asMap().entries.map((entry) {
              return Container(
                width: 42,
                height: 52,
                margin: EdgeInsets.only(
                  right: entry.key < _transferCode!.length - 1 ? 8 : 0,
                  left: entry.key == 3 ? 8 : 0, // Gap in middle
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A24)
                      : const Color(0xFFD8E8D8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A2A3A)
                        : const Color(0xFFB0C8B0),
                  ),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF00FF88)
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Expiry timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer,
                  size: 16,
                  color: isDark ? Colors.white54 : NeoColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Expires in ${_getRemainingTime()}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : NeoColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveMode(bool isDark) {
    return Column(
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
            Icons.download_outlined,
            size: 56,
            color: NeoColors.tealGradient[0],
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Receive Scale',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : NeoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Enter the 6-digit transfer code provided by the current owner.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white60 : NeoColors.textSecondary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        // PIN input
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 46,
              height: 56,
              margin: EdgeInsets.only(
                right: index < 5 ? 10 : 0,
                left: index == 3 ? 10 : 0, // Gap in middle
              ),
              child: TextField(
                controller: _pinControllers[index],
                focusNode: _pinFocusNodes[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NeoColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF252536) : NeoColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF3A3A4A)
                          : NeoColors.lightShadowDark,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF3A3A4A)
                          : NeoColors.lightShadowDark.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: NeoColors.tealGradient[0], width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _pinFocusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    _pinFocusNodes[index - 1].requestFocus();
                  }
                  // Check if all filled
                  if (_pinControllers.every((c) => c.text.isNotEmpty)) {
                    _verifyTransferCode();
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 40),

        // Verify button
        NeoButton(
          gradient: NeoColors.tealGradient,
          width: double.infinity,
          isLoading: _isLoading,
          onPressed: _verifyTransferCode,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Colors.white),
              SizedBox(width: 10),
              Text('Verify & Accept'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransferComplete(bool isDark) {
    return Column(
      children: [
        // Success icon
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: NeoColors.successGradient
                  .map((c) => c.withValues(alpha: 0.15))
                  .toList(),
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 72,
            color: NeoColors.successGradient[0],
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Transfer Complete!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : NeoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          _isTransferMode
              ? 'You are now the owner of this scale. It has been added to your devices.'
              : 'The scale has been successfully transferred to the new owner.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white60 : NeoColors.textSecondary,
            height: 1.5,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 40),

        NeoButton(
          gradient: NeoColors.successGradient,
          width: double.infinity,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Done'),
        ),
      ],
    );
  }

  String _getRemainingTime() {
    if (_codeExpiry == null) return '5:00';
    final remaining = _codeExpiry!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _generateTransferCode() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Generate 6-digit code
    final random = Random.secure();
    final code = List.generate(6, (_) => random.nextInt(10)).join();

    setState(() {
      _transferCode = code;
      _codeExpiry = DateTime.now().add(const Duration(minutes: 5));
      _isLoading = false;
    });

    // Start expiry timer
    _startExpiryTimer();
  }

  void _startExpiryTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _transferCode != null) {
        setState(() {});
        if (_codeExpiry!.isAfter(DateTime.now())) {
          _startExpiryTimer();
        } else {
          // Code expired
          setState(() {
            _transferCode = null;
            _codeExpiry = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transfer code expired'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: NeoColors.errorGradient[0],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    });
  }

  void _verifyTransferCode() async {
    final code = _pinControllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter complete 6-digit code'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NeoColors.errorGradient[0],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API verification
    await Future.delayed(const Duration(seconds: 2));

    // For demo, accept any 6-digit code
    setState(() {
      _isLoading = false;
      _transferComplete = true;
    });
  }
}
