class MCQQuestion {
  final String number;
  final String question;
  final Map<String, String> options;
  final String correctAnswer;
  final String explanation;
  final String? subject;

  MCQQuestion({
    required this.number,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.subject,
  });

  factory MCQQuestion.fromJson(Map<String, dynamic> json) {
    return MCQQuestion(
      number: json['number']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: Map<String, String>.from(json['options'] ?? {}),
      correctAnswer: json['correct_answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      subject: json['subject']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'subject': subject,
    };
  }
}

class ScanResult {
  final List<MCQQuestion> questions;
  final DateTime scannedAt;
  final String? imagePath;

  ScanResult({
    required this.questions,
    required this.scannedAt,
    this.imagePath,
  });
}
