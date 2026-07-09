import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/preferences_handler.dart';
import 'views/auth/splash_screen.dart';

// Global ValueNotifier to listen for theme changes
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesHandler.init();
  
  // Load saved theme preference
  final savedTheme = PreferencesHandler.themeMode;
  themeNotifier.value = savedTheme == "dark" ? ThemeMode.dark : ThemeMode.light;
  
  // Run the app immediately
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
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
          home: const SplashScreen(),
        );
      },
    );
  }
}
