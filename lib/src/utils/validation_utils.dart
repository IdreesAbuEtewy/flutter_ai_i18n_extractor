import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/extracted_string.dart';
import '../core/localization_entry.dart';
import '../core/extractor_config.dart';

/// Utility class for validation operations
class ValidationUtils {
  /// Validates that a file path exists and is readable
  static bool isValidFilePath(String filePath) {
    try {
      final file = File(filePath);
      return file.existsSync() && file.statSync().type == FileSystemEntityType.file;
    } catch (e) {
      return false;
    }
  }
  
  /// Validates that a directory path exists and is accessible
  static bool isValidDirectoryPath(String dirPath) {
    try {
      final dir = Directory(dirPath);
      return dir.existsSync() && dir.statSync().type == FileSystemEntityType.directory;
    } catch (e) {
      return false;
    }
  }
  
  /// Validates a localization key format
  static bool isValidLocalizationKey(String key, {String convention = 'camelCase'}) {
    if (key.isEmpty) return false;
    
    switch (convention) {
      case 'camelCase':
        return RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(key);
      case 'snake_case':
        return RegExp(r'^[a-z][a-z0-9_]*[a-z0-9]$').hasMatch(key);
      default:
        return false;
    }
  }
  
  /// Validates an extracted string for localization eligibility
  static ValidationResult validateExtractedString(ExtractedString extractedString) {
    final issues = <String>[];
    
    // Check if string is empty or whitespace only
    if (extractedString.value.trim().isEmpty) {
      issues.add('String is empty or contains only whitespace');
    }
    
    // Check if string is too short to be meaningful
    if (extractedString.value.trim().length < 2) {
      issues.add('String is too short to be meaningful for localization');
    }
    
    // Check if string contains only special characters
    if (RegExp(r'^[^a-zA-Z0-9\s]+$').hasMatch(extractedString.value)) {
      issues.add('String contains only special characters');
    }
    
    // Check if string looks like a technical identifier
    if (_isTechnicalIdentifier(extractedString.value)) {
      issues.add('String appears to be a technical identifier');
    }
    
    // Check if string is already localized
    if (extractedString.isAlreadyLocalized) {
      issues.add('String is already localized');
    }
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
  
  /// Validates a localization entry
  static ValidationResult validateLocalizationEntry(LocalizationEntry entry) {
    final issues = <String>[];
    
    // Validate key
    if (!isValidLocalizationKey(entry.key)) {
      issues.add('Invalid localization key format: ${entry.key}');
    }
    
    // Validate original text
    if (entry.originalText.trim().isEmpty) {
      issues.add('Original text is empty');
    }
    
    // Validate translations
    for (final translation in entry.translations.entries) {
      if (translation.value.trim().isEmpty) {
        issues.add('Translation for ${translation.key} is empty');
      }
      
      // Check for placeholder consistency
      final originalPlaceholders = _extractPlaceholders(entry.originalText);
      final translationPlaceholders = _extractPlaceholders(translation.value);
      
      if (!_placeholdersMatch(originalPlaceholders, translationPlaceholders)) {
        issues.add('Placeholder mismatch in ${translation.key} translation');
      }
    }
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
  
  /// Validates the extractor configuration
  static ValidationResult validateConfig(ExtractorConfig config) {
    final issues = <String>[];
    
    try {
      config.validate();
    } catch (e) {
      issues.add(e.toString());
    }
    
    // Additional validations
    if (!isValidDirectoryPath(config.arbDir)) {
      issues.add('ARB directory does not exist: ${config.arbDir}');
    }
    
    for (final scanPath in config.scanPaths) {
      if (!isValidDirectoryPath(scanPath)) {
        issues.add('Scan path does not exist: $scanPath');
      }
    }
    
    // Validate language codes
    for (final language in config.languages) {
      if (!_isValidLanguageCode(language)) {
        issues.add('Invalid language code: $language');
      }
    }
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
  
  /// Validates ARB file content
  static ValidationResult validateArbContent(Map<String, dynamic> arbContent) {
    final issues = <String>[];
    
    // Check for required metadata
    if (!arbContent.containsKey('@@locale')) {
      issues.add('ARB file missing @@locale metadata');
    }
    
    // Validate each entry
    for (final entry in arbContent.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Skip metadata entries
      if (key.startsWith('@@') || key.startsWith('@')) {
        continue;
      }
      
      // Validate key format
      if (!isValidLocalizationKey(key)) {
        issues.add('Invalid key format: $key');
      }
      
      // Validate value
      if (value is! String) {
        issues.add('Non-string value for key: $key');
      } else if (value.trim().isEmpty) {
        issues.add('Empty value for key: $key');
      }
    }
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
  
  /// Checks if a string looks like a technical identifier
  static bool _isTechnicalIdentifier(String value) {
    // Check for common technical patterns
    final patterns = [
      RegExp(r'^[A-Z_][A-Z0-9_]*$'), // CONSTANT_CASE
      RegExp(r'^[a-z][a-zA-Z0-9]*$'), // camelCase (but very short)
      RegExp(r'^[a-z_][a-z0-9_]*$'), // snake_case
      RegExp(r'^[a-z-][a-z0-9-]*$'), // kebab-case
      RegExp(r'^\w+\.(\w+\.)*\w+$'), // dot.notation
      RegExp(r'^/[\w/]*$'), // path-like
      RegExp(r'^https?://'), // URLs
      RegExp(r'^\w+://'), // Other protocols
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(value.trim()));
  }
  
  /// Extracts placeholders from a string
  static List<String> _extractPlaceholders(String text) {
    final placeholderPattern = RegExp(r'\{([^}]+)\}');
    return placeholderPattern
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toList();
  }
  
  /// Checks if two lists of placeholders match
  static bool _placeholdersMatch(List<String> original, List<String> translation) {
    if (original.length != translation.length) return false;
    
    final originalSet = original.toSet();
    final translationSet = translation.toSet();
    
    return originalSet.difference(translationSet).isEmpty &&
           translationSet.difference(originalSet).isEmpty;
  }
  
  /// Validates a language code (basic validation)
  static bool _isValidLanguageCode(String languageCode) {
    // Basic validation for common language codes
    final pattern = RegExp(r'^[a-z]{2}(_[A-Z]{2})?$');
    return pattern.hasMatch(languageCode);
  }
  
  /// Validates file extension
  static bool hasValidDartExtension(String filePath) {
    return path.extension(filePath).toLowerCase() == '.dart';
  }
  
  /// Validates that a path is within allowed scan paths
  static bool isWithinScanPaths(String filePath, List<String> scanPaths) {
    final normalizedFilePath = path.normalize(path.absolute(filePath));
    
    return scanPaths.any((scanPath) {
      final normalizedScanPath = path.normalize(path.absolute(scanPath));
      return normalizedFilePath.startsWith(normalizedScanPath);
    });
  }
  
  /// Validates that a path should not be excluded
  static bool shouldExclude(String filePath, List<String> excludePatterns) {
    final normalizedPath = path.normalize(filePath);
    
    return excludePatterns.any((pattern) {
      try {
        final regex = RegExp(pattern);
        return regex.hasMatch(normalizedPath);
      } catch (e) {
        // If pattern is not a valid regex, treat as literal string
        return normalizedPath.contains(pattern);
      }
    });
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final List<String> issues;
  
  const ValidationResult({
    required this.isValid,
    required this.issues,
  });
  
  /// Returns true if there are no validation issues
  bool get hasNoIssues => issues.isEmpty;
  
  /// Returns a formatted string of all issues
  String get issuesText => issues.join('\n');
  
  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, issues: ${issues.length})';
  }
}