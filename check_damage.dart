import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return;

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // The current state is that files have literal text: .withValues(alpha: ${match.group(1)})
    // or .withOpacity(${match.group(1)})
    // Because they were replaced blindly.
    // However, I didn't actually overwrite with `withValues(alpha...` because my first mistake was withAlpha((.
    // Then my second mistake was replacing `withOpacity(X)` with `withOpacity(${match.group(1)})`.
    // Wait, the error is: Undefined name '$', Expected to find ','
    // So the text in the files is literally `.withOpacity(${match.group(1)})`.
    // I need to use regex to capture the original opacity from git? No, there is no git.
    // Wait, if it replaced it with the literal text, the ORIGINAL VALUE IS LOST!!!
    // Oh no.
    
    // BUT wait! Did the opacityExp match `.withOpacity(0.1)` AND `.withOpacity(${match.group(1)})`?
    // Let me check what is actually in the file.
    
    print('Checking \${file.path}');
  }
}
