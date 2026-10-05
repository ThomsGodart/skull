import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the engine never imports Flutter', () {
    final offenders = [
      for (final file in Directory('lib/engine').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            RegExp(r'''import\s+['"](package:flutter|dart:ui)''')
                .hasMatch(file.readAsStringSync()))
          file.path,
    ];

    expect(offenders, isEmpty);
  });
}
