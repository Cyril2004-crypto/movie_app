import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/theme_provider.dart'; // added
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // add this import
import 'screens/favorites_screen.dart'; // add this import
import 'screens/watchlist_screen.dart'; // <-- add import for WatchlistScreen
import 'screens/settings_screen.dart'; // <-- import SettingsScreen
import 'screens/profile_screen.dart'; // <-- import ProfileScreen
import 'screens/explore_screen.dart'; // <-- import ExploreScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env'); // ensure env is accessible as asset
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  await Hive.openBox('user');
  await Hive.openBox('cache');
  await Hive.openBox('watchlist'); // <-- add this
  await Hive.openBox('settings'); // <-- open settings box for theme
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider(apiService: api)),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // theme provider
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProv, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Movie App',
          theme: ThemeData.light().copyWith(primaryColor: Colors.blue),
          darkTheme: ThemeData.dark().copyWith(primaryColor: Colors.blue),
          themeMode: themeProv.mode,
          home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/favorites': (_) => const FavoritesScreen(),
            '/watchlist': (_) => const WatchlistScreen(), // add import and route
            '/settings': (context) => const SettingsScreen(), // <-- add settings route
            '/profile': (_) => const ProfileScreen(),
            '/explore': (_) => const ExploreScreen(),
          },
        ),
      ),
    );
  }
}