import 'package:findit/models/item.dart';
import 'package:findit/widgets/type_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TypeBadge shows LOST / FOUND / RESOLVED', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        TypeBadge(type: ItemType.lost),
        TypeBadge(type: ItemType.found),
        TypeBadge(type: ItemType.found, resolved: true),
      ]),
    ));
    expect(find.text('LOST'), findsOneWidget);
    expect(find.text('FOUND'), findsOneWidget);
    expect(find.text('RESOLVED'), findsOneWidget);
  });

  test('Item JSON round trip', () {
    final item = Item(
      id: '1',
      title: 'Umbrella',
      description: 'Black',
      category: 'Other',
      location: 'Library',
      type: ItemType.found,
      ownerId: 'u1',
      ownerName: 'Ana',
      contact: '0912',
      createdAt: DateTime(2026, 10, 1),
    );
    final copy = Item.fromJson(item.toJson());
    expect(copy.title, 'Umbrella');
    expect(copy.type, ItemType.found);
  });
}
