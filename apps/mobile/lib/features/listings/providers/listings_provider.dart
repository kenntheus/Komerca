import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class ListingsFilter {
  final String? q;
  final String? categoryId;
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final String sortBy;
  final int page;
  final int limit;

  const ListingsFilter({
    this.q,
    this.categoryId,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.sortBy = 'newest',
    this.page = 1,
    this.limit = 20,
  });

  ListingsFilter copyWith({
    String? q,
    String? categoryId,
    String? city,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? sortBy,
    int? page,
    int? limit,
    bool clearQ = false,
    bool clearCategoryId = false,
    bool clearCondition = false,
  }) =>
      ListingsFilter(
        q: clearQ ? null : q ?? this.q,
        categoryId:
            clearCategoryId ? null : categoryId ?? this.categoryId,
        city: city ?? this.city,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        condition:
            clearCondition ? null : condition ?? this.condition,
        sortBy: sortBy ?? this.sortBy,
        page: page ?? this.page,
        limit: limit ?? this.limit,
      );

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'sortBy': sortBy, 'page': page, 'limit': limit};
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (city != null && city!.isNotEmpty) params['city'] = city;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (condition != null) params['condition'] = condition;
    return params;
  }

  bool get hasActiveFilters =>
      categoryId != null ||
      minPrice != null ||
      maxPrice != null ||
      condition != null ||
      (city != null && city!.isNotEmpty);
}

final listingsFilterProvider =
    StateProvider<ListingsFilter>((ref) => const ListingsFilter());

final listingsProvider =
    FutureProvider.autoDispose<List<Listing>>((ref) async {
  final filter = ref.watch(listingsFilterProvider);
  final dio = ref.watch(apiClientProvider);
  final res = await dio.get('/listings',
      queryParameters: filter.toQueryParams());
  final data = res.data as List<dynamic>;
  return data
      .map((e) => Listing.fromJson(e as Map<String, dynamic>))
      .toList();
});

final listingDetailProvider =
    FutureProvider.autoDispose.family<Listing, String>((ref, id) async {
  final dio = ref.watch(apiClientProvider);
  final res = await dio.get('/listings/$id');
  return Listing.fromJson(res.data as Map<String, dynamic>);
});

final myListingsProvider =
    FutureProvider.autoDispose<List<Listing>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return [];
  final dio = ref.watch(apiClientProvider);
  final userId = auth.user!.id;
  final res = await dio.get('/users/$userId/listings',
      queryParameters: {'limit': 50, 'sortBy': 'newest'});
  final data = res.data as Map<String, dynamic>;
  return (data['items'] as List<dynamic>)
      .map((e) => Listing.fromJson(e as Map<String, dynamic>))
      .toList();
});
