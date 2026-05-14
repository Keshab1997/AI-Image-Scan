import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) => _buildShimmerCard(index)),
      ),
    );
  }

  Widget _buildShimmerCard(int index) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.secondaryDark,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Container(
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.accentIndigo,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 14, width: double.infinity),
                  const SizedBox(height: 8),
                  _shimmerBox(height: 14, width: 250),
                  const SizedBox(height: 24),
                  ...List.generate(4, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _shimmerBox(height: 52, width: double.infinity),
                  )),
                  const SizedBox(height: 8),
                  _shimmerBox(height: 60, width: double.infinity),
                  const SizedBox(height: 16),
                  _shimmerBox(height: 120, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class AIProcessingOverlay extends StatefulWidget {
  const AIProcessingOverlay({super.key});

  @override
  State<AIProcessingOverlay> createState() => _AIProcessingOverlayState();
}

class _AIProcessingOverlayState extends State<AIProcessingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  int _stepIndex = 0;

  final List<String> _steps = [
    'ছবি বিশ্লেষণ করা হচ্ছে...',
    'প্রশ্ন খুঁজে বের করা হচ্ছে...',
    'উত্তর নির্ধারণ করা হচ্ছে...',
    'বাংলায় ব্যাখ্যা তৈরি করা হচ্ছে...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startStepCycle();
  }

  void _startStepCycle() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _stepIndex = (_stepIndex + 1) % _steps.length;
        });
        _startStepCycle();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated AI logo
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, child) => Transform.rotate(
              angle: _rotateController.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.indigoGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentIndigo.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Opacity(
              opacity: 0.6 + (_pulseController.value * 0.4),
              child: Text(
                _steps[_stepIndex],
                style: const TextStyle(
                  color: AppTheme.accentIndigo,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentIndigo),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
