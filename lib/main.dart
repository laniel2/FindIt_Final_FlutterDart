import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/auth_service.dart';
import 'screens/add_item_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use real paths on the web so Vercel can reload routes such as /home.
  if (kIsWeb) usePathUrlStrategy();
  // Load the saved session before a refreshed deep link builds its screen.
  await AuthService.instance.init();
  final prefs = await SharedPreferences.getInstance();
  final browserPath = Uri.base.path;
  final savedRoute = prefs.getString(_LastRouteObserver.storageKey);
  final startRoute = browserPath == '/' &&
          savedRoute != null &&
          savedRoute != '/'
      ? savedRoute
      : browserPath;
  runApp(FindItApp(initialRoute: startRoute));
}

class FindItApp extends StatelessWidget {
  const FindItApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final routes = <String, WidgetBuilder>{
      '/': (_) => const SplashScreen(),
      '/login': (_) => const LoginScreen(),
      '/register': (_) => const RegisterScreen(),
      '/profile-setup': (_) => const ProfileSetupScreen(),
      '/home': (_) => const HomeShell(),
      '/add-item': (_) => const AddItemScreen(),
    };

    return MaterialApp(
      title: 'FindIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: routes,
      navigatorObservers: [_LastRouteObserver()],
      // Don't create the splash route underneath a refreshed deep link.
      // Its session redirect would otherwise replace the requested page.
      onGenerateInitialRoutes: (initialRoute) {
        final route = routes[initialRoute] == null ? '/' : initialRoute;
        return [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: route),
            builder: routes[route]!,
          ),
        ];
      },
    );
  }
}

/// Keeps the last named screen so a browser reload can recover if the server
/// or browser starts the Flutter app at `/` instead of the current path.
class _LastRouteObserver extends NavigatorObserver {
  static const storageKey = 'last_named_route';

  void _save(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name == '/') return;
    SharedPreferences.getInstance().then((prefs) => prefs.setString(storageKey, name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _save(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _save(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _save(previousRoute);
    super.didPop(route, previousRoute);
  }
}
