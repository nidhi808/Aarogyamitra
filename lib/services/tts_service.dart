import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  Completer<void>? _speechCompleter;

  Future<void> init() async {
    final engines = await _flutterTts.getEngines;
    print("TTS: Available system engines: $engines");
    
    // Favor non-Google engines if available
    String? bestEngine;
    for (var engine in engines) {
      if (engine.toString().contains("google")) continue;
      bestEngine = engine.toString();
      break;
    }
    
    if (bestEngine != null) {
      print("TTS: Selecting non-google engine: $bestEngine");
      await _flutterTts.setEngine(bestEngine);
    }

    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    });
  }

  Future<void> speak(String text, String lang) async {
    // If already speaking, stop first
    await stop();
    
    _speechCompleter = Completer<void>();
    
    String languageCode = lang == 'hi' ? "hi-IN" : "mr-IN";
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.speak(text);
    
    return _speechCompleter!.future;
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      _speechCompleter!.complete();
    }
  }
}
