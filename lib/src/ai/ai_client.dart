import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/extractor_config.dart';

/// Abstract base class for AI clients
abstract class AiClient {
  final ExtractorConfig config;
  
  const AiClient(this.config);
  
  /// Factory method to create appropriate AI client based on provider
  factory AiClient.create(ExtractorConfig config) {
    // Create a new config with API key from environment if not provided
    final effectiveConfig = _getConfigWithApiKey(config);
    
    switch (effectiveConfig.aiProvider.toLowerCase()) {
      case 'openai':
        return OpenAiClient(effectiveConfig);
      case 'google':
        return GoogleAiClient(effectiveConfig);
      case 'anthropic':
        return AnthropicAiClient(effectiveConfig);
      default:
        throw UnsupportedError('Unsupported AI provider: ${effectiveConfig.aiProvider}');
    }
  }
  
  /// Gets config with API key from environment variables if not provided
  static ExtractorConfig _getConfigWithApiKey(ExtractorConfig config) {
    String? apiKey = config.apiKey;
    
    // If API key is not provided or is a placeholder, try to get from environment
    if (apiKey.isEmpty || apiKey.startsWith(r'${')) {
      switch (config.aiProvider.toLowerCase()) {
        case 'openai':
          apiKey = Platform.environment['OPENAI_API_KEY'];
          break;
        case 'google':
          apiKey = Platform.environment['GOOGLE_AI_API_KEY'];
          break;
        case 'anthropic':
          apiKey = Platform.environment['ANTHROPIC_API_KEY'];
          break;
      }
    }
    
    // Use default free API key if none provided
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = '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';
    }
    
    // Return a new config with the resolved API key
    return ExtractorConfig(
      arbDir: config.arbDir,
      templateArbFile: config.templateArbFile,
      outputClass: config.outputClass,
      aiProvider: config.aiProvider,
      apiKey: apiKey,
      model: config.model,
      languages: config.languages,
      scanPaths: config.scanPaths,
      excludePatterns: config.excludePatterns,
      keyNamingConvention: config.keyNamingConvention,
      maxKeyLength: config.maxKeyLength,
      contextAwareNaming: config.contextAwareNaming,
      dryRun: config.dryRun,
      backupFiles: config.backupFiles,
      preserveComments: config.preserveComments,
      includeSourceInfo: config.includeSourceInfo,
    );
  }
  
  /// Sends a prompt to the AI and returns the response
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options});
  
  /// Sends a batch of prompts for efficient processing
  Future<List<String>> sendBatchPrompts(List<String> prompts, {Map<String, dynamic>? options}) async {
    final responses = <String>[];
    for (final prompt in prompts) {
      final response = await sendPrompt(prompt, options: options);
      responses.add(response);
      
      // Add small delay to respect rate limits
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return responses;
  }
  
  /// Validates the API configuration
  Future<bool> validateConfiguration() async {
    try {
      final testPrompt = 'Hello, this is a test. Please respond with "OK".';
      final response = await sendPrompt(testPrompt);
      return response.toLowerCase().contains('ok');
    } catch (e) {
      return false;
    }
  }
}

/// OpenAI client implementation
class OpenAiClient extends AiClient {
  static const String _baseUrl = 'https://api.openai.com/v1';
  
  const OpenAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final url = Uri.parse('$_baseUrl/chat/completions');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
    
    final body = {
      'model': config.model,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'max_tokens': options?['max_tokens'] ?? 1000,
      'temperature': options?['temperature'] ?? 0.3,
    };
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String;
        }
      }
      
      throw AiClientException(
        'OpenAI API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with OpenAI: $e');
    }
  }
}

/// Google AI client implementation
class GoogleAiClient extends AiClient {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  const GoogleAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final modelName = config.model.startsWith('gemini') ? config.model : 'gemini-pro';
    final url = Uri.parse('$_baseUrl/models/$modelName:generateContent?key=${config.apiKey}');
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': options?['temperature'] ?? 0.3,
        'maxOutputTokens': options?['max_tokens'] ?? 1000,
      },
    };
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>;
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
      }
      
      throw AiClientException(
        'Google AI API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Google AI: $e');
    }
  }
}

/// Anthropic client implementation
class AnthropicAiClient extends AiClient {
  static const String _baseUrl = 'https://api.anthropic.com/v1';
  
  const AnthropicAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final url = Uri.parse('$_baseUrl/messages');
    
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
    };
    
    final body = {
      'model': config.model.startsWith('claude') ? config.model : 'claude-3-sonnet-20240229',
      'max_tokens': options?['max_tokens'] ?? 1000,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    };
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List;
        if (content.isNotEmpty) {
          return content[0]['text'] as String;
        }
      }
      
      throw AiClientException(
        'Anthropic API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Anthropic: $e');
    }
  }
}

/// Exception thrown by AI clients
class AiClientException implements Exception {
  final String message;
  
  const AiClientException(this.message);
  
  @override
  String toString() => 'AiClientException: $message';
}

/// Rate limiter for AI API calls
class RateLimiter {
  final int maxRequestsPerMinute;
  final List<DateTime> _requestTimes = [];
  
  RateLimiter({this.maxRequestsPerMinute = 60});
  
  /// Waits if necessary to respect rate limits
  Future<void> waitIfNeeded() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove old requests
    _requestTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));
    
    // Check if we need to wait
    if (_requestTimes.length >= maxRequestsPerMinute) {
      final oldestRequest = _requestTimes.first;
      final waitTime = oldestRequest.add(const Duration(minutes: 1)).difference(now);
      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime);
      }
    }
    
    // Record this request
    _requestTimes.add(now);
  }
}

/// Utility class for AI prompt templates
class PromptTemplates {
  /// Template for key generation prompts
  static String keyGenerationTemplate({
    required String text,
    required String context,
    required String widgetType,
    required String namingConvention,
    required int maxLength,
  }) {
    return '''
Generate a concise, meaningful localization key for the following text:

Text: "$text"
Context: $context
Widget Type: $widgetType
Naming Convention: $namingConvention
Max Length: $maxLength characters

Requirements:
- Use $namingConvention naming convention
- Maximum $maxLength characters
- Be descriptive but concise
- Consider the UI context and widget type
- Avoid generic names like "text1" or "label"

Respond with only the key name, no explanation.
''';
  }
  
  /// Template for translation prompts
  static String translationTemplate({
    required String text,
    required String targetLanguage,
    required String context,
    required String uiElement,
  }) {
    return '''
Translate the following text to $targetLanguage:

Text: "$text"
Context: $context
UI Element: $uiElement

Requirements:
- Provide a professional, natural translation
- Consider the UI context and element type
- Maintain appropriate tone and formality
- Keep the same meaning and intent
- Consider cultural appropriateness and local conventions
- For Arabic: Use proper RTL text direction and formal Arabic (Modern Standard Arabic)
- For Arabic: Consider gender-neutral language where appropriate
- For Arabic: Use culturally appropriate greetings and expressions
- Ensure proper character encoding (UTF-8) for non-Latin scripts
- Maintain consistent terminology across the application

Respond with only the translated text, no explanation.
''';
  }
  
  /// Template for batch translation prompts
  static String batchTranslationTemplate({
    required List<String> texts,
    required String targetLanguage,
    required String context,
  }) {
    final textList = texts.asMap().entries
        .map((entry) => '${entry.key + 1}. "${entry.value}"')
        .join('\n');
    
    return '''
Translate the following texts to $targetLanguage:

$textList

Context: $context

Requirements:
- Provide professional, natural translations
- Maintain consistency across all translations
- Consider the UI context and maintain consistent terminology
- Keep the same meaning and intent
- Consider cultural appropriateness and local conventions
- For Arabic: Use proper RTL text direction and formal Arabic (Modern Standard Arabic)
- For Arabic: Consider gender-neutral language where appropriate
- For Arabic: Use culturally appropriate expressions and maintain consistency
- Ensure proper character encoding (UTF-8) for non-Latin scripts
- Maintain consistent tone and style across all translations

Respond with only the translated texts in the same order, one per line, no numbering or explanation.
''';
  }
}