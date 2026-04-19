import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _key = 'smartcards_history';

  Future<void> saveSummary({
    required String name,
    required String age,
    required String symptoms,
    required String scheme,
    required String facility,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    
    final Map<String, String> entry = {
      'name': name,
      'age': age,
      'symptoms': symptoms,
      'scheme': scheme,
      'facility': facility,
      'date': date,
    };
    
    history.add(json.encode(entry));
    await prefs.setStringList(_key, history);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStr = prefs.getStringList(_key) ?? [];
    return historyStr.map((s) => json.decode(s) as Map<String, dynamic>).toList().reversed.toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
