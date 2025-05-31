import '../core/extractor_config.dart';
import '../core/localization_entry.dart';
import '../core/extracted_string.dart';
import 'ai_client.dart';

/// Professional translator that uses AI to generate high-quality translations
class ProfessionalTranslator {
  final ExtractorConfig config;
  final AiClient _aiClient;
  final RateLimiter _rateLimiter;
  
  // Language code to language name mapping
  static const Map<String, String> _languageNames = {
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'zh': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'pt': 'Portuguese',
    'it': 'Italian',
    'ru': 'Russian',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'pl': 'Polish',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'he': 'Hebrew',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'id': 'Indonesian',
    'ms': 'Malay',
    'uk': 'Ukrainian',
    'cs': 'Czech',
    'sk': 'Slovak',
    'hu': 'Hungarian',
    'ro': 'Romanian',
    'bg': 'Bulgarian',
    'hr': 'Croatian',
    'sr': 'Serbian',
    'sl': 'Slovenian',
    'et': 'Estonian',
    'lv': 'Latvian',
    'lt': 'Lithuanian',
    'mt': 'Maltese',
    'ga': 'Irish',
    'cy': 'Welsh',
    'is': 'Icelandic',
    'mk': 'Macedonian',
    'sq': 'Albanian',
    'eu': 'Basque',
    'ca': 'Catalan',
    'gl': 'Galician',
    'af': 'Afrikaans',
    'sw': 'Swahili',
    'am': 'Amharic',
    'bn': 'Bengali',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'mr': 'Marathi',
    'ne': 'Nepali',
    'or': 'Odia',
    'pa': 'Punjabi',
    'si': 'Sinhala',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ur': 'Urdu',
    'fa': 'Persian',
    'ps': 'Pashto',
    'ku': 'Kurdish',
    'az': 'Azerbaijani',
    'kk': 'Kazakh',
    'ky': 'Kyrgyz',
    'mn': 'Mongolian',
    'my': 'Myanmar (Burmese)',
    'km': 'Khmer',
    'lo': 'Lao',
    'ka': 'Georgian',
    'hy': 'Armenian',
  };
  
  ProfessionalTranslator(this.config)
      : _aiClient = AiClient.create(config),
        _rateLimiter = RateLimiter(maxRequestsPerMinute: 30);

  /// Translates all localization entries to the configured languages
  Future<void> translateEntries(List<LocalizationEntry> entries) async {
    print('Starting translation for ${config.languages.length} languages...');
    
    for (final languageCode in config.languages) {
      if (languageCode == 'en') continue; // Skip English as it's the source
      
      print('Translating to ${_getLanguageName(languageCode)}...');
      await _translateToLanguage(entries, languageCode);
      
      // Delay between languages to respect rate limits
      await Future.delayed(const Duration(seconds: 2));
    }
    
    print('Translation completed for all languages.');
  }
  
  /// Translates entries to a specific language
  Future<void> _translateToLanguage(List<LocalizationEntry> entries, String languageCode) async {
    final languageName = _getLanguageName(languageCode);
    
    // Group entries by context for better translation consistency
    final contextGroups = _groupEntriesByContext(entries);
    
    for (final group in contextGroups) {
      try {
        await _translateGroup(group, languageCode, languageName);
      } catch (e) {
        print('Warning: Failed to translate group to $languageName: $e');
        // Fallback to individual translation
        await _translateIndividually(group, languageCode, languageName);
      }
    }
  }
  
  /// Groups entries by context for consistent translation
  List<List<LocalizationEntry>> _groupEntriesByContext(List<LocalizationEntry> entries) {
    final groups = <String, List<LocalizationEntry>>{};
    
    for (final entry in entries) {
      final contextKey = _getContextKey(entry);
      groups.putIfAbsent(contextKey, () => []).add(entry);
    }
    
    // Split large groups into smaller batches
    final result = <List<LocalizationEntry>>[];
    for (final group in groups.values) {
      if (group.length <= 5) {
        result.add(group);
      } else {
        // Split into smaller batches
        for (int i = 0; i < group.length; i += 5) {
          final end = (i + 5 < group.length) ? i + 5 : group.length;
          result.add(group.sublist(i, end));
        }
      }
    }
    
    return result;
  }
  
  /// Gets a context key for grouping entries
  String _getContextKey(LocalizationEntry entry) {
    final parts = <String>[];
    
    if (entry.contextType != null) {
      parts.add(entry.contextType!.name);
    }
    
    if (entry.widgetType != null) {
      parts.add(entry.widgetType!);
    }
    
    if (entry.extractedString.context?.screenContext != null) {
      parts.add(entry.extractedString.context!.screenContext!);
    }
    
    return parts.isEmpty ? 'general' : parts.join('_');
  }
  
  /// Translates a group of entries together for consistency
  Future<void> _translateGroup(List<LocalizationEntry> group, String languageCode, String languageName) async {
    await _rateLimiter.waitIfNeeded();
    
    final texts = group.map((e) => e.originalText).toList();
    final context = _buildGroupContext(group);
    
    final prompt = PromptTemplates.batchTranslationTemplate(
      texts: texts,
      targetLanguage: languageName,
      context: context,
    );
    
    final response = await _aiClient.sendPrompt(prompt, options: {
      'temperature': 0.2, // Low temperature for consistent translations
      'max_tokens': 2000,
    });
    
    final translations = _parseTranslationResponse(response, texts.length);
    
    if (translations.length != texts.length) {
      throw Exception('Translation count mismatch: expected ${texts.length}, got ${translations.length}');
    }
    
    // Apply translations to entries
    for (int i = 0; i < group.length; i++) {
      final entry = group[i];
      final translation = translations[i].trim();
      
      if (translation.isNotEmpty) {
        final updatedEntry = entry.addTranslation(languageCode, translation);
        // Replace the entry in the original list
        final index = group.indexOf(entry);
        group[index] = updatedEntry;
      }
    }
  }
  
  /// Builds context description for a group of entries
  String _buildGroupContext(List<LocalizationEntry> group) {
    final contexts = group.map((e) => e.contextType?.displayName ?? 'text').toSet();
    final widgets = group.map((e) => e.widgetType).where((w) => w != null).toSet();
    final screens = group.map((e) => e.extractedString.context?.screenContext)
        .where((s) => s != null).toSet();
    
    final parts = <String>[];
    
    if (contexts.isNotEmpty) {
      parts.add('UI Elements: ${contexts.join(', ')}');
    }
    
    if (widgets.isNotEmpty) {
      parts.add('Widgets: ${widgets.join(', ')}');
    }
    
    if (screens.isNotEmpty) {
      parts.add('Screens: ${screens.join(', ')}');
    }
    
    return parts.isEmpty ? 'Mobile app UI text' : parts.join('; ');
  }
  
  /// Parses the AI response to extract individual translations
  List<String> _parseTranslationResponse(String response, int expectedCount) {
    final lines = response.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    // Remove any numbering or bullet points
    final cleanedLines = lines.map((line) {
      // Remove patterns like "1. ", "- ", "• ", etc.
      return line.replaceAll(RegExp(r'^\d+\.\s*'), '')
                .replaceAll(RegExp(r'^[-•]\s*'), '')
                .trim();
    }).where((line) => line.isNotEmpty).toList();
    
    return cleanedLines;
  }
  
  /// Translates entries individually as fallback
  Future<void> _translateIndividually(List<LocalizationEntry> entries, String languageCode, String languageName) async {
    for (final entry in entries) {
      try {
        await _rateLimiter.waitIfNeeded();
        
        final context = _buildEntryContext(entry);
        final uiElement = entry.contextType?.displayName ?? 'text';
        
        final prompt = PromptTemplates.translationTemplate(
          text: entry.originalText,
          targetLanguage: languageName,
          context: context,
          uiElement: uiElement,
        );
        
        final response = await _aiClient.sendPrompt(prompt, options: {
          'temperature': 0.2,
          'max_tokens': 200,
        });
        
        final translation = response.trim();
        if (translation.isNotEmpty) {
          final updatedEntry = entry.addTranslation(languageCode, translation);
          final index = entries.indexOf(entry);
          entries[index] = updatedEntry;
        }
        
      } catch (e) {
        print('Warning: Failed to translate "${entry.originalText}" to $languageName: $e');
      }
    }
  }
  
  /// Builds context description for a single entry
  String _buildEntryContext(LocalizationEntry entry) {
    final parts = <String>[];
    
    if (entry.contextType != null) {
      parts.add('UI Element: ${entry.contextType!.displayName}');
    }
    
    if (entry.widgetType != null) {
      parts.add('Widget: ${entry.widgetType}');
    }
    
    if (entry.extractedString.context?.screenContext != null) {
      parts.add('Screen: ${entry.extractedString.context!.screenContext}');
    }
    
    if (entry.parameterName != null) {
      parts.add('Parameter: ${entry.parameterName}');
    }
    
    return parts.isEmpty ? 'Mobile app UI text' : parts.join(', ');
  }
  
  /// Gets the display name for a language code
  String _getLanguageName(String languageCode) {
    return _languageNames[languageCode] ?? languageCode.toUpperCase();
  }
  
  /// Validates translations for quality and completeness
  Future<Map<String, List<String>>> validateTranslations(List<LocalizationEntry> entries) async {
    final issues = <String, List<String>>{};
    
    for (final entry in entries) {
      final entryIssues = <String>[];
      
      // Check if all required languages have translations
      for (final languageCode in config.languages) {
        if (!entry.translations.containsKey(languageCode)) {
          entryIssues.add('Missing translation for $languageCode');
        } else {
          final translation = entry.translations[languageCode]!;
          
          // Basic quality checks
          if (translation.trim().isEmpty) {
            entryIssues.add('Empty translation for $languageCode');
          }
          
          if (translation == entry.originalText && languageCode != 'en') {
            entryIssues.add('Translation for $languageCode is identical to original');
          }
          
          // Check for obvious translation issues
          if (_hasTranslationIssues(entry.originalText, translation, languageCode)) {
            entryIssues.add('Potential quality issue in $languageCode translation');
          }
        }
      }
      
      if (entryIssues.isNotEmpty) {
        issues[entry.key] = entryIssues;
      }
    }
    
    return issues;
  }
  
  /// Checks for potential translation quality issues
  bool _hasTranslationIssues(String original, String translation, String languageCode) {
    // Check for untranslated English words in non-Latin script languages
    final nonLatinLanguages = {'ar', 'zh', 'ja', 'ko', 'hi', 'th', 'he', 'ru', 'bg', 'mk', 'sr'};
    
    if (nonLatinLanguages.contains(languageCode)) {
      // Check if translation contains mostly Latin characters (potential issue)
      final latinChars = translation.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      final totalChars = translation.replaceAll(RegExp(r'\s'), '').length;
      
      if (totalChars > 0 && latinChars / totalChars > 0.7) {
        return true; // Mostly Latin characters in non-Latin language
      }
    }
    
    // Check for extremely short or long translations compared to original
    final originalLength = original.length;
    final translationLength = translation.length;
    
    if (translationLength < originalLength * 0.3 || translationLength > originalLength * 3) {
      return true; // Suspicious length difference
    }
    
    return false;
  }
  
  /// Gets translation statistics
  Map<String, dynamic> getStatistics(List<LocalizationEntry> entries) {
    final stats = <String, dynamic>{
      'total_entries': entries.length,
      'languages': config.languages,
      'translation_coverage': <String, double>{},
    };
    
    for (final languageCode in config.languages) {
      final translatedCount = entries.where((e) => e.translations.containsKey(languageCode)).length;
      final coverage = entries.isNotEmpty ? translatedCount / entries.length : 0.0;
      stats['translation_coverage'][languageCode] = coverage;
    }
    
    return stats;
  }
}