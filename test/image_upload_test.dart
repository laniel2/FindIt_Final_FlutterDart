import 'dart:convert';

import 'package:findit/services/item_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('data URI uploads are preserved for browser-based image selection', () {
    const dataUri = 'data:image/png;base64,AAAA';

    expect(ItemRepository.isDataUri(dataUri), isTrue);
    expect(ItemRepository.decodeDataUri(dataUri), equals(base64Decode('AAAA')));
  });

  test('local file paths are treated as native files instead of browser data URIs', () {
    const localPath = '/tmp/example.png';

    expect(ItemRepository.isDataUri(localPath), isFalse);
    expect(ItemRepository.isLocalFilePath(localPath), isTrue);
  });
}
