import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import '../core/extractor_config.dart';
import '../core/extracted_string.dart';

/// Scanner that finds and extracts strings from Dart files using AST parsing
class DartFileScanner {
  final ExtractorConfig config;
  
  const DartFileScanner(this.config);

  /// Finds all Dart files to scan based on configuration
  Future<List<String>> findDartFiles() async {
    final files = <String>[];
    
    for (final scanPath in config.scanPaths) {
      final dartFiles = await _findDartFilesInPath(scanPath);
      files.addAll(dartFiles);
    }
    
    // Filter out excluded patterns
    final filteredFiles = <String>[];
    for (final file in files) {
      if (!_isExcluded(file)) {
        filteredFiles.add(file);
      }
    }
    
    return filteredFiles;
  }

  /// Finds Dart files in a specific path
  Future<List<String>> _findDartFilesInPath(String scanPath) async {
    final files = <String>[];
    final directory = Directory(scanPath);
    
    if (!directory.existsSync()) {
      return files;
    }
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity.path);
      }
    }
    
    return files;
  }

  /// Checks if a file should be excluded based on patterns
  bool _isExcluded(String filePath) {
    for (final pattern in config.excludePatterns) {
      final glob = Glob(pattern);
      if (glob.matches(path.basename(filePath)) || 
          glob.matches(filePath) ||
          filePath.contains(pattern.replaceAll('**/', '').replaceAll('*', ''))) {
        return true;
      }
    }
    return false;
  }

  /// Extracts strings from a specific Dart file
  Future<List<ExtractedString>> extractStringsFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return [];
      }
      
      final content = await file.readAsString();
      
      // Parse the Dart file into an AST
      final parseResult = parseString(
        content: content,
        path: filePath,
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      
      if (parseResult.errors.isNotEmpty) {
        // Log parsing errors but continue
        print('Warning: Parse errors in $filePath:');
        for (final error in parseResult.errors) {
          print('  ${error.message}');
        }
      }
      
      // Visit the AST to extract strings
      final visitor = _StringExtractorVisitor(filePath, content);
      parseResult.unit.accept(visitor);
      
      return visitor.extractedStrings;
    } catch (e) {
      print('Error processing file $filePath: $e');
      return [];
    }
  }
}

/// AST visitor that extracts string literals from Dart code
class _StringExtractorVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String sourceContent;
  final List<ExtractedString> extractedStrings = [];
  final List<String> _lines;
  
  _StringExtractorVisitor(this.filePath, this.sourceContent)
      : _lines = sourceContent.split('\n');

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _processStringLiteral(node, node.value);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // Handle concatenated strings like 'Hello ' 'World'
    final combinedValue = node.stringValue ?? '';
    if (combinedValue.isNotEmpty) {
      _processStringLiteral(node, combinedValue);
    }
    super.visitAdjacentStrings(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    // For now, skip interpolated strings as they need special handling
    // TODO: Implement support for extracting parts of interpolated strings
    super.visitStringInterpolation(node);
  }

  void _processStringLiteral(AstNode node, String value) {
    // Skip empty strings
    if (value.trim().isEmpty) return;
    
    // Get position information
    final offset = node.offset;
    final length = node.length;
    final lineInfo = _getLineInfo(offset);
    
    // Get surrounding context
    final context = _analyzeSurroundingContext(node);
    
    // Check if already localized
    final isLocalized = _isAlreadyLocalized(node);
    
    final extractedString = ExtractedString(
      value: value,
      filePath: filePath,
      lineNumber: lineInfo.lineNumber,
      columnNumber: lineInfo.columnNumber,
      offset: offset,
      length: length,
      widgetType: context.widgetType,
      parameterName: context.parameterName,
      surroundingCode: context.surroundingCode,
      isAlreadyLocalized: isLocalized,
    );
    
    // Only add if it should be extracted
    if (extractedString.shouldExtract) {
      extractedStrings.add(extractedString);
    }
  }

  /// Gets line and column information for an offset
  ({int lineNumber, int columnNumber}) _getLineInfo(int offset) {
    int currentOffset = 0;
    for (int i = 0; i < _lines.length; i++) {
      final lineLength = _lines[i].length + 1; // +1 for newline
      if (currentOffset + lineLength > offset) {
        return (
          lineNumber: i + 1,
          columnNumber: offset - currentOffset + 1,
        );
      }
      currentOffset += lineLength;
    }
    return (lineNumber: _lines.length, columnNumber: 1);
  }

  /// Analyzes the surrounding context of a string literal
  _StringContext _analyzeSurroundingContext(AstNode node) {
    String? widgetType;
    String? parameterName;
    String? surroundingCode;
    
    // Walk up the AST to find context
    AstNode? current = node.parent;
    
    while (current != null) {
      if (current is NamedExpression) {
        // This string is a named parameter
        parameterName = current.name.label.name;
        current = current.parent;
      } else if (current is ArgumentList) {
        current = current.parent;
      } else if (current is InstanceCreationExpression) {
        // Found the widget constructor
        final constructorName = current.constructorName.type.name2.lexeme;
        widgetType = constructorName;
        break;
      } else if (current is MethodInvocation) {
        // Found a method call (like showDialog)
        final methodName = current.methodName.name;
        widgetType = methodName;
        break;
      } else {
        current = current.parent;
      }
    }
    
    // Get surrounding code for additional context
    final startOffset = node.offset - 50;
    final endOffset = node.offset + node.length + 50;
    final safeStart = startOffset < 0 ? 0 : startOffset;
    final safeEnd = endOffset > sourceContent.length ? sourceContent.length : endOffset;
    
    surroundingCode = sourceContent.substring(safeStart, safeEnd)
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    return _StringContext(
      widgetType: widgetType,
      parameterName: parameterName,
      surroundingCode: surroundingCode,
    );
  }

  /// Checks if a string is already localized
  bool _isAlreadyLocalized(AstNode node) {
    // Look for patterns like AppLocalizations.of(context).keyName
    // or l10n.keyName
    AstNode? current = node.parent;
    
    while (current != null) {
      final nodeString = current.toString();
      if (nodeString.contains('AppLocalizations') ||
          nodeString.contains('l10n.') ||
          nodeString.contains('.of(context)')) {
        return true;
      }
      current = current.parent;
    }
    
    return false;
  }
}

/// Helper class to hold string context information
class _StringContext {
  final String? widgetType;
  final String? parameterName;
  final String? surroundingCode;
  
  const _StringContext({
    this.widgetType,
    this.parameterName,
    this.surroundingCode,
  });
}