import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/health_speech_service.dart';
import '../services/intent_service.dart';
import '../services/scheme_service.dart';
import '../services/facility_service.dart';
import '../services/response_service.dart';
import '../services/tts_service.dart';
import '../services/history_service.dart';
import '../services/knowledge_service.dart';
import '../services/csv_loader_service.dart';
import 'scheme_voice_screen.dart';
import 'consultation_voice_screen.dart';
import 'nearby_hospitals_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  final HealthSpeechService speechService;
  final IntentService intentService;
  final SchemeService schemeService;
  final FacilityService facilityService;
  final ResponseService responseService;
  final TTSService ttsService;
  final KnowledgeService knowledgeService;
  final CsvLoaderService csvService;
  final HistoryService historyService = HistoryService();

  HomeScreen({
    super.key,
    required this.speechService,
    required this.intentService,
    required this.schemeService,
    required this.facilityService,
    required this.responseService,
    required this.ttsService,
    required this.knowledgeService,
    required this.csvService,
  });

  Future<void> _makeEmergencyCall() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '9076200636',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _buildHeader(context),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildDashboard(context),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Text(
        "Aarogyamitra",
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.w800, 
          color: Color(0xFF0F5238),
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F5238)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "नमस्ते, आरोग्य मित्र! 🙏",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C19),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            " ",
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF404943).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F5238).withOpacity(0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _buildConsultationButton(context),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context, 
                  Icons.local_hospital_outlined, 
                  "अस्पताल\nHospitals", 
                  const Color(0xFF0F5238),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => NearbyHospitalsScreen(knowledgeService: knowledgeService, facilityService: facilityService, language: 'hi')))
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context, 
                  Icons.assignment_outlined, 
                  "योजनाएं\nSchemes", 
                  const Color(0xFF8E4E14),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => SchemeVoiceScreen(
                    initialLanguage: 'hi', 
                    speechService: speechService, 
                    intentService: intentService, 
                    schemeService: schemeService, 
                    facilityService: facilityService, 
                    responseService: responseService, 
                    ttsService: ttsService, 
                    knowledgeService: knowledgeService, 
                    csvService: csvService,
                  )))
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context, 
                  Icons.history_outlined, 
                  "इतिहास\nHistory", 
                  const Color(0xFF404943),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(historyService: historyService, language: 'hi')))
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEmergencyButton(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsultationVoiceScreen(
            initialLanguage: 'hi',
            speechService: speechService,
            intentService: intentService,
            schemeService: schemeService,
            facilityService: facilityService,
            responseService: responseService,
            ttsService: ttsService,
            knowledgeService: knowledgeService,
            csvService: csvService,
          ),
        ),
      ),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: const Color(0xFF0F5238),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F5238).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, bottom: -20,
              child: Icon(Icons.mic_none_outlined, size: 100, color: Colors.white.withOpacity(0.1)),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_none_outlined, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "सलाह शुरू करें",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Start Voice Consultation",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return InkWell(
      onTap: _makeEmergencyCall,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF940011).withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency_outlined, color: Color(0xFF940011), size: 32),
            const SizedBox(height: 12),
            Text(
              "आपातकालीन\nEmergency",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF940011), 
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1C1C19),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
