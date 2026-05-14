import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/study_models.dart';
import '../services/storage_service.dart';
import 'dart:convert';

class StudyClassScreen extends StatelessWidget {
  final StudyClass studyClass;

  const StudyClassScreen({super.key, required this.studyClass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildSections(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              studyClass.chapterName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final jsonString = jsonEncode(studyClass.toJson());
              await Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON কপি করা হয়েছে!'), backgroundColor: AppTheme.accentIndigo),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.copy_rounded, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final saved = await StorageService.saveStudyClass(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                date: DateTime.now(),
                studyClass: studyClass,
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
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.save_rounded, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.accentIndigo.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(studyClass.classNumber, style: const TextStyle(color: AppTheme.accentIndigo, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  List<Widget> _buildSections() {
    List<Widget> widgets = [];

    for (int i = 0; i < studyClass.sections.length; i++) {
      final section = studyClass.sections[i];
      Widget widget;

      switch (section.type) {
        case 'title':
          widget = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(section.content ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
          ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
          break;

        case 'header':
          widget = Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(gradient: AppTheme.indigoGradient, borderRadius: BorderRadius.circular(10)),
              child: Text(section.content ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
          break;

        case 'text':
          widget = Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(section.content ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.6)),
          ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
          break;

        case 'math':
          widget = Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3))),
            child: Text(section.content ?? '', style: const TextStyle(color: AppTheme.accentPurple, fontSize: 16, fontWeight: FontWeight.w600)),
          ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
          break;

        case 'box':
          widget = Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppTheme.correctGradient, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(section.content ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5))),
            ]),
          ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
          break;

        case 'list':
          final items = section.items ?? [];
          widget = Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < items.length; i++) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•', style: TextStyle(color: AppTheme.accentIndigo, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(items[i], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.4))),
                ]),
                if (i < items.length - 1) const SizedBox(height: 6),
              ],
            ]),
          ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
          break;

        case 'question':
          widget = Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.accentIndigo.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('প্রশ্ন', style: TextStyle(color: AppTheme.accentIndigo, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(section.qText ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              if (section.explanation != null && section.explanation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.menu_book_rounded, color: AppTheme.accentPurple, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(section.explanation ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4))),
                  ]),
                ),
              ],
            ]),
          ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
          break;

        default:
          widget = const SizedBox.shrink();
      }

      widgets.add(widget);
    }

    return widgets;
  }
}