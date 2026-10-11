enum ItemType { lost, found }

const List<String> kCategories = [
  'Electronics',
  'Bags',
  'Books',
  'Clothing',
  'ID & Cards',
  'Keys',
  'Accessories',
  'Other',
];

class Item {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final ItemType type;

  /// Either a local file path (photo taken/picked by the user)
  /// or an http(s) URL (items that came from the API).
  final String? image;
  final String ownerId;
  final String ownerName;
  final String contact;
  final DateTime createdAt;
  final bool resolved;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.type,
    this.image,
    required this.ownerId,
    required this.ownerName,
    required this.contact,
    required this.createdAt,
    this.resolved = false,
  });

  bool get isLost => type == ItemType.lost;
  bool get hasNetworkImage => image != null && image!.startsWith('http');

  Item copyWith({bool? resolved}) => Item(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
        type: type,
        image: image,
        ownerId: ownerId,
        ownerName: ownerName,
        contact: contact,
        createdAt: createdAt,
        resolved: resolved ?? this.resolved,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'type': type.name,
        'image': image,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'contact': contact,
        'createdAt': createdAt.toIso8601String(),
        'resolved': resolved,
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] ?? '') as String,
        category: (j['category'] ?? 'Other') as String,
        location: (j['location'] ?? '') as String,
        type: (j['type'] == 'found') ? ItemType.found : ItemType.lost,
        image: j['image'] as String?,
        ownerId: (j['ownerId'] ?? '') as String,
        ownerName: (j['ownerName'] ?? 'Unknown') as String,
        contact: (j['contact'] ?? '') as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        resolved: (j['resolved'] ?? false) as bool,
      );
}
