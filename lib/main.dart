import 'package:flutter/material.dart';
import 'screens/widgets/splash_screen.dart';
import 'screens/widgets//login_screen.dart';

void main() {
  runApp(const SmartISP());
}

class SmartISP extends StatelessWidget {
  const SmartISP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes debug banner
      title: 'SMART ISP',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Start at Splash Screen
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}