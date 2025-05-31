# Flutter AI i18n Extractor

An intelligent Flutter package that automatically extracts hardcoded strings from your Flutter project and generates professional translations using AI, with full compatibility with `flutter_intl` and `intl_utils` workflows.

## Features

- **Professional Translation**: Leverage AI models and translation services for high-quality translations
- **Multiple Translation Options**: Choose from free translation services or premium AI models
- **Compatibility with `flutter_intl`**: Seamlessly integrates with existing `flutter_intl` projects
- **Smart Key Generation**: Automatically generates meaningful keys for your translations
- **Batch Processing**: Extract and translate multiple strings efficiently
- **Customizable**: Configure translation providers, target languages, and extraction patterns
- **CLI Support**: Easy-to-use command-line interface

### Translation Providers

| Translation Module | Support | FREE |
|-------------------|---------|------|
| Google Translate | ✅ | ✅ FREE |
| Google Translate 2 | ✅ | ✅ FREE |
| Microsoft Bing Translate | ✅ | ✅ FREE |
| Libre Translate | ✅ | ✅ FREE |
| Argos Translate | ✅ | ✅ FREE |
| DeepL Translate | ✅ | require API KEY (DEEPL_API_KEY as env)<br/>optional API URL (DEEPL_API_URL as env) |
| gpt-4o | ✅ | require API KEY (OPENAI_API_KEY as env) |
| gpt-3.5-turbo | ✅ | require API KEY (OPENAI_API_KEY as env) |
| gpt-4 | ✅ | require API KEY (OPENAI_API_KEY as env) |
| gpt-4o-mini | ✅ | require API KEY (OPENAI_API_KEY as env) |
| Claude 3.5 Sonnet | ✅ | require API KEY (ANTHROPIC_API_KEY as env) |
| Gemini Pro | ✅ | require API KEY (GOOGLE_AI_API_KEY as env) |
| DeepSeek | ✅ | require API KEY (DEEPSEEK_API_KEY as env) |
| Groq | ✅ | require API KEY (GROQ_API_KEY as env) |
| Cohere | ✅ | require API KEY (COHERE_API_KEY as env) |
| Hugging Face | ✅ | require API KEY (HUGGINGFACE_API_KEY as env) |
| Ollama | ✅ | require local installation |

## Compatibility with flutter_intl

**Yes, this package is fully compatible with `flutter_intl` and `intl_utils` workflows!** 

If you already have `flutter_intl` configured in your `pubspec.yaml`:

```yaml
# Configuration for intl_utils
flutter_intl:
  enabled: true
  class_name: S
  main_locale: en
  arb_dir: lib/l10n
  output_dir: lib/generated
  localizely:
    project_id: # Add your Localizely project ID if using it
```

The extractor will:
- Detect your existing configuration automatically
- Use your configured `class_name` (e.g., `S`)
- Generate ARB files in your specified `arb_dir`
- Generate code that works with your existing setup: `final l10n = S.of(context);`

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_ai_i18n_extractor: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize Configuration

```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor init
```

This creates a `flutter_ai_i18n_extractor.yaml` configuration file:

```yaml
flutter_ai_i18n_extractor:
  # L10n Settings (auto-detected from flutter_intl if present)
  arb_dir: lib/l10n
  template_arb_file: app_en.arb
  output_class: AppLocalizations  # or 'S' if using flutter_intl
  
  # AI Configuration
  ai_provider: google_translate # Default: google_translate (free). Choose from:
  # Free Translation Services: google_translate, google_translate_2, bing_translate, libre_translate, argos_translate
  # Translation with API Key: deepl_translate
  # AI Models with API Key: openai, google, anthropic, deepseek, groq, cohere, huggingface, ollama
  api_key: ${OPENAI_API_KEY}  # Use environment variables
  model: gpt-4
  
  # Target Languages
  languages:
    - en
    - es
    - fr
    - de
  
  # Extraction Settings
  scan_paths:
    - lib/
  exclude_patterns:
    - lib/generated/
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
  # Key Generation
  key_naming_convention: camelCase  # or snake_case
  max_key_length: 35
  context_aware_naming: true
  
  # Processing Options
  dry_run: false
  backup_files: true
  preserve_comments: true
```

### 2. Set Up API Key

Set up your API keys as environment variables (only required for paid services):

```bash
# Free Translation Services (No API Key Required)
# - google_translate
# - google_translate_2  
# - bing_translate
# - libre_translate
# - argos_translate

# Translation Services (API Key Required)
# For DeepL Translate
export DEEPL_API_KEY="your-deepl-api-key"
export DEEPL_API_URL="https://api-free.deepl.com"  # Optional, defaults to free tier

# AI Models (API Key Required)
# For OpenAI
export OPENAI_API_KEY="your-api-key-here"

# For Google AI
export GOOGLE_AI_API_KEY="your-api-key-here"

# For Anthropic
export ANTHROPIC_API_KEY="your-api-key-here"

# For DeepSeek (Free tier available)
export DEEPSEEK_API_KEY="your-api-key-here"

# For Groq (Free tier available)
export GROQ_API_KEY="your-api-key-here"

# For Cohere (Free tier available)
export COHERE_API_KEY="your-api-key-here"

# For Hugging Face (Free tier available)
export HUGGINGFACE_API_KEY="your-api-key-here"

# For Ollama (Local - no API key needed)
export OLLAMA_BASE_URL="http://localhost:11434"  # Optional, defaults to localhost

# Optional: Custom URLs for self-hosted services
export LIBRETRANSLATE_URL="https://libretranslate.de"  # Default LibreTranslate instance
export ARGOS_TRANSLATE_URL="http://localhost:5000"     # Local Argos Translate instance
```

### 3. Extract and Translate

```bash
# Extract strings and generate translations
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor extract

# Preview extracted strings and select which ones to process
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor extract --preview

# Or run in dry-run mode first to see what would be extracted
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor extract --dry-run
```

## Usage Examples

### Before Extraction

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter your email',
              labelText: 'Email',
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter your password',
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
```

### After Extraction (flutter_intl compatible)

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);  // Uses your configured class_name
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginPageTitle),
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: l10n.emailFieldHint,
              labelText: l10n.emailFieldLabel,
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: l10n.passwordFieldHint,
              labelText: l10n.passwordFieldLabel,
            ),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.signInButtonText),
          ),
        ],
      ),
    );
  }
}
```

### Generated ARB Files

**lib/l10n/app_en.arb**:
```json
{
  "@@locale": "en",
  "loginPageTitle": "Login",
  "@loginPageTitle": {
    "description": "Title for the login page"
  },
  "emailFieldHint": "Enter your email",
  "@emailFieldHint": {
    "description": "Hint text for email input field"
  },
  "emailFieldLabel": "Email",
  "@emailFieldLabel": {
    "description": "Label for email input field"
  },
  "passwordFieldHint": "Enter your password",
  "@passwordFieldHint": {
    "description": "Hint text for password input field"
  },
  "passwordFieldLabel": "Password",
  "@passwordFieldLabel": {
    "description": "Label for password input field"
  },
  "signInButtonText": "Sign In",
  "@signInButtonText": {
    "description": "Text for sign in button"
  }
}
```

**lib/l10n/app_es.arb**:
```json
{
  "@@locale": "es",
  "loginPageTitle": "Iniciar Sesión",
  "emailFieldHint": "Ingresa tu correo electrónico",
  "emailFieldLabel": "Correo Electrónico",
  "passwordFieldHint": "Ingresa tu contraseña",
  "passwordFieldLabel": "Contraseña",
  "signInButtonText": "Iniciar Sesión"
}
```

## CLI Commands

### Initialize
```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor init
```
Creates a configuration file with sensible defaults.

### Extract
```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor extract [options]
```

Options:
- `--preview, -p`: Show extracted strings and allow selection before processing
- `--dry-run`: Preview changes without modifying files
- `--config`: Specify custom config file path
- `--languages`: Override target languages (comma-separated)

### Update
```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor update
```
Updates existing translations with new strings.

### Validate
```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor validate
```
Validates ARB files and checks for missing translations.

### Stats
```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor stats
```
Shows statistics about your localization coverage.

## Configuration Options

### Translation Providers

#### Free Translation Services (No API Key Required)

##### Google Translate (Default)
```yaml
ai_provider: google_translate
# No API key required - completely free
```

##### Google Translate 2 (Alternative Endpoint)
```yaml
ai_provider: google_translate_2
# No API key required - completely free
```

##### Microsoft Bing Translate
```yaml
ai_provider: bing_translate
# No API key required - completely free
```

##### LibreTranslate
```yaml
ai_provider: libre_translate
# No API key required - uses public instance
# Optional: Set LIBRETRANSLATE_URL for custom instance
```

##### Argos Translate
```yaml
ai_provider: argos_translate
# No API key required - requires local installation
# Optional: Set ARGOS_TRANSLATE_URL for custom instance
```

#### Translation Services (API Key Required)

##### DeepL Translate
```yaml
ai_provider: deepl_translate
api_key: ${DEEPL_API_KEY}
# Optional: Set DEEPL_API_URL for custom endpoint
```

#### AI Models (API Key Required)

##### OpenAI
```yaml
ai_provider: openai
api_key: ${OPENAI_API_KEY}
model: gpt-4o  # or gpt-4, gpt-3.5-turbo, gpt-4o-mini
```

##### Google AI
```yaml
ai_provider: google
api_key: ${GOOGLE_AI_API_KEY}
model: gemini-1.5-pro  # or gemini-1.5-flash
```

##### Anthropic
```yaml
ai_provider: anthropic
api_key: ${ANTHROPIC_API_KEY}
model: claude-3-5-sonnet-20241022  # or claude-3-haiku-20240307
```

##### DeepSeek
```yaml
ai_provider: deepseek
api_key: ${DEEPSEEK_API_KEY}
model: deepseek-chat  # or deepseek-coder
```

##### Groq
```yaml
ai_provider: groq
api_key: ${GROQ_API_KEY}
model: llama-3.1-70b-versatile  # or mixtral-8x7b-32768
```

##### Cohere
```yaml
ai_provider: cohere
api_key: ${COHERE_API_KEY}
model: command-r-plus  # or command-r
```

##### Hugging Face
```yaml
ai_provider: huggingface
api_key: ${HUGGINGFACE_API_KEY}
model: microsoft/DialoGPT-large  # or any compatible model
```

##### Ollama
```yaml
ai_provider: ollama
model: llama3.1  # or any locally installed model
```

> **Note**: Ollama requires local installation. Download models using `ollama pull <model-name>`.

### Key Naming Conventions

#### camelCase (default)
```yaml
key_naming_convention: camelCase
```
Generates keys like: `loginPageTitle`, `emailFieldHint`

#### snake_case
```yaml
key_naming_convention: snake_case
```
Generates keys like: `login_page_title`, `email_field_hint`

### Exclusion Patterns

```yaml
exclude_patterns:
  - lib/generated/
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "**/test/**"
  - "lib/l10n/"
```

## Integration with Existing Projects

### flutter_intl Integration

If you're already using `flutter_intl`, the extractor will:

1. **Auto-detect your configuration** from `pubspec.yaml`
2. **Use your existing class name** (e.g., `S` instead of `AppLocalizations`)
3. **Generate compatible ARB files** in your configured directory
4. **Preserve your existing translations** when updating

### Manual Integration

For projects without `flutter_intl`, add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

Create `l10n.yaml`:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

## Best Practices

### 1. Use Dry Run First
```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor extract --dry-run
```

### 2. Review Generated Keys
The AI generates meaningful keys, but review them for consistency with your naming conventions.

### 3. Backup Your Files
The tool creates backups by default, but consider using version control.

### 4. Incremental Updates
Use the `update` command to add new strings without affecting existing translations.

### 5. Context-Aware Naming
Enable `context_aware_naming` for better key generation based on UI context.

## Troubleshooting

### Common Issues

#### API Key Not Found
```
Error: AI API key is not properly configured
```
**Solution**: Set the environment variable for your AI provider.

#### No Strings Found
```
Warning: No extractable strings found
```
**Solution**: Check your `scan_paths` and `exclude_patterns` configuration.

#### Compilation Errors After Extraction
```
Error: The getter 'someKey' isn't defined
```
**Solution**: Run `flutter packages pub run build_runner build` to generate localization files.

### Debug Mode

Run with verbose output:
```bash
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor extract --verbose
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions:

1. Check the [troubleshooting section](#troubleshooting)
2. Search [existing issues](https://github.com/IdreesAbuEtewy/flutter_ai_i18n_extractor/issues)
3. Create a [new issue](https://github.com/IdreesAbuEtewy/flutter_ai_i18n_extractor/issues/new) with detailed information

## Roadmap

- [ ] Support for more AI providers
- [ ] Integration with translation services (Google Translate, DeepL)
- [ ] VS Code extension
- [ ] Pluralization support
- [ ] Custom translation templates
- [ ] Translation quality scoring