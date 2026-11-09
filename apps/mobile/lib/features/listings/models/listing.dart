import 'category.dart';

class ListingPhoto {
  final String url;
  const ListingPhoto({required this.url});

  factory ListingPhoto.fromJson(Map<String, dynamic> json) =>
      ListingPhoto(url: json['url'] as String);
}

class ListingSeller {
  final String id;
  final String name;
  final String? avatarUrl;
  final int completedDealCount;

  const ListingSeller({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.completedDealCount,
  });

  factory ListingSeller.fromJson(Map<String, dynamic> json) => ListingSeller(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        completedDealCount: json['completedDealCount'] as int? ?? 0,
      );
}

class Listing {
  final String id;
  final String title;
  final double price;
  final String condition;
  final String city;
  final String status;
  final DateTime createdAt;
  final int viewCount;
  final String? checkLevel;
  final List<ListingPhoto> photos;
  final ListingSeller? seller;
  final Category? category;
  final String? description;
  final Map<String, dynamic>? attributes;
  final String? sellerId;
  final String? categoryId;

  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.condition,
    required this.city,
    required this.status,
    required this.createdAt,
    required this.viewCount,
    this.checkLevel,
    required this.photos,
    this.seller,
    this.category,
    this.description,
    this.attributes,
    this.sellerId,
    this.categoryId,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    final photosJson = json['photos'] as List? ?? [];
    final photos = photosJson
        .map((p) => ListingPhoto.fromJson(p as Map<String, dynamic>))
        .toList();

    final sellerJson = json['seller'] as Map<String, dynamic>?;
    final categoryJson = json['category'] as Map<String, dynamic>?;

    return Listing(
      id: json['id'] as String,
      title: json['title'] as String,
      price: double.parse((json['price'] ?? '0').toString()),
      condition: json['condition'] as String,
      city: json['city'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      viewCount: json['viewCount'] as int? ?? 0,
      checkLevel: json['checkLevel'] as String?,
      photos: photos,
      seller: sellerJson != null ? ListingSeller.fromJson(sellerJson) : null,
      category:
          categoryJson != null ? Category.fromJson(categoryJson) : null,
      description: json['description'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
      sellerId: json['sellerId'] as String?,
      categoryId: json['categoryId'] as String?,
    );
  }
}

String conditionLabel(String condition) {
  switch (condition) {
    case 'NEW':
      return 'New';
    case 'LIKE_NEW':
      return 'Like New';
    case 'GOOD':
      return 'Good';
    case 'FAIR':
      return 'Fair';
    case 'FOR_PARTS':
      return 'For Parts';
    default:
      return condition;
  }
}

String formatPrice(double price) {
  if (price >= 1000) {
    final thousands = price / 1000;
    if (thousands == thousands.truncate()) {
      return '${thousands.truncate()}K';
    }
    return '${thousands.toStringAsFixed(1)}K';
  }
  return price.toStringAsFixed(0);
}
