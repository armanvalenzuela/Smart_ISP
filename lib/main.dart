import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/widgets/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

//Adjust ur phone size here
  WindowOptions windowOptions = const WindowOptions(
    size: Size(390, 844), 
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();

    // Lock the window size
    await windowManager.setResizable(false);
    await windowManager.setMaximumSize(const Size(390, 844));
    await windowManager.setMinimumSize(const Size(390, 844));
  });

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
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
