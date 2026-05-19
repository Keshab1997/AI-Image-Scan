import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'theme/app_theme.dart';
import 'services/gemini_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? const FirebaseOptions(
      apiKey: 'AIzaSyB-fnNtGfwAXASB9JMxJhI3I933_uYK0Xc',
      authDomain: 'study-with-keshab.firebaseapp.com',
      projectId: 'study-with-keshab',
      storageBucket: 'study-with-keshab.firebasestorage.app',
      messagingSenderId: '752692165545',
      appId: '1:752692165545:web:219ff482874717c3ab22b8',
    ) : null,
  );
  await StorageService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const AIImageScanApp());
}

class AIImageScanApp extends StatelessWidget {
  const AIImageScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final geminiService = GeminiService(apiKey: _apiKey);
    return MaterialApp(
      title: 'AI প্রশ্ন স্ক্যানার',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _apiKey.isEmpty
          ? const _ApiKeyMissingScreen()
          : StreamBuilder<User?>(
              stream: AuthService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingScreen();
                }
                if (snapshot.hasData) {
                  return HomeScreen(geminiService: geminiService);
                }
                return const LoginScreen();
              },
            ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      ),
    );
  }
}

class _ApiKeyMissingScreen extends StatelessWidget {
  const _ApiKeyMissingScreen();

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
                      color: AppTheme.wrongRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.wrongRed.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.key_off_rounded, color: AppTheme.wrongRed, size: 52),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'API Key প্রয়োজন',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'GEMINI_API_KEY dart-define এ দিন',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
