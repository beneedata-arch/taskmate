// Run once after `flutter create`:   dart tool/setup_android.dart
//
// Patches the generated Android project so TaskMate builds:
//   * adds INTERNET / POST_NOTIFICATIONS permissions and an https <queries>
//     entry (needed to open attachments) to AndroidManifest.xml
//   * raises minSdk to 23 (required by the Firebase plugins)
import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln(
      'android/ folder not found. Run this first:\n'
      '  flutter create . --platforms=android --org com.taskmate',
    );
    exit(1);
  }

  _patchManifest(manifest);
  _patchMinSdk();
  stdout.writeln('\nAndroid project patched. Next: flutterfire configure');
}

void _patchManifest(File manifest) {
  var text = manifest.readAsStringSync();

  const permissions = [
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
  ];
  const queries = '''
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
''';

  final additions = StringBuffer();
  for (final p in permissions) {
    final name = RegExp(r'android:name="([^"]+)"').firstMatch(p)!.group(1)!;
    if (!text.contains(name)) additions.writeln('    $p');
  }
  if (!text.contains('android:scheme="https"')) additions.write(queries);

  if (additions.isEmpty) {
    stdout.writeln('AndroidManifest.xml already patched.');
    return;
  }
  final index = text.indexOf('<application');
  if (index < 0) {
    stderr.writeln('Could not find <application> in AndroidManifest.xml.');
    exit(1);
  }
  text = text.replaceRange(index, index, '${additions.toString()}    ');
  manifest.writeAsStringSync(text);
  stdout.writeln('AndroidManifest.xml patched.');
}

void _patchMinSdk() {
  final candidates = [
    File('android/app/build.gradle.kts'),
    File('android/app/build.gradle'),
  ];
  for (final file in candidates) {
    if (!file.existsSync()) continue;
    final original = file.readAsStringSync();
    var updated = original.replaceAll('flutter.minSdkVersion', '23');
    updated = updated.replaceAllMapped(
      RegExp(r'(minSdk(?:Version)?\s*=?\s*)(\d+)'),
      (m) => int.parse(m.group(2)!) < 23 ? '${m.group(1)}23' : m.group(0)!,
    );
    if (updated != original) {
      file.writeAsStringSync(updated);
      stdout.writeln('${file.path}: minSdk set to 23.');
    } else {
      stdout.writeln('${file.path}: minSdk already OK.');
    }
    return;
  }
  stderr.writeln(
    'Could not find android/app/build.gradle(.kts). '
    'Set minSdk to 23 manually.',
  );
}
