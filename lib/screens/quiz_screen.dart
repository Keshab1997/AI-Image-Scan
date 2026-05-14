import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/study_models.dart';
import '../services/storage_service.dart';
import 'dart:convert';

class QuizScreen extends StatefulWidget {
  final QuizSet quizSet;

  const QuizScreen({super.key, required this.quizSet});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  List<int> _shuffledIndices = [];

  @override
  void initState() {
    super.initState();
    _shuffledIndices = List.generate(widget.quizSet.questions.length, (i) => i);
  }

  QuizQuestion get _currentQuestion => widget.quizSet.questions[_shuffledIndices[_currentIndex]];

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _currentQuestion.correctAnswerIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _shuffledIndices.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('📊 কুইজ সমাপ্ত!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppTheme.indigoGradient, shape: BoxShape.circle),
              child: Text(
                '$_score / ${widget.quizSet.questions.length}',
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'আপনার স্কোর: ${((_score / widget.quizSet.questions.length) * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('বন্ধ করুন', style: TextStyle(color: AppTheme.accentIndigo)),
          ),
        ],
      ),
    );
  }

  Color _optionColor(int index) {
    if (!_answered) return AppTheme.cardDark;
    if (index == _currentQuestion.correctAnswerIndex) return AppTheme.correctGreen.withOpacity(0.3);
    if (index == _selectedAnswer && index != _currentQuestion.correctAnswerIndex) return AppTheme.wrongRed.withOpacity(0.3);
    return AppTheme.cardDark;
  }

  IconData _optionIcon(int index) {
    if (!_answered) return Icons.radio_button_unchecked;
    if (index == _currentQuestion.correctAnswerIndex) return Icons.check_circle;
    if (index == _selectedAnswer && index != _currentQuestion.correctAnswerIndex) return Icons.cancel;
    return Icons.radio_button_unchecked;
  }

  Color _optionIconColor(int index) {
    if (!_answered) return AppTheme.textSecondary;
    if (index == _currentQuestion.correctAnswerIndex) return AppTheme.correctGreen;
    if (index == _selectedAnswer && index != _currentQuestion.correctAnswerIndex) return AppTheme.wrongRed;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildQuizHeader(),
              _buildProgressBar(),
              Expanded(child: _buildQuestionCard()),
              if (_answered) _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.quizSet.setName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.quizSet.chapterName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final jsonString = jsonEncode(widget.quizSet.toJson());
              await Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON কপি করা হয়েছে!'), backgroundColor: AppTheme.accentIndigo),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
              child: const Icon(Icons.copy_rounded, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final saved = await StorageService.saveQuizSet(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                date: DateTime.now(),
                quizSet: widget.quizSet,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(saved ? 'সংরক্ষণ করা হয়েছে!' : 'এই স্ক্যান আগেই সংরক্ষিত আছে!'),
                  backgroundColor: saved ? AppTheme.accentIndigo : AppTheme.wrongRed,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
              child: const Icon(Icons.save_rounded, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Text('${_currentIndex + 1} / ${_shuffledIndices.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentIndex + 1) / _shuffledIndices.length,
      backgroundColor: AppTheme.divider,
      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentIndigo),
      minHeight: 4,
    );
  }

  Widget _buildQuestionCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(gradient: AppTheme.indigoGradient, borderRadius: BorderRadius.circular(20)),
            child: Text('প্রশ্ন ${_currentIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          // Question text
          Text(
            _currentQuestion.question,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
          ),
          const SizedBox(height: 20),
          // Options
          ...List.generate(_currentQuestion.options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _selectAnswer(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _optionColor(index),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _answered ? Colors.transparent : AppTheme.divider, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(_optionIcon(index), color: _optionIconColor(index), size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_currentQuestion.options[index], style: TextStyle(color: Colors.white, fontSize: 15))),
                    ],
                  ),
                ),
              ),
            ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideX(begin: 0.1);
          }),
          // Explanation after answering
          if (_answered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppTheme.explanationGradient, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppTheme.accentPurple, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_currentQuestion.explanation, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5))),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    if (_currentIndex < _shuffledIndices.length - 1) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentIndigo,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('পরবর্তী প্রশ্ন ➜', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _showResults,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.correctGreen,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('📊 ফলাফল দেখুন', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }
}