#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:colorize/colorize.dart';
import 'package:flutter_ai_i18n_extractor/flutter_ai_i18n_extractor.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show usage information')
    ..addFlag('dry-run', help: 'Preview changes without modifying files')
    ..addFlag('verbose', abbr: 'v', help: 'Show detailed output')
    ..addFlag('preview', abbr: 'p', help: 'Show extracted strings and allow selection before processing')
    ..addOption('config', abbr: 'c', help: 'Path to configuration file', defaultsTo: 'ai_i18n_config.yaml')
    ..addOption('files', help: 'Comma-separated list of specific files to process')
    ..addCommand('init')
    ..addCommand('extract')
    ..addCommand('update')
    ..addCommand('validate')
    ..addCommand('stats');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _showHelp(parser);
      return;
    }

    final command = results.command?.name ?? 'extract';
    final configPath = results['config'] as String;
    final dryRun = results['dry-run'] as bool;
    final verbose = results['verbose'] as bool;
    final preview = results['preview'] as bool;
    final files = results['files'] as String?;

    switch (command) {
      case 'init':
        await _initCommand(configPath, verbose);
        break;
      case 'extract':
        await _extractCommand(configPath, dryRun, verbose, preview, files);
        break;
      case 'update':
        await _updateCommand(configPath, verbose);
        break;
      case 'validate':
        await _validateCommand(configPath, verbose);
        break;
      case 'stats':
        await _statsCommand(configPath, verbose);
        break;
      default:
        _printError('Unknown command: $command');
        _showHelp(parser);
        exit(1);
    }
  } catch (e) {
    _printError('Error parsing arguments: $e');
    _showHelp(parser);
    exit(1);
  }
}

void _showHelp(ArgParser parser) {
  print(Colorize('Flutter AI i18n Extractor').bold());
  print('Automatically extract and translate hardcoded strings in Flutter projects.\n');
  print('Usage: dart run flutter_ai_i18n_extractor <command> [options]\n');
  print('Commands:');
  print('  init      Initialize configuration in existing Flutter project');
  print('  extract   Extract and process all strings (default)');
  print('  update    Update existing translations with new strings');
  print('  validate  Validate existing ARB files');
  print('  stats     Show extraction statistics\n');
  print('Options:');
  print('  --preview, -p    Show extracted strings and allow selection before processing');
  print('  --dry-run        Preview changes without modifying files');
  print('  --verbose, -v    Show detailed output\n');
  print(parser.usage);
}

Future<void> _initCommand(String configPath, bool verbose) async {
  try {
    _printInfo('Initializing Flutter AI i18n Extractor...');
    
    // Check if this is a Flutter project
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      _printError('No pubspec.yaml found. Please run this command in a Flutter project root.');
      exit(1);
    }
    
    // Create default configuration
    final configFile = File(configPath);
    if (configFile.existsSync()) {
      _printWarning('Configuration file already exists: $configPath');
      return;
    }
    
    final defaultConfig = ExtractorConfig.defaultConfig();
    await FileUtils.writeYamlFile(configPath, defaultConfig.toMap());
    
    _printSuccess('Configuration file created: $configPath');
    _printInfo('Please update the AI API key and other settings in the configuration file.');
    
  } catch (e) {
    _printError('Failed to initialize: $e');
    exit(1);
  }
}

Future<void> _extractCommand(String configPath, bool dryRun, bool verbose, bool preview, String? files) async {
  try {
    _printInfo('Loading configuration...');
    final config = await ExtractorConfig.fromFile(configPath);
    
    if (dryRun) {
      _printInfo('Running in dry-run mode - no files will be modified');
    }
    
    final scanner = DartFileScanner(config);
    final contextAnalyzer = ContextAnalyzer();
    final abbreviationGenerator = AbbreviationGenerator(config);
    final translator = ProfessionalTranslator(config);
    final arbGenerator = ArbFileGenerator(config);
    final codeReplacer = CodeReplacer(config);
    
    List<String> filesToProcess;
    if (files != null) {
      filesToProcess = files.split(',').map((f) => f.trim()).toList();
      _printInfo('Processing specific files: ${filesToProcess.join(', ')}');
    } else {
      _printInfo('Scanning for Dart files...');
      filesToProcess = await scanner.findDartFiles();
      _printInfo('Found ${filesToProcess.length} Dart files to process');
    }
    
    final allExtractedStrings = <ExtractedString>[];
    
    for (final filePath in filesToProcess) {
      if (verbose) {
        _printInfo('Processing: $filePath');
      }
      
      final extractedStrings = await scanner.extractStringsFromFile(filePath);
      if (extractedStrings.isNotEmpty) {
        allExtractedStrings.addAll(extractedStrings);
        if (verbose) {
          _printInfo('  Found ${extractedStrings.length} strings');
        }
      }
    }
    
    if (allExtractedStrings.isEmpty) {
      _printWarning('No extractable strings found.');
      return;
    }
    
    _printInfo('Analyzing context for ${allExtractedStrings.length} strings...');
    for (int i = 0; i < allExtractedStrings.length; i++) {
      final extractedString = allExtractedStrings[i];
      final context = await contextAnalyzer.analyzeContext(extractedString);
      allExtractedStrings[i] = extractedString.copyWith(context: context);
    }

    // Preview and selection feature
    List<ExtractedString> selectedStrings = allExtractedStrings;
    if (preview) {
      selectedStrings = await _showPreviewAndGetSelection(allExtractedStrings);
      if (selectedStrings.isEmpty) {
        _printWarning('No strings selected for processing.');
        return;
      }
    }

    _printInfo('Generating intelligent keys for ${selectedStrings.length} strings...');
    final localizationEntries = await abbreviationGenerator.generateKeys(selectedStrings);
    
    _printInfo('Translating to ${config.languages.length} languages...');
    await translator.translateEntries(localizationEntries);
    
    if (!dryRun) {
      _printInfo('Generating ARB files...');
      await arbGenerator.generateArbFiles(localizationEntries);
      
      _printInfo('Updating source code...');
      await codeReplacer.replaceStringsInFiles(selectedStrings, localizationEntries);
    }
    
    _printSuccess('Extraction completed successfully!');
    _printInfo('Summary:');
    _printInfo('  - Files processed: ${filesToProcess.length}');
    _printInfo('  - Strings extracted: ${allExtractedStrings.length}');
    if (preview) {
      _printInfo('  - Strings processed: ${selectedStrings.length}');
    }
    _printInfo('  - Languages: ${config.languages.join(', ')}');
    
  } catch (e) {
    _printError('Extraction failed: $e');
    exit(1);
  }
}

Future<void> _updateCommand(String configPath, bool verbose) async {
  _printInfo('Update command not yet implemented');
}

Future<void> _validateCommand(String configPath, bool verbose) async {
  _printInfo('Validate command not yet implemented');
}

Future<void> _statsCommand(String configPath, bool verbose) async {
  _printInfo('Stats command not yet implemented');
}

Future<List<ExtractedString>> _showPreviewAndGetSelection(List<ExtractedString> extractedStrings) async {
  _printInfo('\n=== EXTRACTED STRINGS PREVIEW ===');
  _printInfo('Found ${extractedStrings.length} extractable strings:\n');
  
  // Group strings by file for better organization
  final stringsByFile = <String, List<ExtractedString>>{};
  for (final string in extractedStrings) {
    final fileName = string.filePath.split(Platform.pathSeparator).last;
    stringsByFile.putIfAbsent(fileName, () => []).add(string);
  }
  
  // Display strings with indices
  int index = 1;
  final indexToString = <int, ExtractedString>{};
  
  for (final entry in stringsByFile.entries) {
    print(Colorize('\n📁 ${entry.key}').bold());
    for (final string in entry.value) {
      indexToString[index] = string;
      final preview = string.value.length > 50 
          ? '${string.value.substring(0, 47)}...'
          : string.value;
      print('  ${index.toString().padLeft(3)}. "$preview"');
      print('  Line ${string.lineNumber}, Column ${string.columnNumber}');
      if (string.context != null) {
        print('       Context: ${string.context}');
      }
      index++;
    }
  }
  
  print('\n' + Colorize('Selection Options:').bold().toString());
  print('  • Enter specific numbers (e.g., "1,3,5-8,12")');
  print('  • Enter "all" to select all strings');
  print('  • Enter "none" or press Enter to skip all');
  print('  • Enter "q" to quit');
  
  while (true) {
    stdout.write('\nSelect strings to process: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    
    if (input.toLowerCase() == 'q') {
      exit(0);
    }
    
    if (input.isEmpty || input.toLowerCase() == 'none') {
      return [];
    }
    
    if (input.toLowerCase() == 'all') {
      _printSuccess('Selected all ${extractedStrings.length} strings for processing.');
      return extractedStrings;
    }
    
    try {
      final selectedIndices = _parseSelection(input, extractedStrings.length);
      final selectedStrings = selectedIndices
          .map((i) => indexToString[i]!)
          .toList();
      
      if (selectedStrings.isNotEmpty) {
        _printSuccess('Selected ${selectedStrings.length} strings for processing.');
        return selectedStrings;
      } else {
        _printWarning('No valid strings selected.');
      }
    } catch (e) {
      _printError('Invalid selection format. Please try again.');
      _printInfo('Examples: "1,3,5" or "1-5,8,10-12" or "all"');
    }
  }
}

Set<int> _parseSelection(String input, int maxIndex) {
  final indices = <int>{};
  final parts = input.split(',');
  
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.contains('-')) {
      final range = trimmed.split('-');
      if (range.length == 2) {
        final start = int.parse(range[0].trim());
        final end = int.parse(range[1].trim());
        if (start >= 1 && end <= maxIndex && start <= end) {
          for (int i = start; i <= end; i++) {
            indices.add(i);
          }
        } else {
          throw FormatException('Range out of bounds: $trimmed');
        }
      } else {
        throw FormatException('Invalid range format: $trimmed');
      }
    } else {
      final index = int.parse(trimmed);
      if (index >= 1 && index <= maxIndex) {
        indices.add(index);
      } else {
        throw FormatException('Index out of bounds: $index');
      }
    }
  }
  
  return indices;
}

void _printInfo(String message) {
  print(Colorize(message).blue());
}

void _printSuccess(String message) {
  print(Colorize(message).green());
}

void _printWarning(String message) {
  print(Colorize(message).yellow());
}

void _printError(String message) {
  print(Colorize(message).red());
}