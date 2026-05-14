import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';
import 'study_class_screen.dart';
import 'quiz_screen.dart';
import 'history_screen.dart';

enum ScanMode { mcq, study, quiz }

class HomeScreen extends StatefulWidget {
  final GeminiService geminiService;

  const HomeScreen({super.key, required this.geminiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  double _progress = 0.0;
  String? _errorMessage;
  Uint8List? _previewBytes;
  late AnimationController _floatController;
  ScanMode _selectedMode = ScanMode.mcq;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    if (kIsWeb) {
      _showSnackBar('ওয়েবে ক্যামেরা সমর্থিত নয়। ফাইল আপলোড করুন।');
      return;
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _previewBytes = bytes);
      await _processImage(bytes);
    }
  }

  Future<void> _pickFromGallery() async {
    if (kIsWeb) {
      await _pickFileWeb();
      return;
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _previewBytes = bytes);
      await _processImage(bytes);
    }
  }

  Future<void> _pickFileWeb() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      final bytes = result.files.first.bytes!;
      setState(() => _previewBytes = bytes);
      await _processImage(bytes);
    }
  }

  Future<void> _processImage(Uint8List bytes) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    final progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_progress < 0.9) {
          _progress += 0.01;
        }
      });
    });

    try {
      if (_selectedMode == ScanMode.mcq) {
        final questions = await widget.geminiService.extractMCQFromImageBytes(bytes);
        await StorageService.incrementUsageCount();
        progressTimer.cancel();
        setState(() => _progress = 1.0);

        if (!mounted) return;
        if (questions.isEmpty) {
          setState(() {
            _errorMessage = 'ছবিতে কোনো MCQ প্রশ্ন পাওয়া যায়নি।';
            _isLoading = false;
          });
          return;
        }
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => ResultScreen(
              questions: questions,
              imageBytes: bytes,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              );
            },
          ),
        );
      } else if (_selectedMode == ScanMode.study) {
        final studyClass = await widget.geminiService.extractClassContent(bytes);
        await StorageService.incrementUsageCount();
        progressTimer.cancel();
        setState(() => _progress = 1.0);
        if (!mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => StudyClassScreen(studyClass: studyClass),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              );
            },
          ),
        );
      } else {
        final quizSet = await widget.geminiService.generateQuiz(bytes);
        await StorageService.incrementUsageCount();
        progressTimer.cancel();
        setState(() => _progress = 1.0);
        if (!mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => QuizScreen(quizSet: quizSet),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      progressTimer.cancel();
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              _buildBackgroundDecor(),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildUploadSection()),
                  if (_errorMessage != null) SliverToBoxAdapter(child: _buildErrorWidget()),
                  SliverToBoxAdapter(child: _buildFeaturesSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.accentIndigo.withOpacity(0.15), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.accentTeal.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.indigoGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.accentIndigo.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.indigoGradient.createShader(bounds),
                      child: const Text('AI প্রশ্ন স্ক্যানার', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    ),
                    const Text('ছবি থেকে MCQ বিশ্লেষণ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1),
    );
  }

  Widget _buildUploadSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
            child: Row(
              children: ScanMode.values.map((mode) {
                final isSelected = _selectedMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(gradient: isSelected ? AppTheme.indigoGradient : null, color: isSelected ? null : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(_getModeLabel(mode), style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, child) {
              return Transform.translate(offset: Offset(0, _floatController.value * 6 - 3), child: child);
            },
            child: GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1F2340), Color(0xFF252A55)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.accentIndigo.withOpacity(0.4), width: 1.5), boxShadow: [BoxShadow(color: AppTheme.accentIndigo.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))]),
                child: _previewBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.memory(_previewBytes!, fit: BoxFit.cover),
                          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)]))),
                          const Positioned(bottom: 16, left: 0, right: 0, child: Text('নতুন ছবি বেছে নিতে ট্যাপ করুন', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13))),
                        ]),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: AppTheme.indigoGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.accentIndigo.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)]), child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 44)),
                        const SizedBox(height: 20),
                        const Text('ছবি আপলোড করুন', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('MCQ প্রশ্নের ছবি বেছে নিন', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _ActionButton(icon: Icons.photo_library_rounded, label: 'গ্যালারি', gradient: AppTheme.indigoGradient, onTap: _pickFromGallery)),
              const SizedBox(width: 16),
              if (!kIsWeb) Expanded(child: _ActionButton(icon: Icons.camera_alt_rounded, label: 'ক্যামেরা', gradient: AppTheme.tealGradient, onTap: _pickFromCamera)),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1),
    );
  }

  String _getModeLabel(ScanMode mode) {
    switch (mode) {
      case ScanMode.mcq: return 'MCQ স্ক্যান';
      case ScanMode.study: return 'স্টাডি ক্লাস';
      case ScanMode.quiz: return 'কুইজ তৈরি';
    }
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.wrongRed.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.wrongRed.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppTheme.wrongRed),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.wrongRed, fontSize: 13))),
          IconButton(icon: const Icon(Icons.close, color: AppTheme.wrongRed, size: 18), onPressed: () => setState(() => _errorMessage = null)),
        ]),
      ).animate().fadeIn().shake(),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      (Icons.document_scanner_rounded, 'স্বয়ংক্রিয় স্ক্যান', 'ছবি থেকে প্রশ্ন বের করে'),
      (Icons.spellcheck_rounded, 'সঠিক উত্তর', 'AI দ্বারা উত্তর নির্ধারণ'),
      (Icons.menu_book_rounded, 'বাংলায় ব্যাখ্যা', 'বিস্তারিত বাংলা ব্যাখ্যা'),
      (Icons.speed_rounded, 'দ্রুত বিশ্লেষণ', 'মাত্র কয়েক সেকেন্ডে'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('বৈশিষ্ট্যসমূহ', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3, children: features.asMap().entries.map((e) => _FeatureCard(icon: e.value.$1, title: e.value.$2, subtitle: e.value.$3, index: e.key)).toList()),
      ]).animate().fadeIn(delay: 400.ms),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(gradient: AppTheme.indigoGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.accentIndigo.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)]),
            child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 44)),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
          const SizedBox(height: 28),
          const Text('AI বিশ্লেষণ চলছে...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('বাংলায় ব্যাখ্যা তৈরি হচ্ছে', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          SizedBox(width: 180, child: LinearProgressIndicator(backgroundColor: AppTheme.divider, value: _progress, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentIndigo), minHeight: 3)),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int index;

  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppTheme.accentIndigo, size: 28),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    ).animate(delay: Duration(milliseconds: 500 + index * 100)).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}