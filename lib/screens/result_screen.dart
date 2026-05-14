import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mcq_model.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';
import '../services/storage_service.dart';

class ResultScreen extends StatefulWidget {
  final List<MCQQuestion> questions;
  final Uint8List? imageBytes;

  const ResultScreen({
    super.key,
    required this.questions,
    this.imageBytes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showImage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (_showImage && widget.imageBytes != null) _buildImagePreview(),
              _buildStatsBar(),
              Expanded(child: _buildQuestionsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppTheme.indigoGradient.createShader(b),
                  child: const Text(
                    'বিশ্লেষণ ফলাফল',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${widget.questions.length}টি প্রশ্ন পাওয়া গেছে',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _copyAllResults,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: AppTheme.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _saveScan,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Icon(Icons.save_rounded,
                      color: AppTheme.textPrimary, size: 20),
                ),
              ),
              if (widget.imageBytes != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showImage = !_showImage),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _showImage ? AppTheme.indigoGradient : null,
                      color: _showImage ? null : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      color: _showImage ? Colors.white : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Future<void> _copyAllResults() async {
    StringBuffer buffer = StringBuffer();
    for (var i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      buffer.writeln('প্রশ্ন ${q.number.isNotEmpty ? q.number : (i + 1)}');
      if (q.subject != null && q.subject!.isNotEmpty) {
        buffer.writeln('বিষয়: ${q.subject}');
      }
      buffer.writeln('প্রশ্ন: ${q.question}');
      buffer.writeln('বিকল্পসমূহ:');
      q.options.forEach((key, value) {
        if (value.isNotEmpty) {
          buffer.writeln('  $key: $value');
        }
      });
      buffer.writeln('সঠিক উত্তর: (${q.correctAnswer}) ${q.options[q.correctAnswer.toUpperCase()] ?? ''}');
      buffer.writeln('ব্যাখ্যা: ${q.explanation}');
      if (i < widget.questions.length - 1) {
        buffer.writeln('\n' + '=' * 30 + '\n');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('সবগুলো ফলাফল কপি করা হয়েছে!'),
        backgroundColor: AppTheme.accentIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveScan() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final saved = await StorageService.saveScan(
      id: id,
      date: DateTime.now(),
      questions: widget.questions,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'সফলভাবে সংরক্ষণ করা হয়েছে!' : 'এই স্ক্যান আগেই সংরক্ষিত আছে!'),
        backgroundColor: saved ? AppTheme.accentIndigo : AppTheme.wrongRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentIndigo.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentIndigo.withOpacity(0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(widget.imageBytes!, fit: BoxFit.cover, width: double.infinity),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.quiz_rounded,
            label: 'মোট প্রশ্ন',
            value: '${widget.questions.length}',
            color: AppTheme.accentIndigo,
          ),
          const Spacer(),
          _StatChip(
            icon: Icons.check_circle_rounded,
            label: 'উত্তরসহ',
            value: '${widget.questions.where((q) => q.correctAnswer.isNotEmpty).length}',
            color: AppTheme.correctGreen,
          ),
          const Spacer(),
          _StatChip(
            icon: Icons.menu_book_rounded,
            label: 'ব্যাখ্যাসহ',
            value: '${widget.questions.where((q) => q.explanation.isNotEmpty).length}',
            color: AppTheme.accentPurple,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        return QuestionCard(
          question: widget.questions[index],
          index: index,
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pop(context),
      backgroundColor: AppTheme.accentIndigo,
      icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      label: const Text(
        'নতুন স্ক্যান',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ).animate(delay: 600.ms).fadeIn().scale();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
