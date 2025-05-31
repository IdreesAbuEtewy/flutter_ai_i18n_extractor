import '../core/extracted_string.dart';

/// Parser that analyzes and processes extracted string literals
class StringParser {

  /// Parses and validates extracted strings
  static List<ExtractedString> parseStrings(List<ExtractedString> rawStrings) {
    final validStrings = <ExtractedString>[];
    
    for (final extractedString in rawStrings) {
      final processed = _processString(extractedString);
      if (processed != null && processed.shouldExtract) {
        validStrings.add(processed);
      }
    }
    
    return validStrings;
  }
  
  /// Processes a single extracted string
  static ExtractedString? _processString(ExtractedString extractedString) {
    final value = extractedString.value;
    
    // Skip if already processed
    if (extractedString.isAlreadyLocalized) {
      return null;
    }
    
    // Clean and normalize the string
    final cleanedValue = _cleanString(value);
    if (cleanedValue.isEmpty) {
      return null;
    }
    
    // Apply additional filtering
    if (_shouldSkipString(cleanedValue, extractedString)) {
      return null;
    }
    
    return extractedString.copyWith(value: cleanedValue);
  }
  
  /// Cleans and normalizes a string value
  static String _cleanString(String value) {
    // Remove leading/trailing whitespace
    String cleaned = value.trim();
    
    // Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove escape sequences for display
    cleaned = cleaned.replaceAll('\\n', '\n');
    cleaned = cleaned.replaceAll('\\t', '\t');
    cleaned = cleaned.replaceAll('\\r', '\r');
    cleaned = cleaned.replaceAll('\\\'', '\'');
    cleaned = cleaned.replaceAll('\\"', '"');
    
    return cleaned;
  }
  
  /// Determines if a string should be skipped based on content analysis
  static bool _shouldSkipString(String value, ExtractedString extractedString) {
    // Skip very short strings (likely not user-facing)
    if (value.length < 2) return true;
    
    // Skip very long strings (likely not UI text)
    if (value.length > 200) return true;
    
    // Skip strings that are likely technical identifiers
    if (_isTechnicalIdentifier(value)) return true;
    
    // Skip strings that are likely configuration values
    if (_isConfigurationValue(value)) return true;
    
    // Skip strings in debug contexts
    if (_isDebugContext(extractedString)) return true;
    
    // Skip strings that are likely asset paths
    if (_isAssetPath(value)) return true;
    
    // Skip strings that are likely API endpoints
    if (_isApiEndpoint(value)) return true;
    
    return false;
  }
  
  /// Checks if a string is a technical identifier
  static bool _isTechnicalIdentifier(String value) {
    // Check for common technical patterns
    final technicalPatterns = [
      RegExp(r'^[a-z][a-zA-Z0-9_]*$'), // camelCase identifier
      RegExp(r'^[A-Z][A-Z0-9_]*$'), // CONSTANT_CASE
      RegExp(r'^[a-z]+[0-9]+$'), // alphanumeric codes
      RegExp(r'^[0-9a-f]{8,}$'), // hex strings
      RegExp(r'^[A-Za-z0-9+/=]{20,}$'), // base64-like
    ];
    
    return technicalPatterns.any((pattern) => pattern.hasMatch(value));
  }
  
  /// Checks if a string is a configuration value
  static bool _isConfigurationValue(String value) {
    final configKeywords = [
      'true', 'false', 'null', 'undefined',
      'production', 'development', 'staging', 'test',
      'debug', 'release', 'profile',
      'android', 'ios', 'web', 'windows', 'macos', 'linux',
    ];
    
    final lowerValue = value.toLowerCase();
    return configKeywords.contains(lowerValue);
  }
  
  /// Checks if the string is in a debug context
  static bool _isDebugContext(ExtractedString extractedString) {
    final surroundingCode = extractedString.surroundingCode?.toLowerCase() ?? '';
    final debugContexts = [
      'print(',
      'debugprint(',
      'log(',
      'logger.',
      'console.',
      'assert(',
      'throw ',
      'exception(',
      'error(',
    ];
    
    return debugContexts.any((context) => surroundingCode.contains(context));
  }
  
  /// Checks if a string is an asset path
  static bool _isAssetPath(String value) {
    final assetPatterns = [
      RegExp(r'^assets/'),
      RegExp(r'^images/'),
      RegExp(r'^fonts/'),
      RegExp(r'^icons/'),
      RegExp(r'\.(png|jpg|jpeg|gif|svg|webp|ico)$'),
      RegExp(r'\.(ttf|otf|woff|woff2)$'),
      RegExp(r'\.(json|xml|yaml|yml)$'),
    ];
    
    return assetPatterns.any((pattern) => pattern.hasMatch(value.toLowerCase()));
  }
  
  /// Checks if a string is an API endpoint
  static bool _isApiEndpoint(String value) {
    final apiPatterns = [
      RegExp(r'^/api/'),
      RegExp(r'^/v[0-9]+/'),
      RegExp(r'/[a-z]+/[a-z]+$'),
      RegExp(r'\{[a-zA-Z_]+\}'), // path parameters
    ];
    
    return apiPatterns.any((pattern) => pattern.hasMatch(value));
  }
  
  /// Extracts meaningful words from a string for key generation
  static List<String> extractKeywords(String value) {
    // Remove punctuation and split into words
    final words = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .toList();
    
    // Filter out common stop words
    final stopWords = {
      'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for',
      'from', 'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on',
      'that', 'the', 'to', 'was', 'will', 'with', 'you', 'your',
      'this', 'these', 'those', 'can', 'could', 'should',
      'would', 'may', 'might', 'must', 'shall', 'do', 'does', 'did',
    };
    
    final keywords = words.where((word) => 
        word.length > 1 && !stopWords.contains(word)).toList();
    
    return keywords;
  }
  
  /// Determines the likely UI context based on string content
  static StringContextType inferContextFromContent(String value) {
    final lowerValue = value.toLowerCase();
    
    // Button patterns
    if (_matchesPatterns(lowerValue, [
      'click', 'tap', 'press', 'submit', 'save', 'cancel', 'ok', 'yes', 'no',
      'continue', 'next', 'back', 'finish', 'done', 'close', 'open',
      'login', 'logout', 'sign in', 'sign up', 'register', 'delete',
      'edit', 'update', 'create', 'add', 'remove', 'send', 'share',
    ])) {
      return StringContextType.button;
    }
    
    // Error patterns
    if (_matchesPatterns(lowerValue, [
      'error', 'failed', 'invalid', 'wrong', 'incorrect', 'missing',
      'required', 'not found', 'unauthorized', 'forbidden', 'timeout',
    ])) {
      return StringContextType.error;
    }
    
    // Hint/placeholder patterns
    if (_matchesPatterns(lowerValue, [
      'enter', 'type', 'input', 'search', 'hint', 'placeholder',
      'example:', 'e.g.', 'optional', 'choose', 'select',
    ])) {
      return StringContextType.hint;
    }
    
    // Title patterns
    if (_matchesPatterns(lowerValue, [
      'title', 'heading', 'header', 'welcome', 'dashboard', 'settings',
      'profile', 'account', 'home', 'about', 'help', 'contact',
    ]) || _isTitle(value)) {
      return StringContextType.title;
    }
    
    // Label patterns
    if (_matchesPatterns(lowerValue, [
      'name', 'email', 'password', 'address', 'phone', 'age',
      'date', 'time', 'amount', 'quantity', 'price', 'total',
    ]) || _isLabel(value)) {
      return StringContextType.label;
    }
    
    // Confirmation patterns
    if (_matchesPatterns(lowerValue, [
      'are you sure', 'confirm', 'confirmation', 'verify',
      'do you want', 'would you like', 'please confirm',
    ])) {
      return StringContextType.confirmation;
    }
    
    // Default to message for longer text
    if (value.length > 20 || value.contains(' ')) {
      return StringContextType.message;
    }
    
    return StringContextType.unknown;
  }
  
  /// Checks if a string matches any of the given patterns
  static bool _matchesPatterns(String value, List<String> patterns) {
    return patterns.any((pattern) => value.contains(pattern));
  }
  
  /// Checks if a string looks like a title (capitalized words)
  static bool _isTitle(String value) {
    final words = value.split(' ');
    if (words.length < 2) return false;
    
    // Check if most words are capitalized
    final capitalizedWords = words.where((word) => 
        word.isNotEmpty && word[0] == word[0].toUpperCase()).length;
    
    return capitalizedWords >= words.length * 0.7;
  }
  
  /// Checks if a string looks like a label (short, descriptive)
  static bool _isLabel(String value) {
    return value.length < 30 && 
           !value.contains('.') && 
           !value.contains('!') && 
           !value.contains('?') &&
           value.split(' ').length <= 3;
  }
}