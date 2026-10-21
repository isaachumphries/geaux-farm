import 'dart:io';

import 'package:flutter/services.dart';

/// Loads Nunito, so text measures as it does on a device. The default test
/// font (Ahem) is far wider and overflows labels that fit in the app.
Future<void> loadAppFonts() async {
  final loader = FontLoader('Nunito');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}
