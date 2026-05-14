import 'package:hive_flutter/hive_flutter.dart';
import '../models/mcq_model.dart';
import '../models/study_models.dart';

class StorageService {
  static const String _boxName = 'scans_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static Future<void> incrementUsageCount() async {
    final currentCount = _box.get('total_usage', defaultValue: 0) as int;
    await _box.put('total_usage', currentCount + 1);
  }

  static int getUsageCount() {
    return _box.get('total_usage', defaultValue: 0) as int;
  }

  static String _generateName(String type, dynamic data) {
    if (type == 'study') {
      final chapter = data['chapterName']?.toString() ?? '';
      final cls = data['classNumber']?.toString() ?? '';
      if (chapter.isNotEmpty) return cls.isNotEmpty ? '$chapter ($cls)' : chapter;
    } else if (type == 'quiz') {
      final set = data['setName']?.toString() ?? '';
      final chapter = data['chapterName']?.toString() ?? '';
      if (set.isNotEmpty) return chapter.isNotEmpty ? '$set — $chapter' : set;
    } else if (type == 'mcq') {
      final questions = data as List;
      if (questions.isNotEmpty) {
        final subject = questions.first['subject']?.toString() ?? '';
        final count = questions.length;
        if (subject.isNotEmpty) return '$subject ($count MCQ)';
        return '$count MCQ';
      }
    }
    return 'স্ক্যান';
  }

  static bool _isDuplicate(String type, dynamic contentJson) {
    return _box.values.any((v) {
      if (v is! Map || v['type'] != type) return false;
      final existing = type == 'mcq' ? v['questions'] : v['data'];
      return existing.toString() == contentJson.toString();
    });
  }

  /// Returns false if duplicate
  static Future<bool> saveScan({
    required String id,
    required DateTime date,
    required List<MCQQuestion> questions,
  }) async {
    final questionsJson = questions.map((q) => q.toJson()).toList();
    if (_isDuplicate('mcq', questionsJson)) return false;
    await _box.put(id, {
      'id': id,
      'date': date.toIso8601String(),
      'type': 'mcq',
      'name': _generateName('mcq', questionsJson),
      'questions': questionsJson,
    });
    return true;
  }

  /// Returns false if duplicate
  static Future<bool> saveStudyClass({
    required String id,
    required DateTime date,
    required StudyClass studyClass,
  }) async {
    final data = studyClass.toJson();
    if (_isDuplicate('study', data)) return false;
    await _box.put(id, {
      'id': id,
      'date': date.toIso8601String(),
      'type': 'study',
      'name': _generateName('study', data),
      'data': data,
    });
    return true;
  }

  /// Returns false if duplicate
  static Future<bool> saveQuizSet({
    required String id,
    required DateTime date,
    required QuizSet quizSet,
  }) async {
    final data = quizSet.toJson();
    if (_isDuplicate('quiz', data)) return false;
    await _box.put(id, {
      'id': id,
      'date': date.toIso8601String(),
      'type': 'quiz',
      'name': _generateName('quiz', data),
      'data': data,
    });
    return true;
  }

  static Future<void> renameScan(String id, String newName) async {
    final data = _box.get(id);
    if (data == null) return;
    data['name'] = newName;
    await _box.put(id, data);
  }

  static Map<String, dynamic> _deepCast(dynamic map) {
    return Map<String, dynamic>.from(map as Map).map(
      (k, v) => MapEntry(k.toString(), v is Map ? _deepCast(v) : v),
    );
  }

  static List<Map<String, dynamic>> getAllScans() {
    return _box.values
        .where((v) => v is Map && v['date'] != null)
        .map((v) => _deepCast(v))
        .toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  }

  static Map<String, dynamic>? getRawScan(String id) {
    final data = _box.get(id);
    return data != null ? _deepCast(data) : null;
  }

  static List<MCQQuestion> getQuestionsForScan(String id) {
    final scanData = _box.get(id);
    if (scanData == null) return [];
    final type = scanData['type'] ?? 'mcq';
    if (type == 'mcq') {
      final List<dynamic> questionsJson = scanData['questions'] ?? [];
      return questionsJson
          .map((q) => MCQQuestion.fromJson(_deepCast(q)))
          .toList();
    }
    return [];
  }

  static StudyClass? getStudyClass(String id) {
    final scanData = _box.get(id);
    if (scanData == null || scanData['type'] != 'study') return null;
    return StudyClass.fromJson(_deepCast(scanData['data']));
  }

  static QuizSet? getQuizSet(String id) {
    final scanData = _box.get(id);
    if (scanData == null || scanData['type'] != 'quiz') return null;
    return QuizSet.fromJson(_deepCast(scanData['data']));
  }

  static Future<void> deleteScan(String id) async {
    await _box.delete(id);
  }
}
