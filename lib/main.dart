import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/preferences_handler.dart';
import 'auth/auth_manager.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';

// Global ValueNotifier to listen for theme changes
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesHandler.init();
  
  // Load saved theme preference
  final savedTheme = PreferencesHandler.themeMode;
  themeNotifier.value = savedTheme == "light" ? ThemeMode.light : ThemeMode.dark;
  
  // Run the app immediately without blocking on checkSession
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _checkingSession = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    try {
      final isLoggedIn = await AuthManager().checkSession();
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _checkingSession = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _checkingSession = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AbsensiBro PPKD B6',
          themeMode: currentMode,
          // Premium Light Theme Design
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              secondary: Color(0xFF8B7EFE),
              background: Color(0xFFF6F5FA),
              surface: Color(0xFFFFFFFF),
              onBackground: Colors.black87,
              onSurface: Colors.black87,
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F5FA),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF6F5FA),
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          // Premium Dark Theme Design
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              secondary: Color(0xFF8B7EFE),
              background: Color(0xFF0F0C20),
              surface: Color(0xFF201A38),
              onBackground: Colors.white,
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F0C20),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F0C20),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF201A38),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          // Set localization to support Indonesian date formats (e.g. EEEE, d MMMM yyyy)
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('id', 'ID'), // Indonesian
            Locale('en', 'US'), // English
          ],
          home: _checkingSession
              ? Scaffold(
                  backgroundColor: isDark ? const Color(0xFF0F0C20) : const Color(0xFFF6F5FA),
                  body: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B7EFE)),
                  ),
                )
              : (_isLoggedIn ? const DashboardScreen() : const LoginScreen()),
        );
      },
    );
  }
}
