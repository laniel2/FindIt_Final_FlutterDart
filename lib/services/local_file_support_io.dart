import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

ImageProvider<Object>? localFileImageProvider(String path) =>
    FileImage(File(path));

bool localFileExists(String path) => File(path).existsSync();

Future<void> deleteLocalFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<String> saveLocalFile(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final extension = fileName.contains('.') ? fileName.split('.').last : 'jpg';
  final path =
      '${directory.path}/img_${DateTime.now().microsecondsSinceEpoch}.$extension';
  await File(path).writeAsBytes(bytes);
  return path;
}
