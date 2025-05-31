# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

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

### Features
- **String Context Analysis**: Determines context type based on widget type and parameter names
- **Screen Context Detection**: Infers screen/page context from file names and structure
- **Professional Translation Engine**: Groups related strings for consistent translations
- **ARB File Management**: Create, update, and cleanup ARB files with metadata
- **Code Replacement Engine**: Safe replacement of hardcoded strings with localization calls
- **Abbreviation Generation**: AI-powered generation of meaningful localization keys
- **Validation System**: Comprehensive validation of ARB files and translations
- **Import Management**: Automatic management of import statements
- **File Scanning**: Recursive scanning of Dart files with pattern matching
- **Configuration Auto-detection**: Automatic detection of existing flutter_intl configuration

### Technical Implementation
- Built with Dart analyzer for robust AST parsing
- HTTP client for AI API integration
- YAML configuration parsing
- Path utilities for cross-platform file handling
- Glob pattern matching for file selection
- Colorized CLI output for better user experience
- Comprehensive error handling and logging

### Supported AI Providers
- **OpenAI**: GPT-4, GPT-4 Turbo, GPT-3.5 Turbo
- **Google AI**: Gemini Pro, Gemini Pro Vision
- **Anthropic**: Claude 3 Opus, Claude 3 Sonnet, Claude 3 Haiku

### Configuration Options
- Customizable ARB directory and template file
- Configurable output class name
- Multiple target languages
- Scan path configuration
- File exclusion patterns
- Key naming conventions
- Maximum key length limits
- Context-aware naming toggle
- Processing options (dry run, backups, comments)
- AI provider and model selection
- API key management with environment variables

### CLI Commands
- `init`: Initialize configuration file
- `extract`: Extract strings and generate translations
- `--dry-run`: Preview mode without making changes
- `--config`: Specify custom configuration file
- `--verbose`: Enable detailed logging

### Compatibility
- Flutter 3.0.0+
- Dart SDK 3.0.0+
- Compatible with existing flutter_intl setups
- Works with intl_utils workflows
- Supports existing ARB file structures

### Documentation
- Comprehensive README with setup instructions
- Usage examples and best practices
- Configuration reference
- API integration guides
- Troubleshooting section
- Migration guide for existing projects

---

## [Unreleased]

### Fixed
- Fixed `displayName` getter issue for `StringContextType` enum
- Resolved compilation errors in ARB file generator
- Fixed unnecessary null comparisons in AI client
- Corrected import statements for proper extension access

### Improved
- Enhanced error handling and user feedback
- Better code organization and documentation
- Optimized performance for large codebases

---

*For more details about each release, see the [GitHub releases page](https://github.com/your-username/flutter_ai_i18n_extractor/releases).*