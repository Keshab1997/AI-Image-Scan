class StudyClass {
  final String chapterName;
  final String classNumber;
  final List<StudySection> sections;

  StudyClass({
    required this.chapterName,
    required this.classNumber,
    required this.sections,
  });

  Map<String, dynamic> toJson() {
    return {
      'chapterName': chapterName,
      'classNumber': classNumber,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }

  factory StudyClass.fromJson(Map<String, dynamic> json) {
    return StudyClass(
      chapterName: json['chapterName'] ?? '',
      classNumber: json['classNumber'] ?? '',
      sections: (json['sections'] as List)
          .map((s) => StudySection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudySection {
  final String type; // title, header, text, math, box, list, question
  final String? content;
  final List<String>? items;
  final String? qText;
  final String? explanation;

  StudySection({
    required this.type,
    this.content,
    this.items,
    this.qText,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type};
    if (content != null) map['content'] = content;
    if (items != null) map['items'] = items;
    if (qText != null) map['qText'] = qText;
    if (explanation != null) map['explanation'] = explanation;
    return map;
  }

  factory StudySection.fromJson(Map<String, dynamic> json) {
    return StudySection(
      type: json['type'] ?? 'text',
      content: json['content'],
      items: json['items'] != null ? List<String>.from(json['items']) : null,
      qText: json['qText'],
      explanation: json['explanation'],
    );
  }
}

class QuizSet {
  final String chapterName;
  final String setName;
  final List<QuizQuestion> questions;

  QuizSet({
    required this.chapterName,
    required this.setName,
    required this.questions,
  });

  Map<String, dynamic> toJson() {
    return {
      'chapterName': chapterName,
      'setName': setName,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    return QuizSet(
      chapterName: json['chapterName'] ?? '',
      setName: json['setName'] ?? '',
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}
