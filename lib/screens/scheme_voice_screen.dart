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
import '../models/scheme_rule.dart';
import 'scheme_result_screen.dart';
import 'package:intl/intl.dart';

enum SchemeStep {
  welcome,
  intro,
  confirmName,
  askAge,
  askProblem,
  confirmSymptoms,
  confirmDisclaimer,
  askBPL,
  askAyushman,
  askWhiteRation,
  askResidency,
  finalSummary,
}

class SchemeVoiceScreen extends StatefulWidget {
  final String initialLanguage;
  final HealthSpeechService speechService;
  final IntentService intentService;
  final SchemeService schemeService;
  final FacilityService facilityService;
  final ResponseService responseService;
  final TTSService ttsService;
  final KnowledgeService knowledgeService;
  final CsvLoaderService csvService;

  const SchemeVoiceScreen({
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
  State<SchemeVoiceScreen> createState() => _SchemeVoiceScreenState();
}

class _SchemeVoiceScreenState extends State<SchemeVoiceScreen> {
  SchemeStep _currentStep = SchemeStep.welcome;
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
  bool _hasBPL = false;
  bool _hasAyushman = false;
  bool _hasWhiteRation = false;
  bool _isLocal = true;
  SchemeRule? _matchedScheme;

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
    await _handleStep(SchemeStep.welcome);
  }

  Future<void> _handleStep(SchemeStep step) async {
    if (_isDisposed) return;
    
    setState(() => _currentStep = step);

    String question = "";
    Map<String, String> placeholders = {"name": _userName, "symptoms": _userSymptoms};

    switch (step) {
      case SchemeStep.welcome:
        question = "नमस्ते! आरोग्यमित्र में आपका स्वागत है। आप किस भाषा में बात करना चाहेंगे? हिंदी या मराठी?";
        break;
      case SchemeStep.intro:
        question = widget.responseService.getTranslation(_activeLanguage, "intro");
        break;
      case SchemeStep.confirmName:
        question = _activeLanguage == 'hi' 
            ? "Aapne apna naam $_userName bataya, kya yeh sahi hai?"
            : "आपण आपले नाव $_userName सांगितले, हे बरोबर आहे का?";
        break;
      case SchemeStep.askAge:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_age", placeholders);
        break;
      case SchemeStep.askProblem:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_problem", placeholders);
        break;
      case SchemeStep.confirmSymptoms:
        question = widget.responseService.getTranslation(_activeLanguage, "confirm_symptoms", placeholders);
        break;
      case SchemeStep.confirmDisclaimer:
        question = widget.responseService.getTranslation(_activeLanguage, "disclaimer", placeholders);
        break;
      case SchemeStep.askBPL:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_bpl");
        break;
      case SchemeStep.askAyushman:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_ayushman");
        break;
      case SchemeStep.askWhiteRation:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_white_ration");
        break;
      case SchemeStep.askResidency:
        question = widget.responseService.getTranslation(_activeLanguage, "ask_residency");
        break;
      case SchemeStep.finalSummary:
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
    
    final matchingRules = widget.csvService.getMatchingSchemes(
      symptoms: _userSymptoms,
      hasBpl: _hasBPL,
      hasAyushman: _hasAyushman,
      hasWhiteRation: _hasWhiteRation,
      isLocal: _isLocal,
    );

    _matchedScheme = matchingRules.isNotEmpty ? matchingRules.first : null;
    String schemeName = _matchedScheme?.scheme ?? "General Healthcare";

    String eligibleText = widget.responseService.getTranslation(
      _activeLanguage, "eligible_for", {"name": _userName, "scheme": schemeName}
    );

    String benefitText = (_matchedScheme != null) ? "\n\nBenefits: ${_matchedScheme!.benefit}" : "";
    String fullResponse = "$eligibleText $benefitText";

    if (_isDisposed) return;
    setState(() => _status = fullResponse);
    await widget.ttsService.speak(fullResponse, _activeLanguage);
    
    // Save to history
    await _historyService.saveSummary(
      name: _userName,
      age: _userAge,
      symptoms: _userSymptoms,
      scheme: _matchedScheme?.scheme ?? "General Healthcare",
      facility: "Government Health Center", 
      date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
    );

    if (mounted && !_isDisposed) {
       var location = await widget.facilityService.getCurrentLocation();
       Map<String, dynamic>? hospitalData;
       if (location != null) {
         hospitalData = widget.facilityService.findNearestFacility(location);
       }

       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (context) => SchemeResultScreen(
             language: _activeLanguage,
             userName: _userName,
             userAge: _userAge,
             userSymptoms: _userSymptoms,
             matchedScheme: _matchedScheme,
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
    if (_currentStep == SchemeStep.welcome) locale = 'hi_IN';

    String result = await widget.speechService.listenOnce(localeId: locale, timeout: const Duration(seconds: 10));
    
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
    if (lower.isEmpty) { _handleStep(_currentStep); return; }

    switch (_currentStep) {
      case SchemeStep.welcome:
        _activeLanguage = (lower.contains("marathi") || lower.contains("मराठी") || lower.contains("mr")) ? 'mr' : 'hi';
        _handleStep(SchemeStep.intro);
        break;
      case SchemeStep.intro:
        _userName = input;
        _handleStep(SchemeStep.confirmName);
        break;
      case SchemeStep.confirmName:
        _isNo(input) ? _handleStep(SchemeStep.intro) : _handleStep(SchemeStep.askAge);
        break;
      case SchemeStep.askAge:
        _userAge = input;
        _handleStep(SchemeStep.askProblem);
        break;
      case SchemeStep.askProblem:
        _userSymptoms = input;
        _handleStep(SchemeStep.confirmSymptoms);
        break;
      case SchemeStep.confirmSymptoms:
        _isNo(input) ? _handleStep(SchemeStep.askProblem) : _handleStep(SchemeStep.confirmDisclaimer);
        break;
      case SchemeStep.confirmDisclaimer:
        _handleStep(SchemeStep.askBPL);
        break;
      case SchemeStep.askBPL:
        _hasBPL = _isYes(input);
        _handleStep(SchemeStep.askAyushman);
        break;
      case SchemeStep.askAyushman:
        _hasAyushman = _isYes(input);
        _handleStep(SchemeStep.askWhiteRation);
        break;
      case SchemeStep.askWhiteRation:
        _hasWhiteRation = _isYes(input);
        _handleStep(SchemeStep.askResidency);
        break;
      case SchemeStep.askResidency:
        _isLocal = _isYes(input);
        _handleStep(SchemeStep.finalSummary);
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
        title: const Text("योजना खोज", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F5238))),
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.close, color: colorScheme.primary), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (_currentStep.index + 1) / SchemeStep.values.length,
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
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))]),
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
