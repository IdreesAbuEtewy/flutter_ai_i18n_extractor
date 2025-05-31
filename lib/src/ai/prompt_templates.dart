/// Templates for AI prompts used in translation and key generation
class PromptTemplates {
  /// Template for generating localization keys
  static String keyGenerationTemplate({
    required String text,
    required String context,
    String? widgetType,
    String? parameterName,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Generate a concise, descriptive localization key for the following text:');
    buffer.writeln();
    buffer.writeln('Text: "$text"');
    buffer.writeln('Context: $context');
    
    if (widgetType != null) {
      buffer.writeln('Widget Type: $widgetType');
    }
    
    if (parameterName != null) {
      buffer.writeln('Parameter: $parameterName');
    }
    
    buffer.writeln();
    buffer.writeln('Requirements:');
    buffer.writeln('- Use camelCase format');
    buffer.writeln('- Be descriptive but concise (2-4 words)');
    buffer.writeln('- Reflect the UI context and purpose');
    buffer.writeln('- Avoid generic terms like "text" or "label"');
    buffer.writeln('- Use common Flutter/mobile app terminology');
    buffer.writeln();
    buffer.writeln('Examples:');
    buffer.writeln('- "Welcome to our app" → welcomeMessage');
    buffer.writeln('- "Sign In" → signInButton');
    buffer.writeln('- "Enter your email" → emailInputHint');
    buffer.writeln('- "Loading..." → loadingIndicator');
    buffer.writeln();
    buffer.writeln('Return only the key name, no explanation:');
    
    return buffer.toString();
  }
  
  /// Template for batch key generation
  static String batchKeyGenerationTemplate({
    required List<String> texts,
    required String context,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Generate concise, descriptive localization keys for the following texts:');
    buffer.writeln();
    buffer.writeln('Context: $context');
    buffer.writeln();
    buffer.writeln('Texts:');
    
    for (int i = 0; i < texts.length; i++) {
      buffer.writeln('${i + 1}. "${texts[i]}"');
    }
    
    buffer.writeln();
    buffer.writeln('Requirements:');
    buffer.writeln('- Use camelCase format');
    buffer.writeln('- Be descriptive but concise (2-4 words)');
    buffer.writeln('- Reflect the UI context and purpose');
    buffer.writeln('- Avoid generic terms like "text" or "label"');
    buffer.writeln('- Use common Flutter/mobile app terminology');
    buffer.writeln('- Ensure keys are unique and related');
    buffer.writeln();
    buffer.writeln('Return one key per line, in the same order as the texts:');
    
    return buffer.toString();
  }
  
  /// Template for single text translation
  static String translationTemplate({
    required String text,
    required String targetLanguage,
    required String context,
    String? uiElement,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Translate the following text to $targetLanguage:');
    buffer.writeln();
    buffer.writeln('Text: "$text"');
    buffer.writeln('Context: $context');
    
    if (uiElement != null) {
      buffer.writeln('UI Element: $uiElement');
    }
    
    buffer.writeln();
    buffer.writeln('Requirements:');
    buffer.writeln('- Provide a natural, professional translation');
    buffer.writeln('- Maintain the tone and style appropriate for mobile app UI');
    buffer.writeln('- Consider cultural context and local conventions');
    buffer.writeln('- Keep the same level of formality as the original');
    buffer.writeln('- Preserve any formatting or special characters if relevant');
    buffer.writeln('- Ensure the translation fits the UI context');
    buffer.writeln();
    buffer.writeln('Return only the translated text, no explanation:');
    
    return buffer.toString();
  }
  
  /// Template for batch translation
  static String batchTranslationTemplate({
    required List<String> texts,
    required String targetLanguage,
    required String context,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Translate the following texts to $targetLanguage:');
    buffer.writeln();
    buffer.writeln('Context: $context');
    buffer.writeln();
    buffer.writeln('Texts:');
    
    for (int i = 0; i < texts.length; i++) {
      buffer.writeln('${i + 1}. "${texts[i]}"');
    }
    
    buffer.writeln();
    buffer.writeln('Requirements:');
    buffer.writeln('- Provide natural, professional translations');
    buffer.writeln('- Maintain consistency across related texts');
    buffer.writeln('- Keep the tone and style appropriate for mobile app UI');
    buffer.writeln('- Consider cultural context and local conventions');
    buffer.writeln('- Preserve the same level of formality as the originals');
    buffer.writeln('- Ensure translations fit the UI context');
    buffer.writeln('- Maintain consistency in terminology');
    buffer.writeln();
    buffer.writeln('Return one translation per line, in the same order as the original texts:');
    
    return buffer.toString();
  }
  
  /// Template for context analysis
  static String contextAnalysisTemplate({
    required String text,
    required String filePath,
    String? surroundingCode,
    String? widgetType,
    String? parameterName,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Analyze the UI context for the following text:');
    buffer.writeln();
    buffer.writeln('Text: "$text"');
    buffer.writeln('File: $filePath');
    
    if (widgetType != null) {
      buffer.writeln('Widget: $widgetType');
    }
    
    if (parameterName != null) {
      buffer.writeln('Parameter: $parameterName');
    }
    
    if (surroundingCode != null) {
      buffer.writeln();
      buffer.writeln('Surrounding Code:');
      buffer.writeln('```dart');
      buffer.writeln(surroundingCode);
      buffer.writeln('```');
    }
    
    buffer.writeln();
    buffer.writeln('Determine the most likely UI context from these options:');
    buffer.writeln('- button: Button text or action labels');
    buffer.writeln('- title: Screen titles, section headers');
    buffer.writeln('- message: User messages, notifications, alerts');
    buffer.writeln('- hint: Input hints, placeholder text');
    buffer.writeln('- label: Form labels, field descriptions');
    buffer.writeln('- error: Error messages, validation text');
    buffer.writeln('- description: Explanatory text, help text');
    buffer.writeln('- navigation: Menu items, tab labels');
    buffer.writeln('- status: Status indicators, progress text');
    buffer.writeln('- content: Main content text, body text');
    buffer.writeln();
    buffer.writeln('Return only the context type (one word), no explanation:');
    
    return buffer.toString();
  }
  
  /// Template for translation quality review
  static String qualityReviewTemplate({
    required String originalText,
    required String translatedText,
    required String targetLanguage,
    required String context,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Review the quality of this translation:');
    buffer.writeln();
    buffer.writeln('Original (English): "$originalText"');
    buffer.writeln('Translation ($targetLanguage): "$translatedText"');
    buffer.writeln('Context: $context');
    buffer.writeln();
    buffer.writeln('Evaluate the translation based on:');
    buffer.writeln('- Accuracy: Does it convey the same meaning?');
    buffer.writeln('- Naturalness: Does it sound natural in the target language?');
    buffer.writeln('- Cultural appropriateness: Is it suitable for the target culture?');
    buffer.writeln('- UI context: Does it fit the mobile app interface context?');
    buffer.writeln('- Length: Is it appropriate for UI space constraints?');
    buffer.writeln();
    buffer.writeln('Rate the translation quality:');
    buffer.writeln('- excellent: Perfect translation, no issues');
    buffer.writeln('- good: Minor issues, generally acceptable');
    buffer.writeln('- fair: Some issues, needs improvement');
    buffer.writeln('- poor: Major issues, needs retranslation');
    buffer.writeln();
    buffer.writeln('Return only the rating (one word), no explanation:');
    
    return buffer.toString();
  }
  
  /// Template for generating alternative translations
  static String alternativeTranslationsTemplate({
    required String text,
    required String targetLanguage,
    required String context,
    int alternatives = 3,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Generate $alternatives alternative translations for:');
    buffer.writeln();
    buffer.writeln('Text: "$text"');
    buffer.writeln('Target Language: $targetLanguage');
    buffer.writeln('Context: $context');
    buffer.writeln();
    buffer.writeln('Requirements:');
    buffer.writeln('- Provide $alternatives different translation options');
    buffer.writeln('- Each should be natural and appropriate for mobile UI');
    buffer.writeln('- Vary in formality, length, or style while maintaining meaning');
    buffer.writeln('- Consider different cultural expressions');
    buffer.writeln('- Ensure all are suitable for the given context');
    buffer.writeln();
    buffer.writeln('Return one translation per line, numbered:');
    
    return buffer.toString();
  }
  
  /// Template for terminology consistency check
  static String terminologyConsistencyTemplate({
    required Map<String, String> termPairs,
    required String targetLanguage,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Check terminology consistency for $targetLanguage translations:');
    buffer.writeln();
    buffer.writeln('Term pairs (English → $targetLanguage):');
    
    termPairs.forEach((english, translation) {
      buffer.writeln('"$english" → "$translation"');
    });
    
    buffer.writeln();
    buffer.writeln('Analyze:');
    buffer.writeln('- Are the translations consistent in style and terminology?');
    buffer.writeln('- Do they use the same terms for similar concepts?');
    buffer.writeln('- Are there any conflicting translations for the same term?');
    buffer.writeln('- Is the formality level consistent across translations?');
    buffer.writeln();
    buffer.writeln('Return "consistent" or "inconsistent" followed by specific issues if any:');
    
    return buffer.toString();
  }
}