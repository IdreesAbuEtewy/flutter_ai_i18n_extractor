import 'dart:io';
import 'package:yaml/yaml.dart';

/// L10n configuration settings
class L10nConfig {
  final String arbDir;
  final String templateArbFile;
  final String outputClass;
  
  const L10nConfig({
    required this.arbDir,
    required this.templateArbFile,
    required this.outputClass,
  });
}

/// Processing configuration settings
class ProcessingConfig {
  final bool dryRun;
  final bool createBackups;
  final bool preserveComments;
  final bool includeSourceInfo;
  
  const ProcessingConfig({
    required this.dryRun,
    required this.createBackups,
    required this.preserveComments,
    required this.includeSourceInfo,
  });
 }

/// Configuration class for the Flutter AI i18n Extractor
class ExtractorConfig {
  // L10n Settings
  final String arbDir;
  final String templateArbFile;
  final String outputClass;
  
  // AI Configuration
  final String aiProvider;
  final String apiKey;
  final String model;
  
  // Target Languages
  final List<String> languages;
  
  // Extraction Settings
  final List<String> scanPaths;
  final List<String> excludePatterns;
  
  // Key Generation Settings
  final String keyNamingConvention;
  final int maxKeyLength;
  final bool contextAwareNaming;
  
  // Processing Options
  final bool dryRun;
  final bool backupFiles;
  final bool preserveComments;
  final bool includeSourceInfo;
  
  // Convenience getters for grouped settings
  L10nConfig get l10n => L10nConfig(
    arbDir: arbDir,
    templateArbFile: templateArbFile,
    outputClass: outputClass,
  );
  
  ProcessingConfig get processing => ProcessingConfig(
    dryRun: dryRun,
    createBackups: backupFiles,
    preserveComments: preserveComments,
    includeSourceInfo: includeSourceInfo,
  );

  const ExtractorConfig({
    required this.arbDir,
    required this.templateArbFile,
    required this.outputClass,
    required this.aiProvider,
    required this.apiKey,
    required this.model,
    required this.languages,
    required this.scanPaths,
    required this.excludePatterns,
    required this.keyNamingConvention,
    required this.maxKeyLength,
    required this.contextAwareNaming,
    required this.dryRun,
    required this.backupFiles,
    required this.preserveComments,
    required this.includeSourceInfo,
  });

  /// Creates a default configuration
  factory ExtractorConfig.defaultConfig() {
    return const ExtractorConfig(
      arbDir: 'lib/l10n',
      templateArbFile: 'intl_en.arb',
      outputClass: 'AppLocalizations',
      aiProvider: 'openai',
      apiKey: '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', // Default free API key
      model: 'gpt-4o-mini',
      languages: ['ar', 'es', 'fr', 'de', 'zh'],
      scanPaths: ['lib/'],
      excludePatterns: [
        '**/*.g.dart',
        '**/*.freezed.dart',
        '**/generated/**',
      ],
      keyNamingConvention: 'camelCase',
      maxKeyLength: 35,
      contextAwareNaming: true,
      dryRun: false,
      backupFiles: true,
      preserveComments: true,
      includeSourceInfo: true,
    );
  }

  /// Loads configuration from a YAML file
  static Future<ExtractorConfig> fromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Configuration file not found: $filePath');
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as Map;
    final config = yaml['flutter_ai_i18n_extractor'] as Map;

    return ExtractorConfig(
      arbDir: config['arb_dir'] as String? ?? 'lib/l10n',
      templateArbFile: config['template_arb_file'] as String? ?? 'intl_en.arb',
      outputClass: config['output_class'] as String? ?? 'AppLocalizations',
      aiProvider: config['ai_provider'] as String? ?? 'openai',
      apiKey: _resolveEnvironmentVariable(config['api_key'] as String? ?? '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'),
      model: config['model'] as String? ?? 'gpt-4o-mini',
      languages: (config['languages'] as List?)?.cast<String>() ?? ['ar', 'es', 'fr', 'de', 'zh'],
      scanPaths: (config['scan_paths'] as List?)?.cast<String>() ?? ['lib/'],
      excludePatterns: (config['exclude_patterns'] as List?)?.cast<String>() ?? [
        '**/*.g.dart',
        '**/*.freezed.dart',
        '**/generated/**',
      ],
      keyNamingConvention: config['key_naming_convention'] as String? ?? 'camelCase',
      maxKeyLength: config['max_key_length'] as int? ?? 35,
      contextAwareNaming: config['context_aware_naming'] as bool? ?? true,
      dryRun: config['dry_run'] as bool? ?? false,
      backupFiles: config['backup_files'] as bool? ?? true,
      preserveComments: config['preserve_comments'] as bool? ?? true,
      includeSourceInfo: config['include_source_info'] as bool? ?? true,
    );
  }

  /// Converts the configuration to a Map for YAML serialization
  Map<String, dynamic> toMap() {
    return {
      'flutter_ai_i18n_extractor': {
        'arb_dir': arbDir,
        'template_arb_file': templateArbFile,
        'output_class': outputClass,
        'ai_provider': aiProvider,
        'api_key': apiKey,
        'model': model,
        'languages': languages,
        'scan_paths': scanPaths,
        'exclude_patterns': excludePatterns,
        'key_naming_convention': keyNamingConvention,
        'max_key_length': maxKeyLength,
        'context_aware_naming': contextAwareNaming,
        'dry_run': dryRun,
        'backup_files': backupFiles,
        'preserve_comments': preserveComments,
        'include_source_info': includeSourceInfo,
      },
    };
  }

  /// Resolves environment variables in configuration values
  static String _resolveEnvironmentVariable(String value) {
    final envVarPattern = RegExp(r'\$\{([^}]+)\}');
    return value.replaceAllMapped(envVarPattern, (match) {
      final envVarName = match.group(1)!;
      final envValue = Platform.environment[envVarName];
      if (envValue == null) {
        throw Exception('Environment variable not found: $envVarName');
      }
      return envValue;
    });
  }

  /// Validates the configuration
  void validate() {
    if (apiKey.isEmpty || apiKey.contains(r'${')) {
      throw Exception('AI API key is not properly configured. Please set the environment variable or update the configuration.');
    }

    if (languages.isEmpty) {
      throw Exception('At least one target language must be specified.');
    }

    if (scanPaths.isEmpty) {
      throw Exception('At least one scan path must be specified.');
    }

    if (!['camelCase', 'snake_case'].contains(keyNamingConvention)) {
      throw Exception('Invalid key naming convention. Must be either "camelCase" or "snake_case".');
    }

    if (!['openai', 'google', 'anthropic'].contains(aiProvider)) {
      throw Exception('Unsupported AI provider: $aiProvider. Supported providers: openai, google, anthropic.');
    }
  }

  @override
  String toString() {
    return 'ExtractorConfig(arbDir: $arbDir, languages: $languages, aiProvider: $aiProvider)';
  }
}