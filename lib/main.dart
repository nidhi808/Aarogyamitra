import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/health_speech_service.dart';
import 'services/intent_service.dart';
import 'services/scheme_service.dart';
import 'services/facility_service.dart';
import 'services/response_service.dart';
import 'services/tts_service.dart';
import 'services/knowledge_service.dart';
import 'services/csv_loader_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize synchronous services
  final speechService = HealthSpeechService();
  final intentService = IntentService();
  final schemeService = SchemeService();
  final facilityService = FacilityService();
  final responseService = ResponseService();
  final ttsService = TTSService();
  final knowledgeService = KnowledgeService();
  final csvService = CsvLoaderService();

  runApp(VoiceHealthApp(
    speechService: speechService,
    intentService: intentService,
    schemeService: schemeService,
    facilityService: facilityService,
    responseService: responseService,
    ttsService: ttsService,
    knowledgeService: knowledgeService,
    csvService: csvService,
  ));
}

class VoiceHealthApp extends StatefulWidget {
  final HealthSpeechService speechService;
  final IntentService intentService;
  final SchemeService schemeService;
  final FacilityService facilityService;
  final ResponseService responseService;
  final TTSService ttsService;
  final KnowledgeService knowledgeService;
  final CsvLoaderService csvService;

  const VoiceHealthApp({
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

  @override
  State<VoiceHealthApp> createState() => _VoiceHealthAppState();
}

class _VoiceHealthAppState extends State<VoiceHealthApp> {
  bool _isReady = false;
  String _loadingStatus = "Starting Aarogyamitra...";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _loadingStatus = "Loading Speech Engine...");
      await widget.speechService.init();
      
      setState(() => _loadingStatus = "Loading Medical Knowledge...");
      await widget.schemeService.loadSchemes();
      await widget.facilityService.loadFacilities();
      await widget.responseService.loadTranslations();
      await widget.ttsService.init();

      setState(() => _loadingStatus = "Loading CSV Datasets...");
      await widget.csvService.loadDoctors();
      await widget.csvService.loadHospitals();
      await widget.csvService.loadSchemeRules();

      setState(() => _loadingStatus = "Finalizing Index...");
      await widget.knowledgeService.init(csvService: widget.csvService);

      await Future.delayed(const Duration(milliseconds: 200)); // Quick transition
      
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      setState(() => _loadingStatus = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Health Navigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5238), // Neem
          primary: const Color(0xFF0F5238),   // Neem
          secondary: const Color(0xFF8E4E14), // Haldi
          tertiary: const Color(0xFF940011),  // Emergency Red
          surface: const Color(0xFFFCF9F4),   // Mitti
          onSurface: const Color(0xFF1C1C19),
        ),
        scaffoldBackgroundColor: const Color(0xFFFCF9F4), // Mitti base
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(),
        ),
      ),
      home: _isReady 
        ? HomeScreen(
            speechService: widget.speechService,
            intentService: widget.intentService,
            schemeService: widget.schemeService,
            facilityService: widget.facilityService,
            responseService: widget.responseService,
            ttsService: widget.ttsService,
            knowledgeService: widget.knowledgeService,
            csvService: widget.csvService,
          )
        : _buildSplash(),
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 24),
            const Text(
              "Aarogyamitra",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Color(0xFF2E7D32)),
            const SizedBox(height: 24),
            Text(
              _loadingStatus,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
