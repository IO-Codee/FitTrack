import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/workout_detail_screen.dart';
import '../screens/tracking/tracking_screen.dart';
import '../screens/tracking/active_workout_screen.dart';
import '../screens/plan/plan_screen.dart';
import '../screens/plan/plan_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) => GoRouter(
        initialLocation: '/catalog',
        redirect: (context, state) {
          final isAuth = auth.isAuthenticated;
          final onAuth = state.matchedLocation == '/login' ||
              state.matchedLocation == '/register';
          if (!isAuth && !onAuth) return '/login';
          if (isAuth && onAuth) return '/home';
          return null;
        },
        refreshListenable: auth,
        routes: [
          // Auth
          GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          GoRoute(
              path: '/register', builder: (_, __) => const RegisterScreen()),

          // Main shell with bottom nav
          ShellRoute(
            builder: (context, state, child) => MainShell(child: child),
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
              GoRoute(
                path: '/catalog',
                builder: (_, __) => const CatalogScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => WorkoutDetailScreen(
                      workoutId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
              GoRoute(
                  path: '/tracking',
                  builder: (_, __) => const TrackingScreen()),
              GoRoute(
                  path: '/tracking/active/:id',
                  builder: (_, state) => ActiveWorkoutScreen(
                      workoutId: int.parse(state.pathParameters['id']!))),
              GoRoute(
                path: '/plans',
                builder: (_, __) => const PlanScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => PlanDetailScreen(
                      planId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
              GoRoute(
                  path: '/profile', builder: (_, __) => const ProfileScreen()),
              GoRoute(
                  path: '/profile/edit',
                  builder: (_, __) => const EditProfileScreen()),
            ],
          ),
        ],
        errorBuilder: (_, state) => Scaffold(
          body: Center(child: Text('Сторінку не знайдено: ${state.error}')),
        ),
      );
}

// ─── Main shell with bottom navigation ────────────────────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    ('/home', Icons.home_outlined, Icons.home, 'Головна'),
    (
      '/catalog',
      Icons.fitness_center_outlined,
      Icons.fitness_center,
      'Каталог'
    ),
    ('/tracking', Icons.bar_chart_outlined, Icons.bar_chart, 'Прогрес'),
    ('/plans', Icons.list_alt_outlined, Icons.list_alt, 'Плани'),
    ('/profile', Icons.person_outline, Icons.person, 'Профіль'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.$2),
                  selectedIcon: Icon(t.$3),
                  label: t.$4,
                ))
            .toList(),
      ),
    );
  }
}
