import 'dart:io';

void main() async {
  final directory = Directory('lib');
  final regex = RegExp(r'AppColors\.([a-zA-Z0-9_]+)');

  await for (final file in directory.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart') && !file.path.contains('app_theme.dart')) {
      final content = await file.readAsString();
      if (content.contains('AppColors.')) {
        final newContent = content.replaceAllMapped(regex, (match) {
          return 'context.colors.${match.group(1)}';
        });

        if (content != newContent) {
          await file.writeAsString(newContent);
        }
      }
    }
  }
}
