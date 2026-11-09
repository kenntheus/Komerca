import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komerca/core/network/api_client.dart';
import 'package:komerca/features/auth/providers/auth_provider.dart';
import 'package:komerca/features/listings/models/category.dart';
import 'package:komerca/features/listings/models/listing.dart';
import 'package:komerca/features/listings/providers/categories_provider.dart';
import 'package:komerca/features/listings/providers/listings_provider.dart';
import 'package:komerca/main.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Skip secure storage reads that fail in widget test environment
          authProvider.overrideWith(
            (ref) => AuthNotifier(
              ref.watch(apiClientProvider),
              skipInit: true,
            ),
          ),
          // Return empty data so no real HTTP calls are made
          categoriesProvider.overrideWith((_) async => <Category>[]),
          listingsProvider.overrideWith((_) async => <Listing>[]),
        ],
        child: const KomercaApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(KomercaApp), findsOneWidget);
  });
}
