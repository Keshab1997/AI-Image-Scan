import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null) {
        await StorageService.syncFromFirestore();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('লগইন ব্যর্থ: $e'),
            backgroundColor: AppTheme.wrongRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.indigoGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.accentIndigo.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 52),
                  ).animate().scale(duration: 600.ms),
                  const SizedBox(height: 32),
                  const Text(
                    'AI প্রশ্ন স্ক্যানার',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  const Text(
                    'সব ডিভাইসে ডেটা sync করতে\nGoogle দিয়ে লগইন করুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.6),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 48),
                  _loading
                      ? const CircularProgressIndicator(color: AppTheme.accentIndigo)
                      : GestureDetector(
                          onTap: _signIn,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  'https://www.google.com/favicon.ico',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Google দিয়ে লগইন করুন',
                                  style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
