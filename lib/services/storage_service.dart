import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mcq_model.dart';
import '../models/study_models.dart';

class StorageService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _localBoxName = 'scans_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_localBoxName);
  }

  static Box get _localBox => Hive.box(_localBoxName);

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference? get _scansRef => _uid != null
      ? _firestore.collection('users').doc(_uid).collection('scans')
      : null;

  // ─── Usage Count (local only) ───────────────────────────────────────────

  static Future<void> incrementUsageCount() async {
    final current = _localBox.get('total_usage', defaultValue: 0) as int;
    await _localBox.put('total_usage', current + 1);
  }

  static int getUsageCount() =>
      _localBox.get('total_usage', defaultValue: 0) as int;

  // ─── Save ───────────────────────────────────────────────────────────────

  static Future<bool> saveScan({
    required String id,
    required DateTime date,
    required List<MCQQuestion> questions,
  }) async {
    final questionsJson = questions.map((q) => q.toJson()).toList();
    if (await _isDuplicate('mcq', questionsJson)) return false;
    final data = {
      'id': id,
      'date': date.toIso8601String(),
      'type': 'mcq',
      'name': _generateName('mcq', questionsJson),
      'questions': questionsJson,
    };
    await _save(id, data);
    return true;
  }

  static Future<bool> saveStudyClass({
    required String id,
    required DateTime date,
    required StudyClass studyClass,
  }) async {
    final data = studyClass.toJson();
    if (await _isDuplicate('study', data)) return false;
    final doc = {
      'id': id,
      'date': date.toIso8601String(),
      'type': 'study',
      'name': _generateName('study', data),
      'data': data,
    };
    await _save(id, doc);
    return true;
  }

  static Future<bool> saveQuizSet({
    required String id,
    required DateTime date,
    required QuizSet quizSet,
  }) async {
    final data = quizSet.toJson();
    if (await _isDuplicate('quiz', data)) return false;
    final doc = {
      'id': id,
      'date': date.toIso8601String(),
      'type': 'quiz',
      'name': _generateName('quiz', data),
      'data': data,
    };
    await _save(id, doc);
    return true;
  }

  static Future<void> _save(String id, Map<String, dynamic> data) async {
    // save locally
    await _localBox.put(id, data);
    // save to Firestore if logged in
    if (_scansRef != null) {
      await _scansRef!.doc(id).set(data);
    }
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getAllScans() {
    return _localBox.values
        .where((v) => v is Map && v['date'] != null)
        .map((v) => _deepCast(v))
        .toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  }

  /// Sync from Firestore to local Hive (call after login)
  static Future<void> syncFromFirestore() async {
    if (_scansRef == null) return;
    final snapshot = await _scansRef!.get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      await _localBox.put(doc.id, data);
    }
  }

  static List<MCQQuestion> getQuestionsForScan(String id) {
    final scanData = _localBox.get(id);
    if (scanData == null || scanData['type'] != 'mcq') return [];
    final List<dynamic> questionsJson = scanData['questions'] ?? [];
    return questionsJson.map((q) => MCQQuestion.fromJson(_deepCast(q))).toList();
  }

  static StudyClass? getStudyClass(String id) {
    final scanData = _localBox.get(id);
    if (scanData == null || scanData['type'] != 'study') return null;
    return StudyClass.fromJson(_deepCast(scanData['data']));
  }

  static QuizSet? getQuizSet(String id) {
    final scanData = _localBox.get(id);
    if (scanData == null || scanData['type'] != 'quiz') return null;
    return QuizSet.fromJson(_deepCast(scanData['data']));
  }

  // ─── Delete & Rename ─────────────────────────────────────────────────────

  static Future<void> deleteScan(String id) async {
    await _localBox.delete(id);
    await _scansRef?.doc(id).delete();
  }

  static Future<void> renameScan(String id, String newName) async {
    final data = _localBox.get(id);
    if (data == null) return;
    data['name'] = newName;
    await _localBox.put(id, data);
    await _scansRef?.doc(id).update({'name': newName});
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static Future<bool> _isDuplicate(String type, dynamic contentJson) async {
    return _localBox.values.any((v) {
      if (v is! Map || v['type'] != type) return false;
      final existing = type == 'mcq' ? v['questions'] : v['data'];
      return existing.toString() == contentJson.toString();
    });
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

  static Map<String, dynamic> _deepCast(dynamic map) {
    return Map<String, dynamic>.from(map as Map).map(
      (k, v) => MapEntry(k.toString(), v is Map ? _deepCast(v) : v),
    );
  }
}
