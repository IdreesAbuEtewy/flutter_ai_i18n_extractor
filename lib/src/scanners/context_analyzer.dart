import '../core/extracted_string.dart';
import 'string_parser.dart';

/// Analyzes the context of extracted strings to determine their UI purpose
class ContextAnalyzer {
  /// Analyzes the context of an extracted string
  Future<StringContext> analyzeContext(ExtractedString extractedString) async {
    final contextType = _determineContextType(extractedString);
    final screenContext = _inferScreenContext(extractedString);
    final confidence = _calculateConfidence(extractedString, contextType);
    
    return StringContext(
      type: contextType,
      screenContext: screenContext,
      confidence: confidence,
    );
  }
  
  /// Determines the context type based on widget and parameter information
  StringContextType _determineContextType(ExtractedString extractedString) {
    final widgetType = extractedString.widgetType?.toLowerCase();
    final parameterName = extractedString.parameterName?.toLowerCase();
    final value = extractedString.value;
    
    // Analyze based on widget type
    if (widgetType != null) {
      final widgetContext = _analyzeWidgetContext(widgetType, parameterName);
      if (widgetContext != StringContextType.unknown) {
        return widgetContext;
      }
    }
    
    // Analyze based on parameter name
    if (parameterName != null) {
      final paramContext = _analyzeParameterContext(parameterName);
      if (paramContext != StringContextType.unknown) {
        return paramContext;
      }
    }
    
    // Analyze based on string content
    return StringParser.inferContextFromContent(value);
  }
  
  /// Analyzes context based on widget type
  StringContextType _analyzeWidgetContext(String widgetType, String? parameterName) {
    switch (widgetType) {
      // Button widgets
      case 'elevatedbutton':
      case 'textbutton':
      case 'outlinedbutton':
      case 'iconbutton':
      case 'floatingactionbutton':
      case 'button':
        return StringContextType.button;
      
      // Text widgets
      case 'text':
        if (parameterName == 'data') {
          return StringContextType.message;
        }
        return StringContextType.message;
      
      // AppBar and titles
      case 'appbar':
        if (parameterName == 'title') {
          return StringContextType.title;
        }
        return StringContextType.navigation;
      
      // Input fields
      case 'textfield':
      case 'textformfield':
        if (parameterName == 'hinttext') {
          return StringContextType.hint;
        } else if (parameterName == 'labeltext') {
          return StringContextType.label;
        } else if (parameterName == 'helpertext') {
          return StringContextType.description;
        } else if (parameterName == 'errortext') {
          return StringContextType.error;
        }
        return StringContextType.placeholder;
      
      // Dialog widgets
      case 'alertdialog':
      case 'dialog':
      case 'showdialog':
        if (parameterName == 'title') {
          return StringContextType.title;
        } else if (parameterName == 'content') {
          return StringContextType.message;
        }
        return StringContextType.confirmation;
      
      // Snackbar
      case 'snackbar':
        return StringContextType.message;
      
      // ListTile
      case 'listtile':
        if (parameterName == 'title') {
          return StringContextType.title;
        } else if (parameterName == 'subtitle') {
          return StringContextType.description;
        }
        return StringContextType.message;
      
      // Card
      case 'card':
        return StringContextType.message;
      
      // Tooltip
      case 'tooltip':
        return StringContextType.description;
      
      // Chip
      case 'chip':
      case 'actionchip':
      case 'filterschip':
      case 'inputchip':
        return StringContextType.label;
      
      default:
        return StringContextType.unknown;
    }
  }
  
  /// Analyzes context based on parameter name
  StringContextType _analyzeParameterContext(String parameterName) {
    switch (parameterName) {
      // Title parameters
      case 'title':
      case 'heading':
      case 'header':
        return StringContextType.title;
      
      // Message parameters
      case 'content':
      case 'message':
      case 'text':
      case 'data':
      case 'body':
        return StringContextType.message;
      
      // Button parameters
      case 'child':
        return StringContextType.button; // Context-dependent
      
      // Input field parameters
      case 'hinttext':
      case 'hint':
      case 'placeholder':
        return StringContextType.hint;
      
      case 'labeltext':
      case 'label':
        return StringContextType.label;
      
      case 'helpertext':
      case 'helper':
      case 'description':
        return StringContextType.description;
      
      case 'errortext':
      case 'error':
        return StringContextType.error;
      
      // Navigation parameters
      case 'tooltip':
        return StringContextType.description;
      
      case 'semanticlabel':
        return StringContextType.description;
      
      default:
        return StringContextType.unknown;
    }
  }
  
  /// Infers the screen context from file path and surrounding code
  String? _inferScreenContext(ExtractedString extractedString) {
    final filePath = extractedString.filePath;
    final surroundingCode = extractedString.surroundingCode;
    
    // Extract screen name from file path
    String? screenFromPath = _extractScreenFromPath(filePath);
    
    // Extract screen name from surrounding code
    String? screenFromCode = _extractScreenFromCode(surroundingCode);
    
    return screenFromCode ?? screenFromPath;
  }
  
  /// Extracts screen context from file path
  String? _extractScreenFromPath(String filePath) {
    final fileName = filePath.split('/').last.replaceAll('.dart', '');
    
    // Common screen naming patterns
    final screenPatterns = [
      RegExp(r'(.+)_screen$'),
      RegExp(r'(.+)_page$'),
      RegExp(r'(.+)_view$'),
      RegExp(r'(.+)Screen$'),
      RegExp(r'(.+)Page$'),
      RegExp(r'(.+)View$'),
    ];
    
    for (final pattern in screenPatterns) {
      final match = pattern.firstMatch(fileName);
      if (match != null) {
        return _formatScreenName(match.group(1)!);
      }
    }
    
    // Check if the file name itself suggests a screen
    final commonScreens = [
      'login', 'signup', 'home', 'profile', 'settings', 'dashboard',
      'welcome', 'onboarding', 'splash', 'about', 'help', 'contact',
      'search', 'details', 'list', 'cart', 'checkout', 'payment',
    ];
    
    final lowerFileName = fileName.toLowerCase();
    for (final screen in commonScreens) {
      if (lowerFileName.contains(screen)) {
        return _formatScreenName(screen);
      }
    }
    
    return null;
  }
  
  /// Extracts screen context from surrounding code
  String? _extractScreenFromCode(String? surroundingCode) {
    if (surroundingCode == null) return null;
    
    // Look for class names that suggest screens
    final classPattern = RegExp(r'class\s+(\w+(?:Screen|Page|View))');
    final match = classPattern.firstMatch(surroundingCode);
    
    if (match != null) {
      final className = match.group(1)!;
      return _formatScreenName(className.replaceAll(RegExp(r'(Screen|Page|View)$'), ''));
    }
    
    return null;
  }
  
  /// Formats screen name for display
  String _formatScreenName(String screenName) {
    // Convert camelCase or snake_case to Title Case
    final words = screenName
        .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    
    return words;
  }
  
  /// Calculates confidence score for the context analysis
  double _calculateConfidence(ExtractedString extractedString, StringContextType contextType) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence based on available information
    if (extractedString.widgetType != null) {
      confidence += 0.3;
    }
    
    if (extractedString.parameterName != null) {
      confidence += 0.2;
    }
    
    // Adjust confidence based on context type certainty
    switch (contextType) {
      case StringContextType.button:
      case StringContextType.title:
      case StringContextType.error:
        confidence += 0.1; // High certainty contexts
        break;
      case StringContextType.hint:
      case StringContextType.label:
        confidence += 0.05; // Medium certainty contexts
        break;
      case StringContextType.unknown:
        confidence -= 0.2; // Low certainty
        break;
      default:
        break;
    }
    
    // Ensure confidence is within bounds
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Analyzes multiple strings to find patterns and improve context detection
  Future<void> analyzePatterns(List<ExtractedString> strings) async {
    // Group strings by file
    final fileGroups = <String, List<ExtractedString>>{};
    for (final string in strings) {
      fileGroups.putIfAbsent(string.filePath, () => []).add(string);
    }
    
    // Analyze patterns within each file
    for (final entry in fileGroups.entries) {
      await _analyzeFilePatterns(entry.key, entry.value);
    }
  }
  
  /// Analyzes patterns within a single file
  Future<void> _analyzeFilePatterns(String filePath, List<ExtractedString> strings) async {
    // Look for common patterns like form fields, button groups, etc.
    final widgetTypes = strings.map((s) => s.widgetType).where((w) => w != null).toSet();
    final parameterNames = strings.map((s) => s.parameterName).where((p) => p != null).toSet();
    
    // If file has many TextFields, it's likely a form
    if (widgetTypes.contains('TextField') || widgetTypes.contains('TextFormField') ||
        parameterNames.contains('hintText') || parameterNames.contains('labelText')) {
      // Mark hint texts and labels appropriately
      for (final string in strings) {
        if (string.parameterName == 'hintText' && string.context?.type == StringContextType.unknown) {
          string.context = StringContext(
            type: StringContextType.hint,
            screenContext: string.context?.screenContext,
            confidence: 0.8,
          );
        }
      }
    }
    
    // If file has many buttons, analyze button hierarchy
    final buttonStrings = strings.where((s) => 
        s.widgetType?.toLowerCase().contains('button') == true).toList();
    
    if (buttonStrings.length > 1) {
      // Primary actions are usually longer or contain action words
      for (final string in buttonStrings) {
        if (string.value.toLowerCase().contains('save') ||
            string.value.toLowerCase().contains('submit') ||
            string.value.toLowerCase().contains('continue')) {
          // This is likely a primary action button
        }
      }
    }
  }
}