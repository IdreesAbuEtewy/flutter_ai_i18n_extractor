import '../core/extractor_config.dart';
import '../core/extracted_string.dart';
import '../core/localization_entry.dart';
import '../utils/string_utils.dart';
import 'ai_client.dart';

/// Generates intelligent abbreviations and keys for localization using AI
class AbbreviationGenerator {
  final ExtractorConfig config;
  final AiClient _aiClient;
  final RateLimiter _rateLimiter;
  final Set<String> _usedKeys = {};
  
  AbbreviationGenerator(this.config)
      : _aiClient = AiClient.create(config),
        _rateLimiter = RateLimiter(maxRequestsPerMinute: 50);

  /// Generates localization keys for a list of extracted strings
  Future<List<LocalizationEntry>> generateKeys(List<ExtractedString> extractedStrings) async {
    final entries = <LocalizationEntry>[];
    
    // Process strings in batches to optimize AI calls
    final batches = _createBatches(extractedStrings, batchSize: 10);
    
    for (final batch in batches) {
      final batchEntries = await _processBatch(batch);
      entries.addAll(batchEntries);
      
      // Small delay between batches
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return entries;
  }
  
  /// Creates batches of strings for processing
  List<List<ExtractedString>> _createBatches(List<ExtractedString> strings, {int batchSize = 10}) {
    final batches = <List<ExtractedString>>[];
    for (int i = 0; i < strings.length; i += batchSize) {
      final end = (i + batchSize < strings.length) ? i + batchSize : strings.length;
      batches.add(strings.sublist(i, end));
    }
    return batches;
  }
  
  /// Processes a batch of extracted strings
  Future<List<LocalizationEntry>> _processBatch(List<ExtractedString> batch) async {
    final entries = <LocalizationEntry>[];
    
    for (final extractedString in batch) {
      try {
        await _rateLimiter.waitIfNeeded();
        
        final key = await _generateKey(extractedString);
        final description = _generateDescription(extractedString);
        
        final entry = LocalizationEntry.fromExtractedString(
          extractedString,
          key,
          description,
        );
        
        entries.add(entry);
        _usedKeys.add(key);
        
      } catch (e) {
        print('Warning: Failed to generate key for "${extractedString.value}": $e');
        
        // Fallback to rule-based key generation
        final fallbackKey = _generateFallbackKey(extractedString);
        final description = _generateDescription(extractedString);
        
        final entry = LocalizationEntry.fromExtractedString(
          extractedString,
          fallbackKey,
          description,
        );
        
        entries.add(entry);
        _usedKeys.add(fallbackKey);
      }
    }
    
    return entries;
  }
  
  /// Generates a key using AI
  Future<String> _generateKey(ExtractedString extractedString) async {
    final context = _buildContextDescription(extractedString);
    
    final prompt = PromptTemplates.keyGenerationTemplate(
      text: extractedString.value,
      context: context,
      widgetType: extractedString.widgetType ?? 'unknown',
      namingConvention: config.keyNamingConvention,
      maxLength: config.maxKeyLength,
    );
    
    final response = await _aiClient.sendPrompt(prompt, options: {
      'temperature': 0.1, // Low temperature for consistent naming
      'max_tokens': 50,
    });
    
    final key = _cleanAndValidateKey(response.trim());
    return _ensureUniqueKey(key);
  }
  
  /// Builds a context description for the AI prompt
  String _buildContextDescription(ExtractedString extractedString) {
    final parts = <String>[];
    
    if (extractedString.context != null) {
      parts.add('UI Context: ${extractedString.context!.type.displayName}');
      
      if (extractedString.context!.screenContext != null) {
        parts.add('Screen: ${extractedString.context!.screenContext}');
      }
    }
    
    if (extractedString.widgetType != null) {
      parts.add('Widget: ${extractedString.widgetType}');
    }
    
    if (extractedString.parameterName != null) {
      parts.add('Parameter: ${extractedString.parameterName}');
    }
    
    final fileName = extractedString.filePath.split('/').last.replaceAll('.dart', '');
    parts.add('File: $fileName');
    
    return parts.join(', ');
  }
  
  /// Cleans and validates an AI-generated key
  String _cleanAndValidateKey(String key) {
    // Remove any quotes or extra characters
    String cleaned = key.replaceAll(RegExp(r'["\''\']'), '').trim();
    
    // Remove any explanatory text (AI sometimes adds explanations)
    if (cleaned.contains(' ')) {
      cleaned = cleaned.split(' ').first;
    }
    
    // Ensure it follows the naming convention
    if (config.keyNamingConvention == 'camelCase') {
      cleaned = StringUtils.toCamelCase(cleaned);
    } else if (config.keyNamingConvention == 'snake_case') {
      cleaned = StringUtils.toSnakeCase(cleaned);
    }
    
    // Ensure it's not too long
    if (cleaned.length > config.maxKeyLength) {
      cleaned = cleaned.substring(0, config.maxKeyLength);
    }
    
    // Ensure it's valid (starts with letter, contains only alphanumeric and underscore)
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(cleaned)) {
      throw ArgumentError('Generated key is not valid: $cleaned');
    }
    
    return cleaned;
  }
  
  /// Ensures the key is unique by adding a suffix if necessary
  String _ensureUniqueKey(String baseKey) {
    if (!_usedKeys.contains(baseKey)) {
      return baseKey;
    }
    
    int counter = 1;
    String uniqueKey;
    
    do {
      uniqueKey = '${baseKey}_$counter';
      counter++;
    } while (_usedKeys.contains(uniqueKey));
    
    return uniqueKey;
  }
  
  /// Generates a fallback key using rule-based approach
  String _generateFallbackKey(ExtractedString extractedString) {
    final value = extractedString.value;
    final context = extractedString.context?.type;
    final widgetType = extractedString.widgetType;
    
    // Start with context-based prefix
    String prefix = '';
    if (context != null) {
      switch (context) {
        case StringContextType.button:
          prefix = 'btn';
          break;
        case StringContextType.title:
          prefix = 'title';
          break;
        case StringContextType.message:
          prefix = 'msg';
          break;
        case StringContextType.error:
          prefix = 'error';
          break;
        case StringContextType.hint:
          prefix = 'hint';
          break;
        case StringContextType.label:
          prefix = 'label';
          break;
        default:
          prefix = 'text';
      }
    } else if (widgetType != null) {
      prefix = widgetType.toLowerCase();
    } else {
      prefix = 'text';
    }
    
    // Extract meaningful words from the text
    final words = _extractMeaningfulWords(value);
    
    // Combine prefix with words
    final keyParts = [prefix, ...words];
    
    String key;
    if (config.keyNamingConvention == 'camelCase') {
      key = StringUtils.toCamelCase(keyParts.join(' '));
    } else {
      key = StringUtils.toSnakeCase(keyParts.join(' '));
    }
    
    // Ensure it's not too long
    if (key.length > config.maxKeyLength) {
      key = key.substring(0, config.maxKeyLength);
    }
    
    return _ensureUniqueKey(key);
  }
  
  /// Extracts meaningful words from text for key generation
  List<String> _extractMeaningfulWords(String text) {
    // Remove punctuation and split into words
    final words = text
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .toList();
    
    // Filter out stop words and keep meaningful ones
    final stopWords = {
      'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for',
      'from', 'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on',
      'that', 'the', 'to', 'was', 'will', 'with', 'you', 'your',
      'this', 'these', 'those', 'can', 'could', 'should',
      'would', 'may', 'might', 'must', 'shall', 'do', 'does', 'did',
    };
    
    final meaningfulWords = words
        .where((word) => word.length > 1 && !stopWords.contains(word))
        .take(3) // Limit to 3 words to keep keys concise
        .toList();
    
    return meaningfulWords.isNotEmpty ? meaningfulWords : ['text'];
  }
  
  /// Generates a description for the ARB file
  String _generateDescription(ExtractedString extractedString) {
    final parts = <String>[];
    
    // Add context information
    if (extractedString.context != null) {
      final contextType = extractedString.context!.type.displayName;
      parts.add(contextType);
      
      if (extractedString.context!.screenContext != null) {
        parts.add('for ${extractedString.context!.screenContext}');
      }
    }
    
    // Add widget information
    if (extractedString.widgetType != null) {
      if (parts.isEmpty) {
        parts.add('Text for ${extractedString.widgetType}');
      } else {
        parts.add('in ${extractedString.widgetType}');
      }
    }
    
    // Add parameter information
    if (extractedString.parameterName != null) {
      parts.add('(${extractedString.parameterName} parameter)');
    }
    
    // Default description if no context available
    if (parts.isEmpty) {
      parts.add('Text content');
    }
    
    return parts.join(' ');
  }
  
  /// Validates that all generated keys are unique and valid
  bool validateGeneratedKeys(List<LocalizationEntry> entries) {
    final keys = entries.map((e) => e.key).toList();
    final uniqueKeys = keys.toSet();
    
    if (keys.length != uniqueKeys.length) {
      print('Error: Duplicate keys found');
      return false;
    }
    
    for (final key in keys) {
      if (!_isValidKey(key)) {
        print('Error: Invalid key format: $key');
        return false;
      }
    }
    
    return true;
  }
  
  /// Checks if a key is valid according to the naming convention
  bool _isValidKey(String key) {
    if (key.isEmpty || key.length > config.maxKeyLength) {
      return false;
    }
    
    if (config.keyNamingConvention == 'camelCase') {
      return RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(key);
    } else if (config.keyNamingConvention == 'snake_case') {
      return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(key);
    }
    
    return false;
  }
  
  /// Gets statistics about key generation
  Map<String, dynamic> getStatistics() {
    return {
      'total_keys_generated': _usedKeys.length,
      'naming_convention': config.keyNamingConvention,
      'max_key_length': config.maxKeyLength,
      'ai_provider': config.aiProvider,
    };
  }
}