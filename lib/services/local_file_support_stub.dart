import 'dart:typed_data';

import 'package:flutter/widgets.dart';

ImageProvider<Object>? localFileImageProvider(String path) => null;

bool localFileExists(String path) => false;

Future<void> deleteLocalFile(String path) async {}

Future<String> saveLocalFile(Uint8List bytes, String fileName) async =>
    throw UnsupportedError(
        'Local file storage is unavailable on this platform.');
