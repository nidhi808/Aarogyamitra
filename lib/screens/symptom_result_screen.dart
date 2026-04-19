import 'package:flutter/material.dart';
import '../models/facility.dart';
import '../services/knowledge_service.dart';

class SymptomResultScreen extends StatelessWidget {
  final String language;
  final String userName;
  final String userAge;
  final String userSymptoms;
  final Facility? facility;
  final double? distance;
  final Doctor? matchedDoctor;
  final String status;

  const SymptomResultScreen({
    super.key,
    required this.language,
    required this.userName,
    required this.userAge,
    required this.userSymptoms,
    this.facility,
    this.distance,
    this.matchedDoctor,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          language == 'hi' ? "स्वास्थ्य रिपोर्ट" : "आरोग्य अहवाल",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUnifiedSummaryCard(context),
            const SizedBox(height: 40),
            _buildHomeButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 15))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language == 'hi' ? "स्वास्थ्य सारांश" : "आरोग्य सारांश",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F5238)),
          ),
          const SizedBox(height: 24),
          _buildRow("PATIENT NAME", userName),
          const SizedBox(height: 16),
          _buildRow("AGE", "$userAge Years"),
          const SizedBox(height: 16),
          _buildRow("SYMPTOMS", userSymptoms),
          
          const Divider(height: 32, thickness: 1, color: Color(0xFFEEEEEE)),
          
          if (matchedDoctor != null) ...[
            _buildRow("SUGGESTED DOCTOR", "${matchedDoctor!.name} (${matchedDoctor!.speciality})"),
            const SizedBox(height: 16),
          ],
          
          _buildRow("NEARBY HOSPITAL", facility?.getName(language) ?? "Government Health Center"),
          if (distance != null)
             Padding(
               padding: const EdgeInsets.only(top: 4),
               child: Text(
                 "${distance!.toStringAsFixed(1)} km away • Verified",
                 style: const TextStyle(fontSize: 12, color: Color(0xFF8E4E14), fontWeight: FontWeight.bold),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C1C19))),
      ],
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF0F5238),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0F5238).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
          ]
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                language == 'hi' ? "मुख्य पृष्ठ" : "मुख्य पृष्ठ",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
