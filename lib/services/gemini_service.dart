import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/mcq_model.dart';
import '../models/study_models.dart';

class GeminiService {
  static const String _prompt = '''
তুমি একজন বিশেষজ্ঞ শিক্ষক। এই ছবিতে MCQ প্রশ্ন আছে। প্রতিটি প্রশ্নের জন্য নিচের JSON format-এ বাংলায় উত্তর দাও।

নির্দেশনা:
- প্রতিটি প্রশ্ন, option এবং ব্যাখ্যা বাংলায় লিখবে
- সঠিক উত্তর চিহ্নিত করবে
- বিস্তারিত ব্যাখ্যা বাংলায় দেবে (কেন এই উত্তর সঠিক এবং অন্যগুলো কেন ভুল)
- আউটপুট অবশ্যই একটি বৈধ এবং COMPACT JSON হতে হবে। 
- JSON-এর ভেতরের কোনো ভ্যালুর (যেমন: explanation) ভেতরে সরাসরি 'Enter' বা Newline ব্যবহার করবে না। লাইনের ব্রেক দরকার হলে অবশ্যই `\\n` ব্যবহার করবে।
- পুরো JSON-টি এক লাইনে (single line) দেওয়ার চেষ্টা করো।

শুধুমাত্র নিচের JSON format-এ উত্তর দাও, অন্য কিছু লিখবে না:

{
  "questions": [
    {
      "number": "প্রশ্ন নম্বর",
      "subject": "বিষয় (যেমন: পদার্থবিজ্ঞান, গণিত, ইতিহাস)",
      "question": "সম্পূর্ণ প্রশ্নটি এখানে",
      "options": {
        "A": "বিকল্প A",
        "B": "বিকল্প B",
        "C": "বিকল্প C",
        "D": "বিকল্প D"
      },
      "correct_answer": "সঠিক বিকল্পের অক্ষর (A/B/C/D)",
      "explanation": "বিস্তারিত বাংলায় ব্যাখ্যা"
    }
  ]
}
''';

  static const String _studyPrompt = '''
তুমি একজন বিশেষজ্ঞ শিক্ষক। এই ছবি থেকে একটি পূর্ণাঙ্গ স্টাডি ক্লাস (Study Class) তৈরি করো।
আউটপুট অবশ্যই নিচের JSON ফরম্যাটে হতে হবে।

নির্দেশনা:
- ছবিতে থাকা **সবগুলো তথ্য এবং প্রতিটি অংশ** বিস্তারিতভাবে সংগ্রহ করো। কোনো কিছু বাদ দেবে না।
- সব কন্টেন্ট বাংলায় লিখবে।
- কন্টেন্টকে বিভিন্ন সেকশনে ভাগ করবে (title, header, text, math, box, list, question)।
- math সেকশনে গাণিতিক সূত্রগুলো সুন্দরভাবে লিখবে।
- box সেকশনে গুরুত্বপূর্ণ নোট বা শর্টকাট লিখবে।
- list সেকশনে পয়েন্ট আকারে তথ্য দেবে।
- question সেকশনে প্রশ্ন, অপশন এবং বিস্তারিত ব্যাখ্যা দেবে।
- আউটপুট অবশ্যই একটি বৈধ COMPACT JSON হতে হবে এবং কোনো Raw Newline ব্যবহার করবে না।

JSON ফরম্যাট:
{
  "chapterName": "অধ্যায়ের নাম",
  "classNumber": "ক্লাস নম্বর",
  "sections": [
    { "type": "title", "content": "শিরোনাম" },
    { "type": "header", "content": "সাব-শিরোনাম" },
    { "type": "text", "content": "বিস্তারিত আলোচনা" },
    { "type": "math", "content": "গাণিতিক সমীকরণ" },
    { "type": "box", "content": "গুরুত্বপূর্ণ নোট" },
    { "type": "list", "items": ["পয়েন্ট ১", "পয়েন্ট ২"] },
    { "type": "question", "qText": "প্রশ্ন এবং অপশন", "explanation": "বিস্তারিত ব্যাখ্যা" }
  ]
}
''';

  static const String _quizPrompt = '''
তুমি একজন বিশেষজ্ঞ শিক্ষক। এই ছবি থেকে একটি পূর্ণাঙ্গ প্র্যাক্টিস কুইজ সেট তৈরি করো।
আউটপুট অবশ্যই নিচের JSON ফরম্যাটে হতে হবে।

নির্দেশনা:
- ছবিতে থাকা **প্রতিটি প্রশ্ন** খুঁজে বের করো এবং কুইজে যোগ করো। কোনো প্রশ্ন বাদ দেবে না।
- সব কন্টেন্ট বাংলায় লিখবে।
- প্রতিটি প্রশ্নের জন্য ৪টি অপশন দেবে।
- correctAnswer হবে অপশনের ইনডেক্স (০ থেকে ৩)।
- বিস্তারিত ব্যাখ্যা দেবে।
- আউটপুট অবশ্যই একটি বৈধ COMPACT JSON হতে হবে এবং কোনো Raw Newline ব্যবহার করবে না।

JSON ফরম্যাট:
{
  "chapterName": "অধ্যায়ের নাম",
  "setName": "কুইজ সেটের নাম",
  "questions": [
    {
      "id": 1,
      "question": "প্রশ্নটি এখানে",
      "options": ["অপশন ১", "অপশন ২", "অপশন ৩", "অপশন ৪"],
      "correctAnswer": 0,
      "explanation": "বিস্তারিত ব্যাখ্যা"
    }
  ]
}
''';

  final GenerativeModel _model;


  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-3-flash-preview',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.2,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 8192,
          ),
        );

  Future<List<MCQQuestion>> extractMCQFromImageBytes(Uint8List imageBytes) async {
    return await _processImageWithPrompt(imageBytes, _prompt, (json) {
      final List<dynamic> questionsJson = json['questions'] ?? [];
      return questionsJson
          .map((q) => MCQQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList();
    });
  }

  Future<StudyClass> extractClassContent(Uint8List imageBytes) async {
    return await _processImageWithPrompt(imageBytes, _studyPrompt, (json) {
      return StudyClass.fromJson(Map<String, dynamic>.from(json));
    });
  }

  Future<QuizSet> generateQuiz(Uint8List imageBytes) async {
    return await _processImageWithPrompt(imageBytes, _quizPrompt, (json) {
      return QuizSet.fromJson(Map<String, dynamic>.from(json));
    });
  }

  Future<T> _processImageWithPrompt<T>(
    Uint8List imageBytes,
    String prompt,
    T Function(dynamic json) parser,
  ) async {
    try {
      final content = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ])
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';
      final cleaned = _cleanResponse(responseText);
      final json = jsonDecode(cleaned);
      return parser(json);
    } catch (e) {
      throw Exception('AI বিশ্লেষণে সমস্যা হয়েছে: $e');
    }
  }

  String _cleanResponse(String responseText) {
    String cleaned = responseText.trim();
    if (cleaned.startsWith('```')) {
      int firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      } else {
        cleaned = cleaned.substring(3);
      }
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    int firstBrace = cleaned.indexOf('{');
    int lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }
    return cleaned;
  }

  Future<List<MCQQuestion>> extractMCQFromImageFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return extractMCQFromImageBytes(bytes);
  }

  List<MCQQuestion> _parseResponse(String responseText) {
    try {
      final cleaned = _cleanResponse(responseText);
      final Map<String, dynamic> json = jsonDecode(cleaned);
      final List<dynamic> questionsJson = json['questions'] ?? [];
      return questionsJson
          .map((q) => MCQQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('উত্তর parse করতে সমস্যা হয়েছে: $e\n\nResponse: $responseText');
    }
  }
}
