class Scheme {
  final String id;
  final String nameEn;
  final String nameHi;
  final String nameMr;
  final String descriptionHi;
  final String descriptionMr;
  final List<String> intents;
  final List<String> eligibilityKeywords;
  final List<String> eligibilityQuestionsHi;
  final List<String> eligibilityQuestionsMr;

  Scheme({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.nameMr,
    required this.descriptionHi,
    required this.descriptionMr,
    required this.intents,
    required this.eligibilityKeywords,
    required this.eligibilityQuestionsHi,
    required this.eligibilityQuestionsMr,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'],
      nameEn: json['name_en'],
      nameHi: json['name_hi'],
      nameMr: json['name_mr'],
      descriptionHi: json['description_hi'],
      descriptionMr: json['description_mr'],
      intents: List<String>.from(json['intents']),
      eligibilityKeywords: List<String>.from(json['eligibility_keywords'] ?? []),
      eligibilityQuestionsHi: List<String>.from(json['eligibility_questions_hi']),
      eligibilityQuestionsMr: List<String>.from(json['eligibility_questions_mr']),
    );
  }

  String getName(String lang) {
    if (lang == 'hi') return nameHi;
    if (lang == 'mr') return nameMr;
    return nameEn;
  }

  String getDescription(String lang) {
    if (lang == 'hi') return descriptionHi;
    return descriptionMr;
  }
}
