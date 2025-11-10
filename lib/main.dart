import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/favorites_screen.dart'; // add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env'); // ensure env is accessible as asset
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  await Hive.openBox('user'); // for auth
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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Movie App',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
          routes: {
            '/favorites': (_) => const FavoritesScreen(),
          },
        ),
      ),
    );
  }
}