import 'package:meta/meta.dart';
import 'extracted_string.dart';

/// Represents a localization entry with key, original text, and translations
@immutable
class LocalizationEntry {
  /// The generated localization key
  final String key;
  
  /// The original English text
  final String originalText;
  
  /// The description for the ARB file
  final String description;
  
  /// Map of language codes to translated text
  final Map<String, String> translations;
  
  /// The extracted string this entry was generated from
  final ExtractedString extractedString;
  
  /// Additional metadata for the ARB file
  final Map<String, dynamic>? metadata;

  const LocalizationEntry({
    required this.key,
    required this.originalText,
    required this.description,
    required this.translations,
    required this.extractedString,
    this.metadata,
  });

  /// Creates a localization entry from an extracted string
  factory LocalizationEntry.fromExtractedString(
    ExtractedString extractedString,
    String key,
    String description,
  ) {
    return LocalizationEntry(
      key: key,
      originalText: extractedString.value,
      description: description,
      translations: {'en': extractedString.value},
      extractedString: extractedString,
    );
  }

  /// Creates a copy with updated fields
  LocalizationEntry copyWith({
    String? key,
    String? originalText,
    String? description,
    Map<String, String>? translations,
    ExtractedString? extractedString,
    Map<String, dynamic>? metadata,
  }) {
    return LocalizationEntry(
      key: key ?? this.key,
      originalText: originalText ?? this.originalText,
      description: description ?? this.description,
      translations: translations ?? Map.from(this.translations),
      extractedString: extractedString ?? this.extractedString,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Adds a translation for a specific language
  LocalizationEntry addTranslation(String languageCode, String translation) {
    final newTranslations = Map<String, String>.from(translations);
    newTranslations[languageCode] = translation;
    return copyWith(translations: newTranslations);
  }

  /// Gets the translation for a specific language, fallback to English
  String getTranslation(String languageCode) {
    return translations[languageCode] ?? translations['en'] ?? originalText;
  }

  /// Returns true if all required languages have translations
  bool hasAllTranslations(List<String> requiredLanguages) {
    return requiredLanguages.every((lang) => translations.containsKey(lang));
  }

  /// Generates the ARB entry for this localization
  Map<String, dynamic> toArbEntry() {
    final entry = <String, dynamic>{
      key: originalText,
    };
    
    // Add metadata entry
    final metadataKey = '@$key';
    final metadataEntry = <String, dynamic>{
      'description': description,
    };
    
    // Add any additional metadata
    if (metadata != null) {
      metadataEntry.addAll(metadata!);
    }
    
    // Add context information if available
    if (extractedString.context != null) {
      metadataEntry['context'] = extractedString.context!.type.displayName;
    }
    
    // Add widget type if available
    if (extractedString.widgetType != null) {
      metadataEntry['widget'] = extractedString.widgetType;
    }
    
    entry[metadataKey] = metadataEntry;
    
    return entry;
  }

  /// Generates the ARB entry for a specific language
  Map<String, dynamic> toArbEntryForLanguage(String languageCode) {
    return {
      key: getTranslation(languageCode),
    };
  }

  /// Validates the localization entry
  bool isValid() {
    if (key.isEmpty) return false;
    if (originalText.isEmpty) return false;
    if (!translations.containsKey('en')) return false;
    
    // Validate key format (camelCase or snake_case)
    final camelCasePattern = RegExp(r'^[a-z][a-zA-Z0-9]*$');
    final snakeCasePattern = RegExp(r'^[a-z][a-z0-9_]*$');
    
    return camelCasePattern.hasMatch(key) || snakeCasePattern.hasMatch(key);
  }

  /// Returns the file path where this string was found
  String get filePath => extractedString.filePath;
  
  /// Returns the line number where this string was found
  int get lineNumber => extractedString.lineNumber;
  
  /// Returns the widget type context
  String? get widgetType => extractedString.widgetType;
  
  /// Returns the parameter name context
  String? get parameterName => extractedString.parameterName;
  
  /// Returns the string context type
  StringContextType? get contextType => extractedString.context?.type;

  @override
  String toString() {
    return 'LocalizationEntry(key: $key, text: "$originalText", languages: ${translations.keys.join(', ')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalizationEntry &&
           other.key == key &&
           other.originalText == originalText;
  }

  @override
  int get hashCode {
    return Object.hash(key, originalText);
  }
}

/// Utility class for managing collections of localization entries
class LocalizationEntryCollection {
  final List<LocalizationEntry> _entries;
  
  LocalizationEntryCollection(this._entries);
  
  /// Creates an empty collection
  LocalizationEntryCollection.empty() : _entries = [];
  
  /// Gets all entries
  List<LocalizationEntry> get entries => List.unmodifiable(_entries);
  
  /// Gets the number of entries
  int get length => _entries.length;
  
  /// Checks if the collection is empty
  bool get isEmpty => _entries.isEmpty;
  
  /// Checks if the collection is not empty
  bool get isNotEmpty => _entries.isNotEmpty;
  
  /// Adds an entry to the collection
  void add(LocalizationEntry entry) {
    _entries.add(entry);
  }
  
  /// Adds multiple entries to the collection
  void addAll(Iterable<LocalizationEntry> entries) {
    _entries.addAll(entries);
  }
  
  /// Finds an entry by key
  LocalizationEntry? findByKey(String key) {
    try {
      return _entries.firstWhere((entry) => entry.key == key);
    } catch (e) {
      return null;
    }
  }
  
  /// Gets all unique keys
  Set<String> get keys => _entries.map((e) => e.key).toSet();
  
  /// Gets all supported languages
  Set<String> get supportedLanguages {
    final languages = <String>{};
    for (final entry in _entries) {
      languages.addAll(entry.translations.keys);
    }
    return languages;
  }
  
  /// Filters entries by context type
  List<LocalizationEntry> filterByContextType(StringContextType type) {
    return _entries.where((entry) => entry.contextType == type).toList();
  }
  
  /// Filters entries by widget type
  List<LocalizationEntry> filterByWidgetType(String widgetType) {
    return _entries.where((entry) => entry.widgetType == widgetType).toList();
  }
  
  /// Groups entries by file path
  Map<String, List<LocalizationEntry>> groupByFile() {
    final grouped = <String, List<LocalizationEntry>>{};
    for (final entry in _entries) {
      final filePath = entry.filePath;
      grouped.putIfAbsent(filePath, () => []).add(entry);
    }
    return grouped;
  }
  
  /// Validates all entries
  List<String> validate() {
    final errors = <String>[];
    final seenKeys = <String>{};
    
    for (final entry in _entries) {
      if (!entry.isValid()) {
        errors.add('Invalid entry: ${entry.key}');
      }
      
      if (seenKeys.contains(entry.key)) {
        errors.add('Duplicate key: ${entry.key}');
      } else {
        seenKeys.add(entry.key);
      }
    }
    
    return errors;
  }
}