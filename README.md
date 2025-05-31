# Flutter AI i18n Extractor

An intelligent Flutter package that automatically extracts hardcoded strings from your Flutter project and generates professional translations using AI, with full compatibility with `flutter_intl` and `intl_utils` workflows.

## Features

- 🔍 **Smart String Detection**: Uses AST parsing to find hardcoded strings in Dart files
- 🤖 **AI-Powered Key Generation**: Generates meaningful localization keys using AI
- 🌍 **Professional Translation**: High-quality translations using OpenAI, Google AI, or Anthropic
- 📝 **ARB File Generation**: Creates and updates ARB files compatible with Flutter's localization
- 🔄 **Code Replacement**: Automatically replaces hardcoded strings with localization calls
- 🎯 **Context-Aware**: Analyzes UI context for better key naming and translations
- ✅ **flutter_intl Compatible**: Works seamlessly with existing `flutter_intl` and `intl_utils` setups

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
  ai_provider: openai  # openai, google, or anthropic
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

Set your AI provider API key as an environment variable:

```bash
# For OpenAI
export OPENAI_API_KEY="your-api-key-here"

# For Google AI
export GOOGLE_AI_API_KEY="your-api-key-here"

# For Anthropic
export ANTHROPIC_API_KEY="your-api-key-here"
```

### 3. Extract and Translate

```bash
# Extract strings and generate translations
flutter packages pub run flutter_ai_i18n_extractor:flutter_ai_i18n_extractor extract

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

### AI Providers

#### OpenAI
```yaml
ai_provider: openai
api_key: ${OPENAI_API_KEY}
model: gpt-4  # or gpt-3.5-turbo
```

#### Google AI
```yaml
ai_provider: google
api_key: ${GOOGLE_AI_API_KEY}
model: gemini-pro
```

#### Anthropic
```yaml
ai_provider: anthropic
api_key: ${ANTHROPIC_API_KEY}
model: claude-3-sonnet-20240229
```

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