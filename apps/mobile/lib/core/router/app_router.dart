import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/listings/screens/browse_screen.dart';
import '../../features/listings/screens/category_picker_screen.dart';
import '../../features/listings/screens/create_listing_screen.dart';
import '../../features/listings/screens/draft_listing_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/listings/screens/manage_listings_screen.dart';
import '../../features/listings/screens/search_results_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

// Routes that require authentication
const _authRequired = {'/sell/create', '/sell/details', '/sell/manage'};

class _RouterChangeNotifier extends ChangeNotifier {
  _RouterChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _RouterChangeNotifier(ref);
  final router = GoRouter(
    refreshListenable: listenable,
    initialLocation: '/browse',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      // Guard auth-required routes
      if (_authRequired.any((r) => loc.startsWith(r))) {
        if (!auth.isLoggedIn) return '/auth/phone';
      }

      // Redirect logged-in users away from auth screens
      if (auth.isLoggedIn && loc.startsWith('/auth')) {
        return '/browse';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/browse',
            builder: (_, __) => const BrowseScreen(),
          ),
          GoRoute(
            path: '/sell/manage',
            builder: (_, __) => const ManageListingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/browse/search',
        builder: (_, state) {
          final q = state.uri.queryParameters['q'] ?? '';
          return SearchResultsScreen(query: q);
        },
      ),
      GoRoute(
        path: '/listings/:id',
        builder: (_, state) =>
            ListingDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (_, __) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) =>
            OtpVerificationScreen(phone: state.extra as String),
      ),
      GoRoute(
        path: '/sell/create',
        builder: (_, __) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/sell/details',
        builder: (_, state) =>
            DraftListingScreen(photos: state.extra as List<dynamic>?),
      ),
      GoRoute(
        path: '/sell/categories',
        builder: (_, __) => const CategoryPickerScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    listenable.dispose();
    router.dispose();
  });
  return router;
});

class _AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const _AppShell({required this.location, required this.child});

  int get _currentIndex {
    if (location.startsWith('/sell')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/browse');
              case 1:
                context.go('/sell/manage');
              case 2:
                context.go('/profile');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Browse',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Sell',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      );
}
