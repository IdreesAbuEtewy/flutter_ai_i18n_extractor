/// Utility functions for string processing and validation
class StringUtils {
  /// Checks if a string is likely a debug string
  static bool isDebugString(String text) {
    final debugPatterns = [
      RegExp(r'^DEBUG:', caseSensitive: false),
      RegExp(r'^LOG:', caseSensitive: false),
      RegExp(r'^TRACE:', caseSensitive: false),
      RegExp(r'^ERROR:', caseSensitive: false),
      RegExp(r'^WARNING:', caseSensitive: false),
      RegExp(r'^INFO:', caseSensitive: false),
      RegExp(r'\[DEBUG\]', caseSensitive: false),
      RegExp(r'\[LOG\]', caseSensitive: false),
      RegExp(r'print\(', caseSensitive: false),
      RegExp(r'console\.log', caseSensitive: false),
    ];
    
    return debugPatterns.any((pattern) => pattern.hasMatch(text));
  }
  
  /// Checks if a string is likely a technical identifier
  static bool isTechnicalIdentifier(String text) {
    // Check for common technical patterns
    final technicalPatterns = [
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$'), // Variable names
      RegExp(r'^[A-Z_][A-Z0-9_]*$'), // Constants
      RegExp(r'^[a-z]+([A-Z][a-z]*)*$'), // CamelCase
      RegExp(r'^[a-z]+(-[a-z]+)*$'), // Kebab-case
      RegExp(r'^[a-z]+(_[a-z]+)*$'), // Snake_case
      RegExp(r'^\d+(\.\d+)*$'), // Version numbers
      RegExp(r'^[a-f0-9]{8,}$', caseSensitive: false), // Hex strings
      RegExp(r'^[A-Za-z0-9+/]+=*$'), // Base64
    ];
    
    // Check length - very short or very long strings are likely technical
    if (text.length <= 2 || text.length > 100) {
      return true;
    }
    
    // Check for technical keywords
    final technicalKeywords = [
      'null', 'undefined', 'true', 'false', 'void', 'var', 'let', 'const',
      'function', 'class', 'interface', 'enum', 'type', 'import', 'export',
      'async', 'await', 'return', 'throw', 'try', 'catch', 'finally',
      'if', 'else', 'switch', 'case', 'default', 'for', 'while', 'do',
      'break', 'continue', 'new', 'this', 'super', 'extends', 'implements',
    ];
    
    if (technicalKeywords.contains(text.toLowerCase())) {
      return true;
    }
    
    return technicalPatterns.any((pattern) => pattern.hasMatch(text));
  }
  
  /// Checks if a string is likely a file path or URL
  static bool isPathOrUrl(String text) {
    final pathPatterns = [
      RegExp(r'^https?://'), // HTTP URLs
      RegExp(r'^ftp://'), // FTP URLs
      RegExp(r'^file://'), // File URLs
      RegExp(r'^/[^\s]*'), // Absolute paths
      RegExp(r'^\./[^\s]*'), // Relative paths
      RegExp(r'^\.\.?/[^\s]*'), // Parent directory paths
      RegExp(r'^[a-zA-Z]:[\\]'), // Windows paths
      RegExp(r'\.[a-zA-Z]{2,4}$'), // File extensions
      RegExp(r'/[^/\s]+\.[a-zA-Z]{2,4}$'), // Files with extensions
    ];
    
    return pathPatterns.any((pattern) => pattern.hasMatch(text));
  }
  
  /// Checks if a string is likely an asset path
  static bool isAssetPath(String text) {
    final assetPatterns = [
      RegExp(r'^assets/'), // Flutter assets
      RegExp(r'^images/'), // Image directory
      RegExp(r'^icons/'), // Icon directory
      RegExp(r'^fonts/'), // Font directory
      RegExp(r'^sounds/'), // Sound directory
      RegExp(r'^videos/'), // Video directory
      RegExp(r'\.(png|jpg|jpeg|gif|svg|webp|ico)$', caseSensitive: false), // Image files
      RegExp(r'\.(mp3|wav|ogg|m4a|aac)$', caseSensitive: false), // Audio files
      RegExp(r'\.(mp4|avi|mov|wmv|flv)$', caseSensitive: false), // Video files
      RegExp(r'\.(ttf|otf|woff|woff2)$', caseSensitive: false), // Font files
    ];
    
    return assetPatterns.any((pattern) => pattern.hasMatch(text));
  }
  
  /// Checks if a string is likely an API endpoint or configuration
  static bool isApiOrConfig(String text) {
    final apiPatterns = [
      RegExp(r'^/api/'), // API endpoints
      RegExp(r'^/v\d+/'), // Versioned endpoints
      RegExp(r'\{[^}]+\}'), // Template variables
      RegExp(r'^[A-Z_]+$'), // Environment variables
      RegExp(r'[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+'), // Dotted notation
      RegExp(r'^\$\{[^}]+\}$'), // Environment variable syntax
    ];
    
    return apiPatterns.any((pattern) => pattern.hasMatch(text));
  }
  
  /// Checks if a string contains only whitespace or special characters
  static bool isWhitespaceOrSpecial(String text) {
    return RegExp(r'^[\s\p{P}\p{S}]*$', unicode: true).hasMatch(text);
  }
  
  /// Checks if a string is likely a color value
  static bool isColorValue(String text) {
    final colorPatterns = [
      RegExp(r'^#[0-9a-fA-F]{3,8}$'), // Hex colors
      RegExp(r'^rgb\('), // RGB colors
      RegExp(r'^rgba\('), // RGBA colors
      RegExp(r'^hsl\('), // HSL colors
      RegExp(r'^hsla\('), // HSLA colors
      RegExp(r'^0x[0-9a-fA-F]{8}$'), // Flutter color format
    ];
    
    // Common color names
    final colorNames = [
      'red', 'green', 'blue', 'yellow', 'orange', 'purple', 'pink',
      'brown', 'black', 'white', 'gray', 'grey', 'cyan', 'magenta',
      'lime', 'indigo', 'violet', 'turquoise', 'gold', 'silver',
    ];
    
    return colorPatterns.any((pattern) => pattern.hasMatch(text)) ||
           colorNames.contains(text.toLowerCase());
  }
  
  /// Checks if a string is likely a measurement or unit
  static bool isMeasurementOrUnit(String text) {
    final measurementPatterns = [
      RegExp(r'^\d+(\.\d+)?(px|dp|sp|pt|em|rem|%|vh|vw|cm|mm|in)$'),
      RegExp(r'^\d+(\.\d+)?$'), // Pure numbers
    ];
    
    return measurementPatterns.any((pattern) => pattern.hasMatch(text));
  }
  
  /// Normalizes a string by removing extra whitespace and trimming
  static String normalize(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Cleans a string by removing common prefixes and suffixes
  static String clean(String text) {
    String cleaned = normalize(text);
    
    // Remove common prefixes
    final prefixes = ['TODO:', 'FIXME:', 'NOTE:', 'HACK:'];
    for (final prefix in prefixes) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length).trim();
      }
    }
    
    return cleaned;
  }
  
  /// Checks if a string is extractable for localization
  static bool isExtractable(String text) {
    // Must have minimum length
    if (text.length < 2) return false;
    
    // Must not be purely technical
    if (isTechnicalIdentifier(text)) return false;
    
    // Must not be a path or URL
    if (isPathOrUrl(text)) return false;
    
    // Must not be an asset path
    if (isAssetPath(text)) return false;
    
    // Must not be API or config
    if (isApiOrConfig(text)) return false;
    
    // Must not be debug string
    if (isDebugString(text)) return false;
    
    // Must not be only whitespace or special characters
    if (isWhitespaceOrSpecial(text)) return false;
    
    // Must not be a color value
    if (isColorValue(text)) return false;
    
    // Must not be a measurement
    if (isMeasurementOrUnit(text)) return false;
    
    // Must contain at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(text)) return false;
    
    return true;
  }
  
  /// Converts a string to camelCase
  static String toCamelCase(String text) {
    if (text.isEmpty) return text;
    
    // Split into words
    final words = text
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    
    if (words.isEmpty) return 'text';
    
    // Convert to camelCase
    final result = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      final word = words[i].toLowerCase();
      if (i == 0) {
        result.write(word);
      } else {
        result.write(word[0].toUpperCase() + word.substring(1));
      }
    }
    
    return result.toString();
  }
  
  /// Converts a string to snake_case
  static String toSnakeCase(String text) {
    return text
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .join('_');
  }
  
  /// Converts a string to kebab-case
  static String toKebabCase(String text) {
    return text
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .join('-');
  }
  
  /// Truncates a string to a maximum length
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    
    final truncateLength = maxLength - suffix.length;
    if (truncateLength <= 0) return suffix;
    
    return text.substring(0, truncateLength) + suffix;
  }
  
  /// Escapes special characters for use in regular expressions
  static String escapeRegExp(String text) {
    return text.replaceAllMapped(
      RegExp(r'[\\\^\$\.\|\?\*\+\(\)\[\]\{\}]'),
      (match) => '\\${match.group(0)}',
    );
  }
  
  /// Counts the number of words in a string
  static int wordCount(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }
  
  /// Checks if a string contains any of the given patterns
  static bool containsAny(String text, List<String> patterns) {
    return patterns.any((pattern) => text.contains(pattern));
  }
  
  /// Checks if a string matches any of the given regular expressions
  static bool matchesAny(String text, List<RegExp> patterns) {
    return patterns.any((pattern) => pattern.hasMatch(text));
  }
  
  /// Removes all non-alphanumeric characters except spaces
  static String removeSpecialChars(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }
  
  /// Capitalizes the first letter of each word
  static String toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}