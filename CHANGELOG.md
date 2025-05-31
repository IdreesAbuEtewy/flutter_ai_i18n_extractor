# Changelog


## [1.0.0] - 2025-5-31

### Added
- 🔍 **Smart String Detection**: AST-based parsing to find hardcoded strings in Dart files
- 🤖 **AI-Powered Key Generation**: Intelligent localization key generation using OpenAI, Google AI, or Anthropic
- 🌍 **Professional Translation**: High-quality translations with context awareness
- 📝 **ARB File Generation**: Creates and updates ARB files compatible with Flutter's localization system
- 🔄 **Code Replacement**: Automatically replaces hardcoded strings with localization calls
- 🎯 **Context-Aware Analysis**: Analyzes UI context for better key naming and translations
- ✅ **flutter_intl Compatibility**: Full compatibility with existing `flutter_intl` and `intl_utils` workflows
- 🛠️ **CLI Interface**: Command-line tool for easy integration into development workflows
- 📋 **Configuration Management**: YAML-based configuration with environment variable support
- 🔧 **Multiple AI Providers**: Support for OpenAI, Google AI, and Anthropic APIs
- 🌐 **Multi-language Support**: Generate translations for multiple target languages simultaneously
- 🎨 **Context Types**: Intelligent detection of UI element types (button, title, message, error, etc.)
- 📊 **Statistics and Reporting**: Detailed statistics about extraction and translation processes
- 🔒 **Backup System**: Automatic backup of original files before modifications
- 🎛️ **Dry Run Mode**: Preview changes before applying them
- 📁 **Pattern Matching**: Flexible file inclusion/exclusion patterns
- 🔑 **Key Naming Conventions**: Support for camelCase and snake_case naming conventions
- 📖 **Comprehensive Documentation**: Detailed README with examples and best practices

## [1.0.1] - 2025-5-31

### Added
- **Free Translation Services** (No API Key Required):
  - Google Translate (now default provider)
  - Google Translate 2 (alternative endpoint)
  - Microsoft Bing Translate
  - LibreTranslate (with custom URL support)
  - Argos Translate (local installation)
- **Translation Services** (API Key Required):
  - DeepL Translate with optional custom API URL
- **AI Models** (API Key Required):
  - DeepSeek AI models with free tier availability
  - Groq AI models with fast inference and free tier
  - Cohere AI models with free tier availability
  - Hugging Face AI models with free tier access
  - Ollama local AI models (no API key required)
- Environment variable support for all providers:
  - `DEEPL_API_KEY` and `DEEPL_API_URL` for DeepL Translate
  - `LIBRETRANSLATE_URL` for custom LibreTranslate instances
  - `ARGOS_TRANSLATE_URL` for custom Argos Translate instances
  - `DEEPSEEK_API_KEY` for DeepSeek
  - `GROQ_API_KEY` for Groq
  - `COHERE_API_KEY` for Cohere
  - `HUGGINGFACE_API_KEY` for Hugging Face
- Comprehensive translation provider comparison table in README
- Updated documentation with configuration examples for all providers

### Changed
- **Default provider changed from OpenAI to Google Translate** (free service)
- AI providers are now optional - free translation services available by default
- Reorganized documentation to clearly distinguish between free and paid services

### Fixed
- Fixed `displayName` getter issue in `ExtractedString` class
- Resolved compilation errors and warnings
- Fixed unnecessary null comparisons in `ai_client.dart`
- Corrected import statements and dependencies
- Fixed `assignment_to_final` errors by using `copyWith` method for context assignments

### Improved
- Enhanced provider factory pattern to support translation services and AI models
- Updated README.md with comprehensive provider comparison and usage examples
- Extended validation logic to support all new translation providers
- Improved error handling for unsupported providers
- Better categorization of services by cost and requirements
- Enhanced error handling and validation
- Better code organization and structure
- Improved performance and reliability
- Expanded AI provider ecosystem with free and local options
