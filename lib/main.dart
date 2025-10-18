import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  String? _collectorName;
  String? _collectorTown;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await _showDialog(
        'No Internet Connection',
        'Please check your network and try again.',
      );
      SystemNavigator.pop();
      return;
    }

    await _requestLocationPermission();

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _isLoggedIn = prefs.getBool('loggedIn') ?? false;
      _collectorName = prefs.getString('collectorName');
      _collectorTown = prefs.getString('collectorTown');
      _isLoading = false;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      await _showDialog(
        'Location Permission Required',
        'Location permission is required for this app to function properly.',
      );
    }
  }

  Future<void> _showDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _lightBlueTheme,
        home: const SplashScreen(),
      );
    }

    return MaterialApp(
      title: 'Collector App',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightBlueTheme,
      home: _isLoggedIn && _collectorName != null && _collectorTown != null
          ? HomeScreen(
              collectorName: _collectorName!,
              collectorTown: _collectorTown!,
            )
          : const LoginScreen(),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {}
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Splashscreen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Text(
              'SMART ISP',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Light Theme
final ThemeData _lightBlueTheme = ThemeData(
  primaryColor: Colors.blue,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.blue,
    accentColor: Colors.blueAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.blue),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.black),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.blue,
    textColor: Colors.black,
  ),
  // Apply Poppins font across the app for light theme
  textTheme: GoogleFonts.poppinsTextTheme(),
  primaryTextTheme: GoogleFonts.poppinsTextTheme(),
);

// Dark Theme
final ThemeData _darkTheme = ThemeData.dark().copyWith(
  colorScheme: const ColorScheme.dark(
    primary: Colors.blue,
    secondary: Colors.blueAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black87,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blueAccent, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.white),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.lightBlueAccent,
    textColor: Colors.white,
  ),
  // Apply Poppins font across the app for dark theme
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  primaryTextTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().primaryTextTheme),
);
