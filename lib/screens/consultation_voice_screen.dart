import 'package:flutter/material.dart';
import '../services/health_speech_service.dart';
import '../services/intent_service.dart';
import '../services/scheme_service.dart';
import '../services/facility_service.dart';
import '../services/response_service.dart';
import '../services/tts_service.dart';
import '../services/history_service.dart';
import '../services/knowledge_service.dart';
import '../services/csv_loader_service.dart';
import 'symptom_result_screen.dart';
import 'package:intl/intl.dart';

enum ConsultationStep {
  welcome,
  intro,
  confirmName,
  askAge,
  askProblem,
  confirmSymptoms,
  askResidency,
  finalSummary,
}

class ConsultationVoiceScreen extends StatefulWidget {
  final String initialLanguage;
  final HealthSpeechService speechService;
  final IntentService intentService;
  final SchemeService schemeService;
  final FacilityService facilityService;
  final ResponseService responseService;
  final TTSService ttsService;
  final KnowledgeService knowledgeService;
  final CsvLoaderService csvService;

  const ConsultationVoiceScreen({
    super.key,
    required this.initialLanguage,
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
  State<ConsultationVoiceScreen> createState() => _ConsultationVoiceScreenState();
}

class _ConsultationVoiceScreenState extends State<ConsultationVoiceScreen> {
  ConsultationStep _currentStep = ConsultationStep.welcome;
  late String _activeLanguage;
  String _status = "";
  String _transcript = "";
  bool _isListening = false;
  bool _isDisposed = false;

  final HistoryService _historyService = HistoryService();

  // Stored Data
  String _userName = "";
  String _userAge = "";
  String _userSymptoms = "";
  String _detectedSpeciality = "General Physician";
  bool _isLocal = true;

  @override
  void initState() {
    super.initState();
    _activeLanguage = widget.initialLanguage;
    _startFlow();
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.ttsService.stop();
    widget.speechService.stopListening();
    super.dispose();
  }

  Future<void> _startFlow() async {
    await _handleStep(ConsultationStep.welcome);
  }

  Future<void> _handleStep(ConsultationStep step) async {
    if (_isDisposed) return;
    
    setState(() => _currentStep = step);

    String question = "";
    Map<String, String> placeholders = {"name": _userName, "symptoms": _userSymptoms};

    switch (step) {
      case ConsultationStep.welcome:
        question = "नमस्ते! आरोग्यमित्र में आपका स्वागत है। आप किस भाषा में बात करना चाहेंगे? हिंदी या मराठी?";
        break;
      case ConsultationStep.intro:
        question = widget.responseService.getTranslation(_activeLanguage, "intro");
        break;
      case ConsultationStep.confirmName:
        question = _activeLanguage == 'hi' 
            ? "Aapne apna naam $_userName bataya, kya yeh sahi hai?"
            : "आपण आपले नाव $_userName सांगितले, हे बरोबर आहे का?";
        break;
      case ConsultationStep.askAge:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_age", placeholders);
        break;
      case ConsultationStep.askProblem:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_problem", placeholders);
        break;
      case ConsultationStep.confirmSymptoms:
        question = widget.responseService.getTranslation(_activeLanguage, "confirm_symptoms", placeholders);
        break;
      case ConsultationStep.askResidency:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_residency");
        break;
      case ConsultationStep.finalSummary:
        await _speakFinalSummaryAndNavigate();
        return;
    }

    if (_isDisposed) return;
    setState(() => _status = question);
    await widget.ttsService.speak(question, _activeLanguage);
    if (_isDisposed) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isDisposed) _listen();
  }

  Future<void> _speakFinalSummaryAndNavigate() async {
    if (_isDisposed) return;
    
    _detectedSpeciality = widget.csvService.analyzeSymptoms(_userSymptoms);
    final matchedDoctor = await widget.knowledgeService.findDoctorBySpeciality(_detectedSpeciality);
    var location = await widget.facilityService.getCurrentLocation();
    
    Map<String, dynamic>? hospitalData;
    if (location != null) {
      hospitalData = widget.facilityService.findNearestFacility(location);
    }

    String hospText = "";
    if (hospitalData != null) {
      hospText = widget.responseService.getTranslation(
        _activeLanguage, "nearest_hospital", {
          "facility": hospitalData['facility'].getName(_activeLanguage),
          "distance": hospitalData['distance']
        }
      );
    }

    String doctorText = _activeLanguage == 'hi' 
        ? " Humne aapke liye ${matchedDoctor?.name ?? 'ek doctor'} ko assign kiya hai jo ${_detectedSpeciality} ke specialist hain."
        : " आम्ही तुमच्यासाठी ${matchedDoctor?.name ?? 'एक डॉक्टर'} नियुक्त केला आहे जो ${_detectedSpeciality} तज्ञ आहे.";

    String fullResponse = "$hospText $doctorText";

    if (_isDisposed) return;
    setState(() => _status = fullResponse);
    await widget.ttsService.speak(fullResponse, _activeLanguage);
    
    // Save to history
    await _historyService.saveSummary(
      name: _userName,
      age: _userAge,
      symptoms: _userSymptoms,
      scheme: "General Healthcare",
      facility: "Assigned: ${matchedDoctor?.name ?? 'Dr. Rahul'} (${matchedDoctor?.speciality ?? 'General Surgeon'})", 
      date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
    );

    if (mounted && !_isDisposed) {
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (context) => SymptomResultScreen(
             language: _activeLanguage,
             userName: _userName,
             userAge: _userAge,
             userSymptoms: _userSymptoms,
             matchedDoctor: matchedDoctor,
             facility: hospitalData?['facility'],
             distance: hospitalData != null ? double.tryParse(hospitalData['distance'].toString()) : null,
             status: _status,
           ),
         ),
       );
    }
  }

  Future<void> _listen() async {
    if (_isDisposed) return;
    setState(() {
      _isListening = true;
      _transcript = "";
    });

    String locale = (_activeLanguage == 'hi') ? 'hi_IN' : 'mr_IN';
    if (_currentStep == ConsultationStep.welcome) locale = 'hi_IN';

    String result = await widget.speechService.listenOnce(
      localeId: locale,
      timeout: const Duration(seconds: 10),
    );
    
    if (_isDisposed) return;
    
    // Check for specific errors
    if (widget.speechService.lastError.contains("language_unavailable")) {
      String msg = (_activeLanguage == 'hi') 
          ? "माफ़ करें, इस भाषा का डेटा आपके फोन पर ऑफलाइन उपलब्ध नहीं है। कृपया सेटिंग्स से भाषा पैक डाउनलोड करें।"
          : "क्षमस्व, या भाषेचा डेटा तुमच्या फोनवर ऑफलाइन उपलब्ध नाही. कृपया सेटिंग्जमधून भाषा पॅक डाउनलोड करा.";
      setState(() => _status = msg);
      await widget.ttsService.speak(msg, _activeLanguage);
      await Future.delayed(const Duration(seconds: 3));
    }

    setState(() {
      _isListening = false;
      _transcript = result;
    });

    _processInput(result);
  }

  void _processInput(String input) {
    if (_isDisposed) return;
    String lower = input.toLowerCase().trim();
    if (lower.isEmpty) {
       _handleStep(_currentStep);
       return;
    }

    switch (_currentStep) {
      case ConsultationStep.welcome:
        _activeLanguage = (lower.contains("marathi") || lower.contains("मराठी") || lower.contains("mr")) ? 'mr' : 'hi';
        _handleStep(ConsultationStep.intro);
        break;
      case ConsultationStep.intro:
        _userName = input;
        _handleStep(ConsultationStep.confirmName);
        break;
      case ConsultationStep.confirmName:
        _isNo(input) ? _handleStep(ConsultationStep.intro) : _handleStep(ConsultationStep.askAge);
        break;
      case ConsultationStep.askAge:
        _userAge = input;
        _handleStep(ConsultationStep.askProblem);
        break;
      case ConsultationStep.askProblem:
        _userSymptoms = input;
        _handleStep(ConsultationStep.confirmSymptoms);
        break;
      case ConsultationStep.confirmSymptoms:
        _isNo(input) ? _handleStep(ConsultationStep.askProblem) : _handleStep(ConsultationStep.askResidency);
        break;
      case ConsultationStep.askResidency:
        _isLocal = _isYes(input);
        _handleStep(ConsultationStep.finalSummary);
        break;
      default: break;
    }
  }

  bool _isYes(String text) {
     String lower = text.toLowerCase();
     return lower.contains("हाँ") || lower.contains("हो") || lower.contains("yes") || 
            lower.contains("haan") || lower.contains("ha") || lower.contains("ok");
  }

  bool _isNo(String text) {
     String lower = text.toLowerCase();
     return lower.contains("नहीं") || lower.contains("नाही") || lower.contains("no") || 
            lower.contains("na") || lower.contains("galat") || lower.contains("nahi");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          "स्वास्थ्य परामर्श",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F5238)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (_currentStep.index + 1) / ConsultationStep.values.length,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle, 
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))]
                    ),
                    child: Center(child: Icon(_isListening ? Icons.hearing_outlined : Icons.face_outlined, size: 60, color: colorScheme.primary)),
                  ),
                  const SizedBox(height: 48),
                  Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1C1C19), height: 1.4)),
                  const SizedBox(height: 40),
                  if (_transcript.isNotEmpty || _isListening)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isListening ? "सुन रहे हैं..." : "सुना गया:", style: const TextStyle(fontSize: 12, color: Color(0xFF0F5238), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_isListening ? "Listening..." : _transcript, style: TextStyle(fontSize: 16, fontStyle: _isListening ? FontStyle.italic : FontStyle.normal, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildBottomIndicator(context),
        ],
      ),
    );
  }

  Widget _buildBottomIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(color: Color(0xFFF6F3EE), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isListening ? Icons.mic_rounded : Icons.volume_up_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isListening ? "प्रतिक्रिया दें" : "सुनें", style: const TextStyle(color: Color(0xFF0F5238), fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_isListening ? "Say something..." : "Asha is speaking...", style: TextStyle(color: const Color(0xFF0F5238).withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
