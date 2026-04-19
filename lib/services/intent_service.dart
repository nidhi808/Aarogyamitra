class IntentService {
  final Map<String, List<String>> _intentKeywordsHi = {
    'maternal care': ['गर्भवती', 'बच्चा', 'प्रसव', 'महिला', 'जननी', 'मां', 'डिलीवरी'],
    'general illness': ['बीमार', 'बुखार', 'दर्द', 'इलाज', 'अस्पताल', 'दवा', 'डॉक्टर'],
    'emergency': ['आपातकालीन', 'एम्बुलेंस', 'गंभीर', 'तुरंत', 'चोट', 'दुर्घटना'],
  };

  final Map<String, List<String>> _intentKeywordsMr = {
    'maternal care': ['गर्भवती', 'बाळ', 'प्रसूती', 'स्त्री', 'जननी', 'आई', 'डिलीवरी'],
    'general illness': ['आजारी', 'ताप', 'दुखणे', 'उपचार', 'रुग्णालय', 'औषध', 'डॉक्टर'],
    'emergency': ['आणीबाणी', 'अम्बुलेंस', 'गंभीर', 'ताबडतोब', 'जखम', 'अपघात'],
  };

  String detectIntent(String text, String lang) {
    String normalizedText = text.toLowerCase();
    Map<String, List<String>> keywords = lang == 'hi' ? _intentKeywordsHi : _intentKeywordsMr;

    for (var entry in keywords.entries) {
      for (var keyword in entry.value) {
        if (normalizedText.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'unknown';
  }
}
