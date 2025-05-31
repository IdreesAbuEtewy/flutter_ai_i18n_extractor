import 'package:meta/meta.dart';

/// Represents a string extracted from source code with its context
@immutable
class ExtractedString {
  /// The actual string value
  final String value;
  
  /// The file path where the string was found
  final String filePath;
  
  /// The line number where the string appears
  final int lineNumber;
  
  /// The column number where the string starts
  final int columnNumber;
  
  /// The offset in the file where the string starts
  final int offset;
  
  /// The length of the string in the source code (including quotes)
  final int length;
  
  /// The widget type context (e.g., 'Text', 'AppBar', 'Button')
  final String? widgetType;
  
  /// The parameter name where the string is used (e.g., 'title', 'content', 'hintText')
  final String? parameterName;
  
  /// The surrounding code context for better analysis
  final String? surroundingCode;
  
  /// Whether this string is already localized
  final bool isAlreadyLocalized;
  
  /// The UI context classification
  StringContext? context;
  
  /// Generated localization key
  String? generatedKey;

   ExtractedString({
    required this.value,
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.offset,
    required this.length,
    this.widgetType,
    this.parameterName,
    this.surroundingCode,
    this.isAlreadyLocalized = false,
    this.context,
    this.generatedKey,
  });

  /// Creates a copy with updated fields
  ExtractedString copyWith({
    String? value,
    String? filePath,
    int? lineNumber,
    int? columnNumber,
    int? offset,
    int? length,
    String? widgetType,
    String? parameterName,
    String? surroundingCode,
    bool? isAlreadyLocalized,
    StringContext? context,
    String? generatedKey,
  }) {
    return ExtractedString(
      value: value ?? this.value,
      filePath: filePath ?? this.filePath,
      lineNumber: lineNumber ?? this.lineNumber,
      columnNumber: columnNumber ?? this.columnNumber,
      offset: offset ?? this.offset,
      length: length ?? this.length,
      widgetType: widgetType ?? this.widgetType,
      parameterName: parameterName ?? this.parameterName,
      surroundingCode: surroundingCode ?? this.surroundingCode,
      isAlreadyLocalized: isAlreadyLocalized ?? this.isAlreadyLocalized,
      context: context ?? this.context,
      generatedKey: generatedKey ?? this.generatedKey,
    );
  }

  /// Returns true if this string should be extracted for localization
  bool get shouldExtract {
    if (isAlreadyLocalized) return false;
    if (value.trim().isEmpty) return false;
    if (_isDebugString()) return false;
    if (_isConstantOrEnum()) return false;
    if (_isUrl()) return false;
    if (_isFilePath()) return false;
    return true;
  }

  /// Checks if this is a debug/print statement
  bool _isDebugString() {
    final lowerValue = value.toLowerCase();
    final debugKeywords = ['debug', 'print', 'log', 'error', 'warning', 'info'];
    return debugKeywords.any((keyword) => lowerValue.contains(keyword)) ||
           surroundingCode?.contains('print(') == true ||
           surroundingCode?.contains('debugPrint(') == true;
  }

  /// Checks if this is a constant or enum value
  bool _isConstantOrEnum() {
    // Check if it's all uppercase (likely a constant)
    if (value == value.toUpperCase() && value.length > 1) return true;
    
    // Check if it's a simple identifier (no spaces, likely an enum)
    if (!value.contains(' ') && value.length < 20) {
      final words = value.split(RegExp(r'[^a-zA-Z0-9]'));
      if (words.length == 1) return true;
    }
    
    return false;
  }

  /// Checks if this is a URL
  bool _isUrl() {
    return value.startsWith('http://') || 
           value.startsWith('https://') ||
           value.startsWith('ftp://') ||
           value.contains('://') ||
           value.contains('.com') ||
           value.contains('.org') ||
           value.contains('.net');
  }

  /// Checks if this is a file path
  bool _isFilePath() {
    return value.contains('/') && 
           (value.contains('.dart') || 
            value.contains('.png') || 
            value.contains('.jpg') || 
            value.contains('.svg') ||
            value.startsWith('assets/') ||
            value.startsWith('lib/'));
  }

  @override
  String toString() {
    return 'ExtractedString(value: "$value", file: $filePath:$lineNumber:$columnNumber, widget: $widgetType, param: $parameterName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtractedString &&
           other.value == value &&
           other.filePath == filePath &&
           other.offset == offset;
  }

  @override
  int get hashCode {
    return Object.hash(value, filePath, offset);
  }
}

/// Represents the UI context of a string
class StringContext {
  /// The type of UI element (title, message, button, label, error, hint)
  final StringContextType type;
  
  /// The screen or page context
  final String? screenContext;
  
  /// Additional context information
  final String? additionalInfo;
  
  /// Confidence score of the context analysis (0.0 to 1.0)
  final double confidence;

  const StringContext({
    required this.type,
    this.screenContext,
    this.additionalInfo,
    this.confidence = 1.0,
  });

  @override
  String toString() {
    return 'StringContext(type: $type, screen: $screenContext, confidence: $confidence)';
  }
}

/// Enumeration of string context types
enum StringContextType {
  title,
  message,
  button,
  label,
  error,
  hint,
  placeholder,
  description,
  confirmation,
  navigation,
  unknown,
}

/// Extension to get display names for context types
extension StringContextTypeExtension on StringContextType {
  String get displayName {
    switch (this) {
      case StringContextType.title:
        return 'Title';
      case StringContextType.message:
        return 'Message';
      case StringContextType.button:
        return 'Button';
      case StringContextType.label:
        return 'Label';
      case StringContextType.error:
        return 'Error';
      case StringContextType.hint:
        return 'Hint';
      case StringContextType.placeholder:
        return 'Placeholder';
      case StringContextType.description:
        return 'Description';
      case StringContextType.confirmation:
        return 'Confirmation';
      case StringContextType.navigation:
        return 'Navigation';
      case StringContextType.unknown:
        return 'Unknown';
    }
  }
}