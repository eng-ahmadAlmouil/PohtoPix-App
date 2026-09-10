import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _startApp();
  }

  Future<void> _startApp() async {
    // Time Splash Screen
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002623),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO IMAGE
            Image.asset(
              "assets/images/iconeYellow.png",
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 1),
            const Text(
              "PhotoPix",
              style: TextStyle(
                fontSize: 35,
                fontFamily: "Angkor",
                fontWeight: FontWeight.bold,
                color: Color(0xFFB9A779),
              ),
            ),

            const SizedBox(height: 150),

            const CircularProgressIndicator(color: Color(0xFF988561)),
          ],
        ),
      ),
    );
  }
}
