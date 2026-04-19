import 'package:flutter/material.dart';
import '../models/scheme_rule.dart';
import '../models/facility.dart';

class SchemeResultScreen extends StatelessWidget {
  final String language;
  final String? userName;
  final String? userAge;
  final String? userSymptoms;
  final SchemeRule? matchedScheme;
  final Facility? facility;
  final double? distance;
  final String status;

  const SchemeResultScreen({
    super.key,
    required this.language,
    this.userName,
    this.userAge,
    this.userSymptoms,
    this.matchedScheme,
    this.facility,
    this.distance,
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
          language == 'hi' ? "योजना विवरण" : "योजना तपशील",
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
            language == 'hi' ? "योजना सारांश" : "योजना सारांश",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F5238)),
          ),
          const SizedBox(height: 24),
          _buildRow("PATIENT NAME", userName ?? "Unknown"),
          const SizedBox(height: 16),
          _buildRow("AGE", "${userAge ?? '0'} Years"),
          const SizedBox(height: 16),
          _buildRow("PROBLEM", userSymptoms ?? "General"),
          
          const Divider(height: 32, thickness: 1, color: Color(0xFFEEEEEE)),
          
          if (matchedScheme != null) ...[
             _buildRow("ELIGIBLE SCHEME", matchedScheme!.scheme),
             const SizedBox(height: 16),
             _buildRow("BENEFIT", matchedScheme!.benefit),
             const SizedBox(height: 16),
             _buildRow("REQUIRED DOCUMENTS", matchedScheme!.documents),
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
