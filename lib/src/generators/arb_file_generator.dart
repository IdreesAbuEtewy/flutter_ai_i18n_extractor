import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../core/extractor_config.dart';
import '../core/extracted_string.dart';
import '../core/localization_entry.dart';

/// Generates ARB (Application Resource Bundle) files for Flutter localization
class ArbFileGenerator {
  final ExtractorConfig config;
  
  ArbFileGenerator(this.config);

  /// Generates ARB files for all configured languages
  Future<void> generateArbFiles(List<LocalizationEntry> entries) async {
    print('Generating ARB files for ${config.languages.length} languages...');
    
    // Ensure output directory exists
    final outputDir = Directory(config.l10n.arbDir);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    
    // Generate ARB file for each language
    for (final languageCode in config.languages) {
      await _generateArbFile(entries, languageCode);
    }
    
    print('ARB files generated successfully in ${config.l10n.arbDir}');
  }
  
  /// Generates an ARB file for a specific language
  Future<void> _generateArbFile(List<LocalizationEntry> entries, String languageCode) async {
    final fileName = 'app_$languageCode.arb';
    final filePath = path.join(config.l10n.arbDir, fileName);
    
    // Build ARB content
    final arbContent = _buildArbContent(entries, languageCode);
    
    // Write to file
    final file = File(filePath);
    await file.writeAsString(arbContent);
    
    print('Generated $fileName with ${entries.length} entries');
  }
  
  /// Builds the ARB file content for a language
  String _buildArbContent(List<LocalizationEntry> entries, String languageCode) {
    final arbMap = <String, dynamic>{};
    
    // Add locale metadata
    arbMap['@@locale'] = languageCode;
    arbMap['@@last_modified'] = DateTime.now().toIso8601String();
    
    // Add entries
    for (final entry in entries) {
      final translation = entry.getTranslation(languageCode);
      if (translation.isNotEmpty) {
        // Add the translation
        arbMap[entry.key] = translation;
        
        // Add metadata for the entry
        final metadata = _buildEntryMetadata(entry);
        if (metadata.isNotEmpty) {
          arbMap['@${entry.key}'] = metadata;
        }
      }
    }
    
    // Convert to formatted JSON
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(arbMap);
  }
  
  /// Builds metadata for an ARB entry
  Map<String, dynamic> _buildEntryMetadata(LocalizationEntry entry) {
    final metadata = <String, dynamic>{};
    
    // Add description based on context
    final description = _generateDescription(entry);
    if (description.isNotEmpty) {
      metadata['description'] = description;
    }
    
    // Add placeholders if the text contains parameters
    final placeholders = _extractPlaceholders(entry.originalText);
    if (placeholders.isNotEmpty) {
      metadata['placeholders'] = placeholders;
    }
    
    // Add context information
    if (entry.contextType != null) {
      metadata['context'] = entry.contextType!.name;
    }
    
    // Add source location for debugging
    if (config.processing.includeSourceInfo) {
      metadata['source'] = {
        'file': entry.extractedString.filePath,
        'line': entry.extractedString.lineNumber,
      };
    }
    
    return metadata;
  }
  
  /// Generates a description for the entry based on its context
  String _generateDescription(LocalizationEntry entry) {
    final parts = <String>[];
    
    // Add context type
    if (entry.contextType != null) {
      parts.add(entry.contextType!.displayName);
    }
    
    // Add widget information
    if (entry.widgetType != null) {
      parts.add('in ${entry.widgetType}');
    }
    
    // Add screen context
    if (entry.extractedString.context?.screenContext != null) {
      parts.add('on ${entry.extractedString.context!.screenContext} screen');
    }
    
    return parts.isEmpty ? '' : parts.join(' ');
  }
  
  /// Extracts placeholders from text (e.g., {name}, {count})
  Map<String, Map<String, String>> _extractPlaceholders(String text) {
    final placeholders = <String, Map<String, String>>{};
    
    // Find Flutter-style placeholders: {variable}
    final placeholderRegex = RegExp(r'\{([a-zA-Z_][a-zA-Z0-9_]*)\}');
    final matches = placeholderRegex.allMatches(text);
    
    for (final match in matches) {
      final placeholderName = match.group(1)!;
      placeholders[placeholderName] = {
        'type': 'String', // Default type
        'example': _generatePlaceholderExample(placeholderName),
      };
    }
    
    // Find numbered placeholders: {0}, {1}, etc.
    final numberedRegex = RegExp(r'\{(\d+)\}');
    final numberedMatches = numberedRegex.allMatches(text);
    
    for (final match in numberedMatches) {
      final placeholderName = 'arg${match.group(1)}';
      placeholders[placeholderName] = {
        'type': 'String',
        'example': 'value',
      };
    }
    
    return placeholders;
  }
  
  /// Generates an example value for a placeholder based on its name
  String _generatePlaceholderExample(String placeholderName) {
    final name = placeholderName.toLowerCase();
    
    if (name.contains('name')) return 'John';
    if (name.contains('count') || name.contains('number')) return '5';
    if (name.contains('email')) return 'user@example.com';
    if (name.contains('date')) return '2024-01-01';
    if (name.contains('time')) return '10:30';
    if (name.contains('price') || name.contains('amount')) return '\$10.99';
    if (name.contains('percent')) return '75%';
    if (name.contains('url') || name.contains('link')) return 'https://example.com';
    
    return 'value';
  }
  
  /// Updates existing ARB files by merging with new entries
  Future<void> updateArbFiles(List<LocalizationEntry> newEntries) async {
    print('Updating existing ARB files...');
    
    for (final languageCode in config.languages) {
      await _updateArbFile(newEntries, languageCode);
    }
    
    print('ARB files updated successfully.');
  }
  
  /// Updates an existing ARB file for a specific language
  Future<void> _updateArbFile(List<LocalizationEntry> newEntries, String languageCode) async {
    final fileName = 'app_$languageCode.arb';
    final filePath = path.join(config.l10n.arbDir, fileName);
    final file = File(filePath);
    
    Map<String, dynamic> existingContent = {};
    
    // Load existing content if file exists
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        existingContent = json.decode(content) as Map<String, dynamic>;
      } catch (e) {
        print('Warning: Could not parse existing ARB file $fileName: $e');
      }
    }
    
    // Merge with new entries
    final mergedContent = _mergeArbContent(existingContent, newEntries, languageCode);
    
    // Write updated content
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(mergedContent));
    
    print('Updated $fileName');
  }
  
  /// Merges existing ARB content with new entries
  Map<String, dynamic> _mergeArbContent(
    Map<String, dynamic> existing,
    List<LocalizationEntry> newEntries,
    String languageCode,
  ) {
    final merged = Map<String, dynamic>.from(existing);
    
    // Update metadata
    merged['@@locale'] = languageCode;
    merged['@@last_modified'] = DateTime.now().toIso8601String();
    
    // Add or update entries
    for (final entry in newEntries) {
      final translation = entry.getTranslation(languageCode);
      if (translation.isNotEmpty) {
        // Only update if the translation is different or key doesn't exist
        if (!merged.containsKey(entry.key) || merged[entry.key] != translation) {
          merged[entry.key] = translation;
          
          // Update metadata
          final metadata = _buildEntryMetadata(entry);
          if (metadata.isNotEmpty) {
            merged['@${entry.key}'] = metadata;
          }
        }
      }
    }
    
    return merged;
  }
  
  /// Removes unused entries from ARB files
  Future<void> cleanupArbFiles(List<LocalizationEntry> activeEntries) async {
    print('Cleaning up unused entries from ARB files...');
    
    final activeKeys = activeEntries.map((e) => e.key).toSet();
    
    for (final languageCode in config.languages) {
      await _cleanupArbFile(activeKeys, languageCode);
    }
    
    print('ARB files cleaned up successfully.');
  }
  
  /// Removes unused entries from a specific ARB file
  Future<void> _cleanupArbFile(Set<String> activeKeys, String languageCode) async {
    final fileName = 'app_$languageCode.arb';
    final filePath = path.join(config.l10n.arbDir, fileName);
    final file = File(filePath);
    
    if (!await file.exists()) return;
    
    try {
      final content = await file.readAsString();
      final arbContent = json.decode(content) as Map<String, dynamic>;
      
      final cleanedContent = <String, dynamic>{};
      
      // Keep metadata entries
      arbContent.forEach((key, value) {
        if (key.startsWith('@@')) {
          cleanedContent[key] = value;
        } else if (key.startsWith('@')) {
          // Keep metadata if the corresponding key is active
          final entryKey = key.substring(1);
          if (activeKeys.contains(entryKey)) {
            cleanedContent[key] = value;
          }
        } else {
          // Keep entry if it's active
          if (activeKeys.contains(key)) {
            cleanedContent[key] = value;
          }
        }
      });
      
      // Update last modified
      cleanedContent['@@last_modified'] = DateTime.now().toIso8601String();
      
      // Write cleaned content
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(cleanedContent));
      
      final removedCount = arbContent.length - cleanedContent.length;
      if (removedCount > 0) {
        print('Removed $removedCount unused entries from $fileName');
      }
      
    } catch (e) {
      print('Warning: Could not clean up ARB file $fileName: $e');
    }
  }
  
  /// Validates ARB files for consistency and correctness
  Future<List<String>> validateArbFiles() async {
    final issues = <String>[];
    
    for (final languageCode in config.languages) {
      final fileName = 'app_$languageCode.arb';
      final filePath = path.join(config.l10n.arbDir, fileName);
      final file = File(filePath);
      
      if (!await file.exists()) {
        issues.add('Missing ARB file: $fileName');
        continue;
      }
      
      try {
        final content = await file.readAsString();
        final arbContent = json.decode(content) as Map<String, dynamic>;
        
        // Validate structure
        if (!arbContent.containsKey('@@locale')) {
          issues.add('$fileName: Missing @@locale metadata');
        } else if (arbContent['@@locale'] != languageCode) {
          issues.add('$fileName: Incorrect locale metadata');
        }
        
        // Check for orphaned metadata
        final entryKeys = arbContent.keys
            .where((key) => !key.startsWith('@'))
            .toSet();
        
        final metadataKeys = arbContent.keys
            .where((key) => key.startsWith('@') && !key.startsWith('@@'))
            .map((key) => key.substring(1))
            .toSet();
        
        final orphanedMetadata = metadataKeys.difference(entryKeys);
        if (orphanedMetadata.isNotEmpty) {
          issues.add('$fileName: Orphaned metadata for keys: ${orphanedMetadata.join(', ')}');
        }
        
      } catch (e) {
        issues.add('$fileName: Invalid JSON format - $e');
      }
    }
    
    return issues;
  }
  
  /// Gets statistics about the generated ARB files
  Future<Map<String, dynamic>> getStatistics() async {
    final stats = <String, dynamic>{
      'languages': config.languages,
      'files': <String, Map<String, dynamic>>{},
    };
    
    for (final languageCode in config.languages) {
      final fileName = 'app_$languageCode.arb';
      final filePath = path.join(config.l10n.arbDir, fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final arbContent = json.decode(content) as Map<String, dynamic>;
          
          final entryCount = arbContent.keys
              .where((key) => !key.startsWith('@'))
              .length;
          
          final metadataCount = arbContent.keys
              .where((key) => key.startsWith('@') && !key.startsWith('@@'))
              .length;
          
          stats['files'][languageCode] = {
            'file_name': fileName,
            'entry_count': entryCount,
            'metadata_count': metadataCount,
            'file_size': await file.length(),
            'last_modified': arbContent['@@last_modified'],
          };
          
        } catch (e) {
          stats['files'][languageCode] = {
            'file_name': fileName,
            'error': 'Could not parse file: $e',
          };
        }
      } else {
        stats['files'][languageCode] = {
          'file_name': fileName,
          'exists': false,
        };
      }
    }
    
    return stats;
  }
}