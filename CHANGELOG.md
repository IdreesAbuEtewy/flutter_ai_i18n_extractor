# Changelog


## [1.0.1] - 2024-12-19

### Fixed
- **DeepSeek API**: Fixed "Model Not Exist" error by updating default model from `deepseek-chat` to `deepseek-r1`
- **DateFormat Localization**: Added exclusion patterns for `DateFormat` strings (e.g., 'MMM', 'yyyy', 'dd/MM/yyyy') to prevent incorrect localization attempts

### Added
- **Preview Feature**: New `--preview` (`-p`) flag allows users to review and select which extracted strings to process before applying translations
  - Interactive string selection with file grouping
  - Support for range selection (e.g., "1,3,5-8,12")
  - Options to select all, none, or specific strings
  - Prevents processing errors by allowing manual filtering

### Improved
- **Error Prevention**: Enhanced validation to avoid processing technical identifiers and date format patterns
- **User Experience**: Better control over which strings get localized through the preview feature
- **Documentation**: Updated README with preview feature usage examples

## [1.0.0] - 2024-12-19

### Added
- **Free Translation Services (No API Key Required)**:
  - Google Translate - Free web-based translation service
  - Google Translate 2 - Alternative Google Translate endpoint
  - Microsoft Bing Translate - Free Microsoft translation service
  - LibreTranslate - Open-source translation service (supports custom URLs)
  - Argos Translate - Open-source offline translation (supports custom URLs)

- **Translation Services (API Key Required)**:
  - DeepL Translate - Professional translation service with API key

- **AI Models (API Key Required)** - All existing AI providers:
  - OpenAI (GPT-4, GPT-3.5-turbo, etc.)
  - Anthropic (Claude models)
  - Google AI (Gemini models)
  - DeepSeek (DeepSeek Chat, DeepSeek Coder)
  - Groq (Llama, Mixtral models)
  - Cohere (Command models)
  - Hugging Face (Various models)
  - Ollama (Local AI models)

### Changed
- **Default Provider**: Changed from OpenAI to Google Translate for immediate usability
- **AI Providers**: Now optional - users can start with free translation services
- **Documentation**: Reorganized to clearly distinguish between free and paid services
- **Configuration**: Updated examples to showcase free translation options first
