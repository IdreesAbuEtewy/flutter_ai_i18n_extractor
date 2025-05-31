import 'dart:io';
import 'package:path/path.dart' as path;

/// Utility functions for file operations and path management
class FileUtils {
  /// Finds all Dart files in a directory recursively
  static Future<List<String>> findDartFiles(
    String directoryPath, {
    List<String> excludePatterns = const [],
    int maxDepth = 10,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw DirectoryNotFoundException('Directory not found: $directoryPath');
    }
    
    final dartFiles = <String>[];
    await _findDartFilesRecursive(
      directory,
      dartFiles,
      excludePatterns,
      0,
      maxDepth,
    );
    
    return dartFiles;
  }
  
  /// Recursively finds Dart files
  static Future<void> _findDartFilesRecursive(
    Directory directory,
    List<String> dartFiles,
    List<String> excludePatterns,
    int currentDepth,
    int maxDepth,
  ) async {
    if (currentDepth >= maxDepth) return;
    
    try {
      await for (final entity in directory.list()) {
        final entityPath = entity.path;
        
        // Check if path should be excluded
        if (_shouldExcludePath(entityPath, excludePatterns)) {
          continue;
        }
        
        if (entity is File && entityPath.endsWith('.dart')) {
          dartFiles.add(path.normalize(entityPath));
        } else if (entity is Directory) {
          await _findDartFilesRecursive(
            entity,
            dartFiles,
            excludePatterns,
            currentDepth + 1,
            maxDepth,
          );
        }
      }
    } catch (e) {
      // Skip directories that can't be accessed
      print('Warning: Could not access directory ${directory.path}: $e');
    }
  }
  
  /// Checks if a path should be excluded based on patterns
  static bool _shouldExcludePath(String filePath, List<String> excludePatterns) {
    final normalizedPath = path.normalize(filePath).replaceAll('\\', '/');
    
    for (final pattern in excludePatterns) {
      if (_matchesPattern(normalizedPath, pattern)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Checks if a path matches a glob-like pattern
  static bool _matchesPattern(String filePath, String pattern) {
    // Convert glob pattern to regex
    String regexPattern = pattern
        .replaceAll('\\', '/')
        .replaceAll('.', '\\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');
    
    // Add anchors if not present
    if (!regexPattern.startsWith('^')) {
      regexPattern = '.*$regexPattern';
    }
    if (!regexPattern.endsWith('\$')) {
      regexPattern = '$regexPattern.*';
    }
    
    final regex = RegExp(regexPattern, caseSensitive: false);
    return regex.hasMatch(filePath);
  }
  
  /// Gets the relative path from a base directory
  static String getRelativePath(String filePath, String basePath) {
    return path.relative(filePath, from: basePath);
  }
  
  /// Ensures a directory exists, creating it if necessary
  static Future<void> ensureDirectoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
  
  /// Copies a file to a new location
  static Future<void> copyFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    
    // Ensure destination directory exists
    await ensureDirectoryExists(path.dirname(destinationPath));
    
    await sourceFile.copy(destinationPath);
  }
  
  /// Moves a file to a new location
  static Future<void> moveFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    
    // Ensure destination directory exists
    await ensureDirectoryExists(path.dirname(destinationPath));
    
    await sourceFile.rename(destinationPath);
  }
  
  /// Deletes a file if it exists
  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Deletes a directory and all its contents
  static Future<void> deleteDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
  
  /// Gets the size of a file in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
  
  /// Gets the last modified time of a file
  static Future<DateTime?> getLastModified(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.lastModified();
    }
    return null;
  }
  
  /// Checks if a file exists
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }
  
  /// Checks if a directory exists
  static Future<bool> directoryExists(String directoryPath) async {
    return await Directory(directoryPath).exists();
  }
  
  /// Reads a file as a string
  static Future<String> readFileAsString(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }
  
  /// Writes a string to a file
  static Future<void> writeStringToFile(String filePath, String content) async {
    final file = File(filePath);
    
    // Ensure directory exists
    await ensureDirectoryExists(path.dirname(filePath));
    
    await file.writeAsString(content);
  }
  
  /// Appends a string to a file
  static Future<void> appendStringToFile(String filePath, String content) async {
    final file = File(filePath);
    
    // Ensure directory exists
    await ensureDirectoryExists(path.dirname(filePath));
    
    await file.writeAsString(content, mode: FileMode.append);
  }
  
  /// Gets the file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }
  
  /// Gets the file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
  
  /// Gets the file name with extension
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
  
  /// Gets the directory path
  static String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }
  
  /// Joins path components
  static String joinPaths(List<String> pathComponents) {
    return path.joinAll(pathComponents);
  }
  
  /// Normalizes a path
  static String normalizePath(String filePath) {
    return path.normalize(filePath);
  }
  
  /// Checks if a path is absolute
  static bool isAbsolutePath(String filePath) {
    return path.isAbsolute(filePath);
  }
  
  /// Converts a path to absolute
  static String toAbsolutePath(String filePath) {
    return path.absolute(filePath);
  }
  
  /// Lists all files in a directory
  static Future<List<String>> listFiles(
    String directoryPath, {
    bool recursive = false,
    String? extension,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }
    
    final files = <String>[];
    
    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is File) {
        final filePath = entity.path;
        
        if (extension == null || filePath.endsWith(extension)) {
          files.add(path.normalize(filePath));
        }
      }
    }
    
    return files;
  }
  
  /// Lists all directories in a directory
  static Future<List<String>> listDirectories(
    String directoryPath, {
    bool recursive = false,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }
    
    final directories = <String>[];
    
    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is Directory) {
        directories.add(path.normalize(entity.path));
      }
    }
    
    return directories;
  }
  
  /// Creates a temporary file
  static Future<File> createTempFile({String? prefix, String? suffix}) async {
    final tempDir = Directory.systemTemp;
    final fileName = '${prefix ?? 'temp'}_${DateTime.now().millisecondsSinceEpoch}${suffix ?? '.tmp'}';
    final tempFile = File(path.join(tempDir.path, fileName));
    
    await tempFile.create();
    return tempFile;
  }
  
  /// Creates a temporary directory
  static Future<Directory> createTempDirectory({String? prefix}) async {
    final tempDir = Directory.systemTemp;
    final dirName = '${prefix ?? 'temp'}_${DateTime.now().millisecondsSinceEpoch}';
    final tempDirectory = Directory(path.join(tempDir.path, dirName));
    
    await tempDirectory.create();
    return tempDirectory;
  }
  
  /// Calculates the total size of a directory
  static Future<int> getDirectorySize(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return 0;
    }
    
    int totalSize = 0;
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        try {
          totalSize += await entity.length();
        } catch (e) {
          // Skip files that can't be accessed
        }
      }
    }
    
    return totalSize;
  }
  
  /// Formats file size in human-readable format
  static String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
  
  /// Validates that a path is safe (no directory traversal)
  static bool isSafePath(String filePath) {
    final normalizedPath = path.normalize(filePath);
    
    // Check for directory traversal attempts
    if (normalizedPath.contains('..')) {
      return false;
    }
    
    // Check for absolute paths that might escape intended directory
    if (path.isAbsolute(normalizedPath)) {
      // Allow absolute paths but be cautious
      return true;
    }
    
    return true;
  }
  
  /// Gets the common base path of multiple file paths
  static String? getCommonBasePath(List<String> filePaths) {
    if (filePaths.isEmpty) return null;
    if (filePaths.length == 1) return path.dirname(filePaths.first);
    
    final normalizedPaths = filePaths.map((p) => path.normalize(p)).toList();
    final firstPath = normalizedPaths.first;
    final pathComponents = path.split(firstPath);
    
    for (int i = pathComponents.length - 1; i >= 0; i--) {
      final candidateBase = path.joinAll(pathComponents.take(i + 1));
      
      if (normalizedPaths.every((p) => p.startsWith(candidateBase))) {
        return candidateBase;
      }
    }
    
    return null;
  }

  /// Writes data to a YAML file
  static Future<void> writeYamlFile(String filePath, Map<String, dynamic> data) async {
    final file = File(filePath);
    
    // Ensure parent directory exists
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    
    // Convert map to YAML string
    final yamlString = _mapToYamlString(data);
    
    // Write to file
    await file.writeAsString(yamlString);
  }

  /// Converts a map to YAML string format
  static String _mapToYamlString(Map<String, dynamic> data, [int indent = 0]) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    
    data.forEach((key, value) {
      buffer.write('$indentStr$key:');
      
      if (value is Map<String, dynamic>) {
        buffer.writeln();
        buffer.write(_mapToYamlString(value, indent + 1));
      } else if (value is List) {
        buffer.writeln();
        for (final item in value) {
          buffer.writeln('$indentStr  - $item');
        }
      } else if (value is String) {
        // Handle strings that might need quoting
        if (value.contains('\n') || value.contains(':') || value.contains('#')) {
          buffer.writeln(' "$value"');
        } else {
          buffer.writeln(' $value');
        }
      } else {
        buffer.writeln(' $value');
      }
    });
    
    return buffer.toString();
  }
}

/// Exception thrown when a directory is not found
class DirectoryNotFoundException implements Exception {
  final String message;
  
  const DirectoryNotFoundException(this.message);
  
  @override
  String toString() => 'DirectoryNotFoundException: $message';
}