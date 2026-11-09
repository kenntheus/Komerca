class Category {
  final String id;
  final String slug;
  final String name;
  final String iconName;
  final int sortOrder;

  const Category({
    required this.id,
    required this.slug,
    required this.name,
    required this.iconName,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
