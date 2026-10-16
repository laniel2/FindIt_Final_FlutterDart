import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import 'local_file_support.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class LoadResult {
  final List<Item> items;

  /// Set when the API could not be reached but local items are still shown.
  final String? warning;
  LoadResult(this.items, this.warning);
}

/// Stores lost & found reports on the device (SharedPreferences JSON, no MySQL)
/// and pulls starter reports from a public REST API (dummyjson.com).
class ItemRepository {
  ItemRepository._();
  static final ItemRepository instance = ItemRepository._();

  static const _itemsKey = 'items';
  static const _seededKey = 'items_seeded_from_api';
  static const deletedRetentionDays = 30;

  /// Screens listen to this and reload whenever data changes.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  // ---------------------------------------------------------------- API
  static const _places = [
    'Library',
    'Cafeteria',
    'Gymnasium',
    'Computer Lab',
    'Main Gate',
    'Science Building',
  ];

  /// Fetch sample reports from the API. Each endpoint returns products that
  /// look like typical lost items (watches, bags, sunglasses, phone accessories).
  Future<List<Item>> _fetchFromApi() async {
    const endpoints = {
      'mens-watches': 'Accessories',
      'womens-bags': 'Bags',
      'sunglasses': 'Accessories',
      'mobile-accessories': 'Electronics',
    };
    try {
      final responses = await Future.wait(endpoints.keys.map((cat) {
        final uri = Uri.parse(
            'https://dummyjson.com/products/category/$cat?limit=2&select=title,description,thumbnail');
        return http.get(uri).timeout(const Duration(seconds: 12));
      }));

      final items = <Item>[];
      var n = 0;
      for (var i = 0; i < responses.length; i++) {
        final res = responses[i];
        if (res.statusCode != 200) {
          throw ApiException('Server responded with error ${res.statusCode}.');
        }
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final category = endpoints.values.elementAt(i);
        for (final p in (body['products'] as List<dynamic>)) {
          final m = p as Map<String, dynamic>;
          items.add(Item(
            id: 'api_${m['id']}',
            title: m['title'] as String,
            description: (m['description'] ?? '') as String,
            category: category,
            location: _places[n % _places.length],
            type: n.isEven ? ItemType.found : ItemType.lost,
            image: m['thumbnail'] as String?,
            ownerId: 'school_feed',
            ownerName: 'School Security Office',
            contact: 'security@school.edu',
            createdAt: DateTime.now().subtract(Duration(days: n + 1)),
          ));
          n++;
        }
      }
      return items;
    } on SocketException {
      throw ApiException('No internet connection. Check your network.');
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException('Could not reach the server.');
    } on FormatException {
      throw ApiException('Received unexpected data from the server.');
    }
  }

  // ------------------------------------------------------------ Storage
  Future<List<Item>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _writeAll(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _itemsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    changes.value++;
  }

  Future<void> _purgeExpired() async {
    final items = await _readAll();
    final now = DateTime.now();
    final expired = items.where((item) {
      final deletedAt = item.deletedAt;
      return deletedAt != null &&
          now.difference(deletedAt) >=
              const Duration(days: deletedRetentionDays);
    }).toList();
    if (expired.isEmpty) return;

    final expiredIds = expired.map((item) => item.id).toSet();
    await _writeAll(
        items.where((item) => !expiredIds.contains(item.id)).toList());
    for (final item in expired) {
      await _removeStoredImage(item);
    }
  }

  Future<void> _removeStoredImage(Item item) async {
    if (item.image == null ||
        item.hasNetworkImage ||
        !isLocalFilePath(item.image)) {
      return;
    }
    await deleteLocalFile(item.image!);
  }

  /// Loads all items. On first run (or until it succeeds) it also tries to
  /// download starter reports from the API and saves them locally.
  Future<LoadResult> loadItems() async {
    await _purgeExpired();
    final prefs = await SharedPreferences.getInstance();
    String? warning;
    if (!(prefs.getBool(_seededKey) ?? false)) {
      try {
        final fromApi = await _fetchFromApi();
        final existing = await _readAll();
        await prefs.setString(
            _itemsKey,
            jsonEncode(
                [...existing, ...fromApi].map((e) => e.toJson()).toList()));
        await prefs.setBool(_seededKey, true);
      } on ApiException catch (e) {
        warning = e.message;
      }
    }
    final items =
        (await _readAll()).where((item) => item.deletedAt == null).toList();
    if (items.isEmpty && warning != null) throw ApiException(warning);
    return LoadResult(items, warning);
  }

  /// Reads stored items without contacting the API (used for profile stats).
  Future<List<Item>> readLocal() async {
    await _purgeExpired();
    return (await _readAll()).where((item) => item.deletedAt == null).toList();
  }

  Future<List<Item>> readDeleted() async {
    await _purgeExpired();
    return (await _readAll()).where((item) => item.deletedAt != null).toList();
  }

  Future<void> add(Item item) async {
    final items = await _readAll();
    await _writeAll([item, ...items]);
  }

  Future<void> update(Item updated) async {
    final items = await _readAll();
    final index = items.indexWhere((item) => item.id == updated.id);
    if (index == -1) throw ApiException('Report no longer exists.');

    final previous = items[index];
    items[index] = updated;
    await _writeAll(items);

    // Remove an old locally stored image only after the updated report saves.
    if (previous.image != null &&
        previous.image != updated.image &&
        !previous.hasNetworkImage &&
        isLocalFilePath(previous.image)) {
      await deleteLocalFile(previous.image!);
    }
  }

  Future<void> delete(String id) async {
    final items = await _readAll();
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1 || items[index].deletedAt != null) return;
    items[index] = items[index].copyWith(deletedAt: DateTime.now());
    await _writeAll(items);
  }

  Future<void> restore(String id) async {
    final items = await _readAll();
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1 || items[index].deletedAt == null) return;
    items[index] = items[index].copyWith(clearDeletedAt: true);
    await _writeAll(items);
  }

  Future<void> permanentlyDelete(String id) async {
    final items = await _readAll();
    final target = items.where((item) => item.id == id).firstOrNull;
    if (target == null) return;
    items.removeWhere((item) => item.id == id);
    await _writeAll(items);
    await _removeStoredImage(target);
  }

  Future<void> toggleResolved(String id) async {
    final items = await _readAll();
    final updated = items
        .map((i) => i.id == id ? i.copyWith(resolved: !i.resolved) : i)
        .toList();
    await _writeAll(updated);
  }

  static bool isDataUri(String? value) =>
      value != null && value.startsWith('data:');

  static bool isLocalFilePath(String? value) =>
      value != null &&
      value.isNotEmpty &&
      !isDataUri(value) &&
      !value.startsWith('http');

  static Uint8List decodeDataUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.data == null) {
      throw const FormatException('Invalid image data URI.');
    }
    return uri.data!.contentAsBytes();
  }

  /// Saves the selected photo so it can be displayed reliably across mobile and
  /// web builds. On web, browser-managed files are kept as data URLs instead of
  /// local file paths because `dart:io` File APIs are unavailable there.
  Future<String> savePickedImage(XFile file) async {
    final bytes = await file.readAsBytes();

    if (kIsWeb) {
      final mimeType = file.mimeType ?? 'image/jpeg';
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final fileName = file.name.isNotEmpty
        ? file.name
        : 'image_${DateTime.now().microsecondsSinceEpoch}.jpg';
    return saveLocalFile(bytes, fileName);
  }
}
