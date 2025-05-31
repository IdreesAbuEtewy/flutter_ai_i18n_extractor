import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../core/extractor_config.dart';
import '../core/localization_entry.dart';
import '../core/extracted_string.dart';

/// Replaces hardcoded strings in Dart files with localization calls
class CodeReplacer {
  final ExtractorConfig config;
  final Map<String, List<LocalizationEntry>> _fileEntries = {};
  
  CodeReplacer(this.config);

  /// Replaces hardcoded strings with localization calls
  Future<void> replaceStrings(List<LocalizationEntry> entries) async {
    print('Replacing hardcoded strings with localization calls...');
    
    // Group entries by file for efficient processing
    _groupEntriesByFile(entries);
    
    int filesModified = 0;
    int stringsReplaced = 0;
    
    for (final filePath in _fileEntries.keys) {
      final fileEntries = _fileEntries[filePath]!;
      final result = await _replaceStringsInFile(filePath, fileEntries);
      
      if (result.modified) {
        filesModified++;
        stringsReplaced += result.replacementCount;
      }
    }
    
    print('Replacement completed: $stringsReplaced strings replaced in $filesModified files.');
  }

  /// Replaces hardcoded strings in files with localization calls
  /// This method takes extracted strings and their corresponding localization entries
  Future<void> replaceStringsInFiles(List<ExtractedString> extractedStrings, List<LocalizationEntry> entries) async {
    // Create a map from extracted strings to their localization entries
    final stringToEntryMap = <ExtractedString, LocalizationEntry>{};
    
    for (final entry in entries) {
      stringToEntryMap[entry.extractedString] = entry;
    }
    
    // Filter entries that have corresponding extracted strings
    final validEntries = extractedStrings
        .where((str) => stringToEntryMap.containsKey(str))
        .map((str) => stringToEntryMap[str]!)
        .toList();
    
    // Use the existing replaceStrings method
    await replaceStrings(validEntries);
  }
  
  /// Groups localization entries by their source file
  void _groupEntriesByFile(List<LocalizationEntry> entries) {
    _fileEntries.clear();
    
    for (final entry in entries) {
      final filePath = entry.extractedString.filePath;
      _fileEntries.putIfAbsent(filePath, () => []).add(entry);
    }
  }
  
  /// Replaces strings in a specific file
  Future<ReplacementResult> _replaceStringsInFile(
    String filePath,
    List<LocalizationEntry> entries,
  ) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      print('Warning: File not found: $filePath');
      return ReplacementResult(modified: false, replacementCount: 0);
    }
    
    try {
      final content = await file.readAsString();
      final parseResult = parseString(content: content, path: filePath);
      
      if (parseResult.errors.isNotEmpty) {
        print('Warning: Parse errors in $filePath:');
        for (final error in parseResult.errors) {
          print('  ${error.message}');
        }
        return ReplacementResult(modified: false, replacementCount: 0);
      }
      
      final replacer = StringReplacementVisitor(entries, content);
      parseResult.unit.accept(replacer);
      
      if (replacer.hasReplacements) {
        final newContent = replacer.getModifiedContent();
        
        // Add import if needed
        final finalContent = _ensureLocalizationImport(newContent, filePath);
        
        // Create backup if configured
        if (config.processing.createBackups) {
          await _createBackup(filePath);
        }
        
        // Write modified content
        await file.writeAsString(finalContent);
        
        print('Modified $filePath: ${replacer.replacementCount} strings replaced');
        return ReplacementResult(
          modified: true,
          replacementCount: replacer.replacementCount,
        );
      }
      
      return ReplacementResult(modified: false, replacementCount: 0);
      
    } catch (e) {
      print('Error processing $filePath: $e');
      return ReplacementResult(modified: false, replacementCount: 0);
    }
  }
  
  /// Ensures the localization import is present in the file
  String _ensureLocalizationImport(String content, String filePath) {
    final lines = content.split('\n');
    
    // Check if import already exists
    final hasImport = lines.any((line) => 
        line.contains('flutter_gen/gen_l10n/app_localizations.dart') ||
        line.contains('package:flutter_gen/gen_l10n/app_localizations.dart'));
    
    if (hasImport) {
      return content;
    }
    
    // Find the best place to insert the import
    int insertIndex = 0;
    bool foundImports = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('import ')) {
        foundImports = true;
        insertIndex = i + 1;
      } else if (foundImports && !line.startsWith('import ') && line.isNotEmpty) {
        break;
      }
    }
    
    // Insert the import
    final importLine = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';";
    lines.insert(insertIndex, importLine);
    
    return lines.join('\n');
  }
  
  /// Creates a backup of the original file
  Future<void> _createBackup(String filePath) async {
    final file = File(filePath);
    final backupPath = '$filePath.backup';
    await file.copy(backupPath);
  }
  
  /// Validates that replacements were successful
  Future<List<String>> validateReplacements(List<LocalizationEntry> entries) async {
    final issues = <String>[];
    
    for (final entry in entries) {
      final filePath = entry.extractedString.filePath;
      final file = File(filePath);
      
      if (!await file.exists()) {
        issues.add('File not found: $filePath');
        continue;
      }
      
      try {
        final content = await file.readAsString();
        
        // Check if the original string still exists (shouldn't after replacement)
        if (content.contains('"${entry.originalText}"') || 
            content.contains("'${entry.originalText}'")) {
          issues.add('Original string still found in $filePath: "${entry.originalText}"');
        }
        
        // Check if the localization call exists
        final expectedCall = _generateLocalizationCall(entry.key);
        if (!content.contains(expectedCall)) {
          issues.add('Localization call not found in $filePath: $expectedCall');
        }
        
      } catch (e) {
        issues.add('Error validating $filePath: $e');
      }
    }
    
    return issues;
  }
  
  /// Generates the appropriate localization call for a key
  String _generateLocalizationCall(String key) {
    return 'AppLocalizations.of(context)!.$key';
  }
  
  /// Restores files from backups
  Future<void> restoreFromBackups(List<String> filePaths) async {
    print('Restoring files from backups...');
    
    int restoredCount = 0;
    
    for (final filePath in filePaths) {
      final backupPath = '$filePath.backup';
      final backupFile = File(backupPath);
      
      if (await backupFile.exists()) {
        await backupFile.copy(filePath);
        await backupFile.delete();
        restoredCount++;
        print('Restored $filePath');
      } else {
        print('Warning: Backup not found for $filePath');
      }
    }
    
    print('Restored $restoredCount files from backups.');
  }
}

/// Result of string replacement operation
class ReplacementResult {
  final bool modified;
  final int replacementCount;
  
  const ReplacementResult({
    required this.modified,
    required this.replacementCount,
  });
}

/// AST visitor that performs string replacements
class StringReplacementVisitor extends RecursiveAstVisitor<void> {
  final List<LocalizationEntry> entries;
  final String originalContent;
  final List<TextReplacement> _replacements = [];
  
  StringReplacementVisitor(this.entries, this.originalContent);
  
  bool get hasReplacements => _replacements.isNotEmpty;
  int get replacementCount => _replacements.length;
  
  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final stringValue = node.value;
    
    try {
      final entry = entries.firstWhere(
        (entry) => entry.originalText == stringValue &&
         _isCorrectLocation(entry.extractedString, node),
      );
      
      // Create replacement
      final localizationCall = _generateLocalizationCall(entry.key);
      
      _replacements.add(TextReplacement(
        offset: node.offset,
        length: node.length,
        replacement: localizationCall,
      ));
      
    } catch (e) {
      // No exact match found, skip this string
    }
    
    super.visitSimpleStringLiteral(node);
  }
  
  /// Checks if the node location matches the extracted string location
  bool _isCorrectLocation(ExtractedString extractedString, AstNode node) {
    // Compare line numbers (allowing for small differences due to parsing)
    final nodeLine = _getLineNumber(node.offset);
    final extractedLine = extractedString.lineNumber;
    
    return (nodeLine - extractedLine).abs() <= 2; // Allow 2-line tolerance
  }
  
  /// Gets the line number for a given offset
  int _getLineNumber(int offset) {
    int lineNumber = 1;
    for (int i = 0; i < offset && i < originalContent.length; i++) {
      if (originalContent[i] == '\n') {
        lineNumber++;
      }
    }
    return lineNumber;
  }
  
  /// Generates the localization call for a key
  String _generateLocalizationCall(String key) {
    return 'AppLocalizations.of(context)!.$key';
  }
  
  /// Gets the modified content with all replacements applied
  String getModifiedContent() {
    if (_replacements.isEmpty) {
      return originalContent;
    }
    
    // Sort replacements by offset in descending order
    // This ensures we don't mess up offsets when applying replacements
    _replacements.sort((a, b) => b.offset.compareTo(a.offset));
    
    String modifiedContent = originalContent;
    
    for (final replacement in _replacements) {
      modifiedContent = modifiedContent.replaceRange(
        replacement.offset,
        replacement.offset + replacement.length,
        replacement.replacement,
      );
    }
    
    return modifiedContent;
  }
}

/// Represents a text replacement operation
class TextReplacement {
  final int offset;
  final int length;
  final String replacement;
  
  const TextReplacement({
    required this.offset,
    required this.length,
    required this.replacement,
  });
  
  @override
  String toString() {
    return 'TextReplacement(offset: $offset, length: $length, replacement: "$replacement")';
  }
}