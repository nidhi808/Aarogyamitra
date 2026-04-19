import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class HealthSpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  String _lastRecognizedWords = '';
  String _lastError = '';
  bool _isLanguagePackMissing = false;

  String get lastError => _lastError;
  bool get isLanguagePackMissing => _isLanguagePackMissing;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;

  Future<void> init() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          print('Speech recognition error: ${error.errorMsg}');
          _lastError = error.errorMsg;
          if (error.errorMsg.contains("language_unavailable")) {
            _isLanguagePackMissing = true;
          }
        },
        onStatus: (String status) {
          print('Speech recognition status: $status');
        },
      );
      
      if (_isInitialized) {
        final locales = await _speech.locales();
        print("Speech recognition: Available locales found: ${locales.length}");
        
        final hasHindi = locales.any((l) => l.localeId.toLowerCase().startsWith("hi"));
        final hasMarathi = locales.any((l) => l.localeId.toLowerCase().startsWith("mr"));
        
        final marathiLocale = locales.firstWhere(
          (l) => l.localeId.toLowerCase().startsWith("mr"),
          orElse: () => locales.first,
        );
        
        if (!hasHindi) {
          print("WARNING: Hindi offline pack NOT found.");
        } else {
          final hId = locales.firstWhere((l) => l.localeId.toLowerCase().startsWith("hi")).localeId;
          print("SUCCESS: Hindi Offline READY. (ID: $hId)");
        }
        
        if (!hasMarathi) {
          print("INFO: Marathi pack missing from system. App will automatically use Hindi fallback for safety.");
        } else {
          print("SUCCESS: Marathi Offline READY. (ID: ${marathiLocale.localeId})");
        }
        
        for (var l in locales) {
          if (l.localeId.contains("hi") || l.localeId.contains("mr")) {
            print("Speech recognition: Found relevant locale: ${l.name} (${l.localeId})");
          }
        }
      } else {
        print('CRITICAL: Speech recognition initialization failed. Check Permissions.');
      }
    } catch (e) {
      print('Speech Init Error: $e');
      _isInitialized = false;
    }
  }

  // Listen and return result via callback
  Future<void> startListening({
    required Function(String text) onResult,
    String localeId = 'hi_IN', // hi_IN = Hindi, mr_IN = Marathi
  }) async {
    if (!_isInitialized) await init();

    if (_isInitialized && !_speech.isListening) {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastRecognizedWords = result.recognizedWords;
          onResult(result.recognizedWords);
        },
        localeId: localeId,
        onDevice: true,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    }
  }

  // Listen and return result as a Future (replaces listenSample)
  Future<String> listenOnce({
    String localeId = 'hi_IN',
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return '';

    _lastError = '';
    _isLanguagePackMissing = false;
    final completer = Completer<String>();

    String finalLocaleId = localeId; // Fallback to whatever was requested
    
    // Direct Mapping for Speed
    if (localeId.startsWith('hi')) {
      finalLocaleId = 'hi_IN';
    } else if (localeId.startsWith('mr')) {
      final locales = await _speech.locales();
      finalLocaleId = locales.any((l) => l.localeId.startsWith('mr')) 
          ? 'mr_IN' 
          : 'hi_IN';
    }

    print("STT: Final ID: $finalLocaleId");

    // Safety Delay: Give the system time to switch from TTS output to Mic input
    await Future.delayed(const Duration(milliseconds: 500));

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(result.recognizedWords);
        }
      },
      localeId: finalLocaleId,
      listenMode: ListenMode.dictation,
      cancelOnError: true,
      partialResults: false,
    );

    // Timeout fallback
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        _speech.stop();
        completer.complete(_lastRecognizedWords);
      }
    });

    return completer.future;
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  // Get available locales (useful to check if hi_IN or mr_IN is available)
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) await init();
    return await _speech.locales();
  }

  void dispose() {
    _speech.cancel();
  }
}
