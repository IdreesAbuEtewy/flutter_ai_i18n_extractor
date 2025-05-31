/// Flutter AI i18n Extractor
/// 
/// Automatically detect, extract, and intelligently translate hardcoded text 
/// in Flutter projects using AI-powered abbreviation generation and 
/// professional translations, fully compatible with Flutter's intl utils system.
library flutter_ai_i18n_extractor;

// Core exports
export 'src/core/extractor_config.dart';
export 'src/core/extracted_string.dart';
export 'src/core/localization_entry.dart';

// Scanner exports
export 'src/scanners/dart_file_scanner.dart';
export 'src/scanners/string_parser.dart';
export 'src/scanners/context_analyzer.dart';

// AI exports
export 'src/ai/ai_client.dart';
export 'src/ai/abbreviation_generator.dart';
export 'src/ai/professional_translator.dart';

// Generator exports
export 'src/generators/arb_file_generator.dart';
export 'src/generators/code_replacer.dart';
export 'src/generators/import_manager.dart';

// Utility exports
export 'src/utils/file_utils.dart';
export 'src/utils/string_utils.dart';
export 'src/utils/validation_utils.dart';