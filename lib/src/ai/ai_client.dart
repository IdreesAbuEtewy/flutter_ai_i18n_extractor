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
      // Free Translation Services (Default)
      case 'google_translate':
        return GoogleTranslateClient(effectiveConfig);
      case 'google_translate_2':
        return GoogleTranslate2Client(effectiveConfig);
      case 'bing_translate':
        return BingTranslateClient(effectiveConfig);
      case 'libre_translate':
        return LibreTranslateClient(effectiveConfig);
      case 'argos_translate':
        return ArgosTranslateClient(effectiveConfig);
      case 'deepl_translate':
        return DeepLTranslateClient(effectiveConfig);
      
      // AI Models (Paid/API Key Required)
      case 'openai':
        return OpenAiClient(effectiveConfig);
      case 'google':
        return GoogleAiClient(effectiveConfig);
      case 'anthropic':
        return AnthropicAiClient(effectiveConfig);
      case 'deepseek':
        return DeepSeekAiClient(effectiveConfig);
      case 'groq':
        return GroqAiClient(effectiveConfig);
      case 'cohere':
        return CohereAiClient(effectiveConfig);
      case 'huggingface':
        return HuggingFaceAiClient(effectiveConfig);
      case 'ollama':
        return OllamaAiClient(effectiveConfig);
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
        // Free translation services (no API key required)
        case 'google_translate':
        case 'google_translate_2':
        case 'bing_translate':
        case 'libre_translate':
        case 'argos_translate':
          apiKey = 'free';
          break;
        case 'deepl_translate':
          apiKey = Platform.environment['DEEPL_API_KEY'];
          break;
        
        // AI Models (API key required)
        case 'openai':
          apiKey = Platform.environment['OPENAI_API_KEY'];
          break;
        case 'google':
          apiKey = Platform.environment['GOOGLE_AI_API_KEY'];
          break;
        case 'anthropic':
          apiKey = Platform.environment['ANTHROPIC_API_KEY'];
          break;
        case 'deepseek':
          apiKey = Platform.environment['DEEPSEEK_API_KEY'];
          break;
        case 'groq':
          apiKey = Platform.environment['GROQ_API_KEY'];
          break;
        case 'cohere':
          apiKey = Platform.environment['COHERE_API_KEY'];
          break;
        case 'huggingface':
          apiKey = Platform.environment['HUGGINGFACE_API_KEY'];
          break;
        case 'ollama':
          // Ollama typically runs locally without API key
          apiKey = Platform.environment['OLLAMA_API_KEY'] ?? 'local';
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

/// DeepSeek AI client implementation
class DeepSeekAiClient extends AiClient {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  
  const DeepSeekAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final url = Uri.parse('$_baseUrl/chat/completions');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
    
    final body = {
      'model': config.model.isNotEmpty ? config.model : 'deepseek-chat',
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
        'DeepSeek API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with DeepSeek: $e');
    }
  }
}

/// Groq AI client implementation (fast inference)
class GroqAiClient extends AiClient {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  
  const GroqAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final url = Uri.parse('$_baseUrl/chat/completions');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
    
    final body = {
      'model': config.model.isNotEmpty ? config.model : 'llama3-8b-8192',
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
        'Groq API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Groq: $e');
    }
  }
}

/// Cohere AI client implementation
class CohereAiClient extends AiClient {
  static const String _baseUrl = 'https://api.cohere.ai/v1';
  
  const CohereAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final url = Uri.parse('$_baseUrl/generate');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
    
    final body = {
      'model': config.model.isNotEmpty ? config.model : 'command-light',
      'prompt': prompt,
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
        final generations = data['generations'] as List;
        if (generations.isNotEmpty) {
          return generations[0]['text'] as String;
        }
      }
      
      throw AiClientException(
        'Cohere API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Cohere: $e');
    }
  }
}

/// Hugging Face AI client implementation
class HuggingFaceAiClient extends AiClient {
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';
  
  const HuggingFaceAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final model = config.model.isNotEmpty ? config.model : 'microsoft/DialoGPT-medium';
    final url = Uri.parse('$_baseUrl/$model');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
    
    final body = {
      'inputs': prompt,
      'parameters': {
        'max_length': options?['max_tokens'] ?? 1000,
        'temperature': options?['temperature'] ?? 0.3,
      },
    };
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text'] as String;
        } else if (data is Map && data.containsKey('generated_text')) {
          return data['generated_text'] as String;
        }
      }
      
      throw AiClientException(
        'Hugging Face API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Hugging Face: $e');
    }
  }
}

/// Ollama AI client implementation (local models)
class OllamaAiClient extends AiClient {
  static const String _defaultBaseUrl = 'http://localhost:11434';
  
  const OllamaAiClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final baseUrl = Platform.environment['OLLAMA_BASE_URL'] ?? _defaultBaseUrl;
    final url = Uri.parse('$baseUrl/api/generate');
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    final body = {
      'model': config.model.isNotEmpty ? config.model : 'llama2',
      'prompt': prompt,
      'stream': false,
      'options': {
        'temperature': options?['temperature'] ?? 0.3,
        'num_predict': options?['max_tokens'] ?? 1000,
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
        return data['response'] as String;
      }
      
      throw AiClientException(
        'Ollama API request failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Ollama: $e');
    }
  }
}

/// Google Translate client implementation (Free)
class GoogleTranslateClient extends AiClient {
  const GoogleTranslateClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    // Extract text and target language from prompt
    final translation = await _translateText(prompt, options?['target_language'] ?? 'en');
    return translation;
  }
  
  Future<String> _translateText(String text, String targetLang) async {
    final url = Uri.parse('https://translate.googleapis.com/translate_a/single')
        .replace(queryParameters: {
      'client': 'gtx',
      'sl': 'auto',
      'tl': targetLang,
      'dt': 't',
      'q': text,
    });
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          return data[0][0][0] as String;
        }
      }
      throw AiClientException('Google Translate request failed: ${response.statusCode}');
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Google Translate: $e');
    }
  }
}

/// Google Translate 2 client implementation (Free, alternative endpoint)
class GoogleTranslate2Client extends AiClient {
  const GoogleTranslate2Client(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final translation = await _translateText(prompt, options?['target_language'] ?? 'en');
    return translation;
  }
  
  Future<String> _translateText(String text, String targetLang) async {
    final url = Uri.parse('https://clients5.google.com/translate_a/t')
        .replace(queryParameters: {
      'client': 'dict-chrome-ex',
      'sl': 'auto',
      'tl': targetLang,
      'q': text,
    });
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0] as String;
        }
      }
      throw AiClientException('Google Translate 2 request failed: ${response.statusCode}');
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Google Translate 2: $e');
    }
  }
}

/// Microsoft Bing Translate client implementation (Free)
class BingTranslateClient extends AiClient {
  const BingTranslateClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final translation = await _translateText(prompt, options?['target_language'] ?? 'en');
    return translation;
  }
  
  Future<String> _translateText(String text, String targetLang) async {
    final url = Uri.parse('https://www.bing.com/ttranslatev3')
        .replace(queryParameters: {
      'fromLang': 'auto-detect',
      'to': targetLang,
      'text': text,
    });
    
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };
    
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0]['translations'] is List) {
          return data[0]['translations'][0]['text'] as String;
        }
      }
      throw AiClientException('Bing Translate request failed: ${response.statusCode}');
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Bing Translate: $e');
    }
  }
}

/// LibreTranslate client implementation (Free)
class LibreTranslateClient extends AiClient {
  const LibreTranslateClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final translation = await _translateText(prompt, options?['target_language'] ?? 'en');
    return translation;
  }
  
  Future<String> _translateText(String text, String targetLang) async {
    final baseUrl = Platform.environment['LIBRETRANSLATE_URL'] ?? 'https://libretranslate.de';
    final url = Uri.parse('$baseUrl/translate');
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    final body = {
      'q': text,
      'source': 'auto',
      'target': targetLang,
      'format': 'text',
    };
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['translatedText'] as String;
      }
      
      throw AiClientException('LibreTranslate request failed: ${response.statusCode}');
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with LibreTranslate: $e');
    }
  }
}

/// Argos Translate client implementation (Free, local)
class ArgosTranslateClient extends AiClient {
  const ArgosTranslateClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final translation = await _translateText(prompt, options?['target_language'] ?? 'en');
    return translation;
  }
  
  Future<String> _translateText(String text, String targetLang) async {
    final baseUrl = Platform.environment['ARGOS_TRANSLATE_URL'] ?? 'http://localhost:5000';
    final url = Uri.parse('$baseUrl/translate');
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    final body = {
      'q': text,
      'source': 'auto',
      'target': targetLang,
    };
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['translatedText'] as String;
      }
      
      throw AiClientException('Argos Translate request failed: ${response.statusCode}');
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with Argos Translate: $e');
    }
  }
}

/// DeepL Translate client implementation (API Key Required)
class DeepLTranslateClient extends AiClient {
  const DeepLTranslateClient(super.config);
  
  @override
  Future<String> sendPrompt(String prompt, {Map<String, dynamic>? options}) async {
    final translation = await _translateText(prompt, options?['target_language'] ?? 'en');
    return translation;
  }
  
  Future<String> _translateText(String text, String targetLang) async {
    final baseUrl = Platform.environment['DEEPL_API_URL'] ?? 'https://api-free.deepl.com';
    final url = Uri.parse('$baseUrl/v2/translate');
    
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'DeepL-Auth-Key ${config.apiKey}',
    };
    
    final body = {
      'text': text,
      'target_lang': targetLang.toUpperCase(),
    };
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final translations = data['translations'] as List;
        if (translations.isNotEmpty) {
          return translations[0]['text'] as String;
        }
      }
      
      throw AiClientException('DeepL Translate request failed: ${response.statusCode}');
    } catch (e) {
      if (e is AiClientException) rethrow;
      throw AiClientException('Failed to communicate with DeepL Translate: $e');
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