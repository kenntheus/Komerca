import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../../../core/network/api_client.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final res = await dio.get('/categories');
  final data = res.data as List<dynamic>;
  return data
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList();
});
