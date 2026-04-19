import 'package:flutter/material.dart';

import '../services/history_service.dart';
import 'symptom_result_screen.dart';

class HistoryScreen extends StatelessWidget {
  final HistoryService historyService;
  final String language;

  const HistoryScreen({
    super.key,
    required this.historyService,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          language == 'hi' ? "स्वास्थ्य इतिहास" : "आरोग्य इतिहास",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: historyService.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    language == 'hi' ? "कोई इतिहास नहीं मिला" : "काहीही रेकॉर्ड सापडले नाही",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white, // surface-container-lowest
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle
                    ),
                    child: Icon(Icons.badge_outlined, color: colorScheme.primary),
                  ),
                  title: Row(
                    children: [
                      Text(
                        log['name'], 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          "${log['age']}Y", 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.secondary)
                        ),
                      )
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['symptoms'], 
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log['date'], 
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SymptomResultScreen(
                          language: language,
                          userName: log['name'],
                          userAge: log['age'],
                          userSymptoms: log['symptoms'],
                          status: "History View",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
