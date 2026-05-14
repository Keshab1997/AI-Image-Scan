import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/gemini_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          : HomeScreen(geminiService: geminiService),
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
                    '.env ফাইলে আপনার Gemini API Key দিন:\n\nGEMINI_API_KEY=আপনার_কী_এখানে',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.7),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.accentIndigo),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Google AI Studio থেকে ফ্রিতে API Key নিন:\naistudio.google.com',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
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
