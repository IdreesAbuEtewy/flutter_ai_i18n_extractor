import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Manages import statements in Dart files for localization
class ImportManager {
  static const String _flutterGenImport = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';";
  static const String _flutterImport = "import 'package:flutter/material.dart';";
  
  /// Ensures that the necessary imports are present in a Dart file
  static Future<String> ensureImports(String filePath, String content) async {
    final parseResult = parseString(content: content);
    final unit = parseResult.unit;
    
    final visitor = _ImportVisitor();
    unit.accept(visitor);
    
    bool hasFlutterGenImport = visitor.imports.any((import) => 
        import.uri.stringValue?.contains('flutter_gen/gen_l10n/app_localizations.dart') == true);
    bool hasFlutterImport = visitor.imports.any((import) => 
        import.uri.stringValue?.contains('package:flutter/material.dart') == true);
    
    if (hasFlutterGenImport && hasFlutterImport) {
      return content; // All imports already present
    }
    
    final lines = content.split('\n');
    int insertIndex = _findImportInsertIndex(lines, visitor.imports);
    
    final importsToAdd = <String>[];
    if (!hasFlutterImport) {
      importsToAdd.add(_flutterImport);
    }
    if (!hasFlutterGenImport) {
      importsToAdd.add(_flutterGenImport);
    }
    
    // Insert imports at the appropriate location
    for (int i = importsToAdd.length - 1; i >= 0; i--) {
      lines.insert(insertIndex, importsToAdd[i]);
    }
    
    return lines.join('\n');
  }
  
  /// Finds the best position to insert new imports
  static int _findImportInsertIndex(List<String> lines, List<ImportDirective> existingImports) {
    if (existingImports.isEmpty) {
      // Find the first non-comment, non-empty line after any library directive
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('library ')) {
          // Insert after library directive
          return i + 1;
        }
        if (line.isNotEmpty && !line.startsWith('//') && !line.startsWith('/*')) {
          // Insert before the first code line
          return i;
        }
      }
      return 0;
    }
    
    // Insert after the last import
    final lastImport = existingImports.last;
    final lastImportLine = lastImport.end;
    
    // Find the line number corresponding to the last import
    int lineNumber = 0;
    int charCount = 0;
    for (int i = 0; i < lines.length; i++) {
      charCount += lines[i].length + 1; // +1 for newline
      if (charCount > lastImportLine) {
        lineNumber = i + 1;
        break;
      }
    }
    
    return lineNumber;
  }
  
  /// Checks if a file needs localization imports
  static bool needsLocalizationImports(String content) {
    return content.contains('AppLocalizations.of(context)') ||
           content.contains('context.l10n') ||
           content.contains('.l10n.');
  }
  
  /// Removes unused imports (basic implementation)
  static String removeUnusedImports(String content) {
    final parseResult = parseString(content: content);
    final unit = parseResult.unit;
    
    final visitor = _ImportUsageVisitor();
    unit.accept(visitor);
    
    final lines = content.split('\n');
    final linesToRemove = <int>{};
    
    for (final import in visitor.unusedImports) {
      final importLine = _getLineNumber(content, import.offset);
      if (importLine >= 0 && importLine < lines.length) {
        linesToRemove.add(importLine);
      }
    }
    
    // Remove lines in reverse order to maintain indices
    final sortedLinesToRemove = linesToRemove.toList()..sort((a, b) => b.compareTo(a));
    for (final lineIndex in sortedLinesToRemove) {
      lines.removeAt(lineIndex);
    }
    
    return lines.join('\n');
  }
  
  /// Gets the line number for a given character offset
  static int _getLineNumber(String content, int offset) {
    int charCount = 0;
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      if (charCount + lines[i].length >= offset) {
        return i;
      }
      charCount += lines[i].length + 1; // +1 for newline
    }
    
    return -1;
  }
}

/// Visitor to collect import directives
class _ImportVisitor extends RecursiveAstVisitor<void> {
  final List<ImportDirective> imports = [];
  
  @override
  void visitImportDirective(ImportDirective node) {
    imports.add(node);
    super.visitImportDirective(node);
  }
}

/// Visitor to find unused imports
class _ImportUsageVisitor extends RecursiveAstVisitor<void> {
  final List<ImportDirective> allImports = [];
  final Set<String> usedIdentifiers = {};
  final List<ImportDirective> unusedImports = [];
  
  @override
  void visitImportDirective(ImportDirective node) {
    allImports.add(node);
    super.visitImportDirective(node);
  }
  
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    usedIdentifiers.add(node.name);
    super.visitSimpleIdentifier(node);
  }
  
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    usedIdentifiers.add(node.prefix.name);
    usedIdentifiers.add(node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }
  
  /// Call this after visiting to determine unused imports
  void analyzeUsage() {
    for (final import in allImports) {
      final uri = import.uri.stringValue;
      if (uri == null) continue;
      
      // Skip dart: and flutter: core imports as they're often implicitly used
      if (uri.startsWith('dart:') || uri.contains('flutter/material.dart')) {
        continue;
      }
      
      // Check if any identifiers from this import are used
      bool isUsed = false;
      
      // Simple heuristic: if the import has a prefix, check if prefix is used
      if (import.prefix != null) {
        isUsed = usedIdentifiers.contains(import.prefix!.name);
      } else {
        // For non-prefixed imports, this is more complex
        // For now, assume they're used if they're not obviously unused
        isUsed = true;
      }
      
      if (!isUsed) {
        unusedImports.add(import);
      }
    }
  }
}