import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/scheme.dart';

class SchemeService {
  List<Scheme> _schemes = [];

  Future<void> loadSchemes() async {
    final String response = await rootBundle.loadString('assets/data/schemes.json');
    final data = await json.decode(response);
    _schemes = (data as List).map((s) => Scheme.fromJson(s)).toList();
  }

  List<Scheme> getSchemesByIntent(String intent) {
    if (intent == 'unknown') return _schemes;
    return _schemes.where((scheme) => scheme.intents.contains(intent)).toList();
  }

  Scheme? getSchemeById(String id) {
    try {
      return _schemes.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
