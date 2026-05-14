import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/study_models.dart';
import 'result_screen.dart';
import 'study_class_screen.dart';
import 'quiz_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final scans = StorageService.getAllScans();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (scans.isEmpty) _buildEmptyState() else _buildScansList(scans),
            ],
          ),
        ),
      ),
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
                const Text(
                  'সংরক্ষিত স্ক্যান',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'মোট ব্যবহার: ${StorageService.getUsageCount()} বার',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: AppTheme.textSecondary, size: 64),
            const SizedBox(height: 16),
            const Text(
              'কোনো সংরক্ষিত স্ক্যান নেই',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(String id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('নাম পরিবর্তন', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'নতুন নাম লিখুন',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.accentIndigo),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('সংরক্ষণ', style: TextStyle(color: AppTheme.accentIndigo)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await StorageService.renameScan(id, newName);
      setState(() {});
    }
  }

  Widget _buildScansList(List<Map<String, dynamic>> scans) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scans.length,
        itemBuilder: (context, index) {
          final scan = scans[index];
          final id = scan['id'] as String;
          final type = scan['type'] ?? 'mcq';
          final name = scan['name'] as String? ?? (type == 'study'
              ? (scan['data']?['chapterName'] ?? 'স্ক্যান')
              : type == 'quiz'
                  ? (scan['data']?['setName'] ?? 'স্ক্যান')
                  : '${(scan['questions'] as List?)?.length ?? 0} MCQ');
          final dateStr = scan['date'] as String;
          final date = DateTime.parse(dateStr);
          final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

          return GestureDetector(
            onLongPress: () => _showRenameDialog(id, name),
            onTap: () {
              if (type == 'mcq') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      questions: StorageService.getQuestionsForScan(id),
                    ),
                  ),
                );
              } else if (type == 'study') {
                final studyClass = StorageService.getStudyClass(id);
                if (studyClass != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StudyClassScreen(studyClass: studyClass)),
                  );
                }
              } else if (type == 'quiz') {
                final quizSet = StorageService.getQuizSet(id);
                if (quizSet != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuizScreen(quizSet: quizSet)),
                  );
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentIndigo.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      type == 'study' ? Icons.book_rounded : (type == 'quiz' ? Icons.quiz_rounded : Icons.description_rounded),
                      color: AppTheme.accentIndigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$formattedDate • ${type == 'mcq' ? (scan['questions'] as List).length : (type == 'study' ? (scan['data']['sections'] as List).length : (scan['data']['questions'] as List).length)}টি আইটেম',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.wrongRed),
                    onPressed: () async {
                      await StorageService.deleteScan(id);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: index * 100)).fadeIn().slideX(begin: 0.1);
        },
      ),
    );
  }
}
