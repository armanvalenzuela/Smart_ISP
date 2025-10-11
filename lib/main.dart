import 'package:flutter/material.dart';
import 'screens/widgets/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';

void main(){
  runApp(const SmartISP());
}

class SmartISP extends StatelessWidget {
  const SmartISP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMART ISP',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: Colors.white,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue,
          selectionColor: Colors.blue.withOpacity(0.35),
          selectionHandleColor: Colors.blue,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
