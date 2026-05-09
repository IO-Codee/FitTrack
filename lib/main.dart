import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database_helper.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/providers.dart';
import 'presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DEF-ST-01 fix: initialize DB with error handling for offline start
  try {
    await DatabaseHelper().database;
  } catch (e) {
    debugPrint('DB init warning: $e');
  }

  runApp(const FitTrackApp());
}

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({super.key});
  @override
  State<FitTrackApp> createState() => FitTrackAppState();
}

class FitTrackAppState extends State<FitTrackApp> {
  // Shared DB instance across all providers
  final _db = DatabaseHelper();
  late final AuthProvider _auth;
  late final WorkoutProvider _workouts;
  late final TrackingProvider _tracking;
  late final PlanProvider _plans;
  late final ProfileProvider _profile;

  // Theme mode — toggled via ProfileScreen (BRL-8)
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider(db: _db);
    _workouts = WorkoutProvider(db: _db);
    _tracking = TrackingProvider(db: _db);
    _plans = PlanProvider(db: _db);
    _profile = ProfileProvider(db: _db);
  }

  void setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<WorkoutProvider>.value(value: _workouts),
        ChangeNotifierProvider<TrackingProvider>.value(value: _tracking),
        ChangeNotifierProvider<PlanProvider>.value(value: _plans),
        ChangeNotifierProvider<ProfileProvider>.value(value: _profile),
      ],
      child: Builder(builder: (context) {
        final router = AppRouter.create(context.read<AuthProvider>());
        return MaterialApp.router(
          title: 'FitTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeMode, // BRL-8: light/dark support
          routerConfig: router,
        );
      }),
    );
  }
}
