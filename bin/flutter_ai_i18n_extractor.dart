#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:colorize/colorize.dart';
import 'package:flutter_ai_i18n_extractor/flutter_ai_i18n_extractor.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show usage information')
    ..addFlag('dry-run', help: 'Preview changes without modifying files')
    ..addFlag('verbose', abbr: 'v', help: 'Show detailed output')
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
    final files = results['files'] as String?;

    switch (command) {
      case 'init':
        await _initCommand(configPath, verbose);
        break;
      case 'extract':
        await _extractCommand(configPath, dryRun, verbose, files);
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

Future<void> _extractCommand(String configPath, bool dryRun, bool verbose, String? files) async {
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
    for (final extractedString in allExtractedStrings) {
      extractedString.context = await contextAnalyzer.analyzeContext(extractedString);
    }
    
    _printInfo('Generating intelligent keys...');
    final localizationEntries = await abbreviationGenerator.generateKeys(allExtractedStrings);
    
    _printInfo('Translating to ${config.languages.length} languages...');
    await translator.translateEntries(localizationEntries);
    
    if (!dryRun) {
      _printInfo('Generating ARB files...');
      await arbGenerator.generateArbFiles(localizationEntries);
      
      _printInfo('Updating source code...');
      await codeReplacer.replaceStringsInFiles(allExtractedStrings, localizationEntries);
    }
    
    _printSuccess('Extraction completed successfully!');
    _printInfo('Summary:');
    _printInfo('  - Files processed: ${filesToProcess.length}');
    _printInfo('  - Strings extracted: ${allExtractedStrings.length}');
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