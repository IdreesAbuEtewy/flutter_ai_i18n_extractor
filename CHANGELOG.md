# Changelog


## [Unreleased]

### Added
- Support for DeepSeek AI provider with free tier availability
- Support for Groq AI provider with fast inference and free tier
- Support for Cohere AI provider with free tier availability
- Support for Hugging Face AI provider with free tier availability
- Support for Ollama local AI models (no API key required)
- Environment variable support for all new AI providers
- Updated documentation with configuration examples for all providers

### Fixed
- Fixed `displayName` getter issue in `ExtractedString` class
- Resolved compilation errors and warnings
- Fixed unnecessary null comparisons in `ai_client.dart`
- Corrected import statements and dependencies
- Fixed `assignment_to_final` errors by using `copyWith` method for context assignments

### Improved
- Enhanced error handling and validation
- Better code organization and structure
- Improved performance and reliability
- Expanded AI provider ecosystem with free and local options

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


