import 'package:dailyatt/homepage.dart';
import 'package:dailyatt/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rightshiftController;
  late AnimationController _solutionsController;
  late AnimationController _poweredController;

  late Animation<Offset> _rightshiftSlide;
  late Animation<double> _rightshiftFade;

  late Animation<Offset> _solutionsSlide;
  late Animation<double> _solutionsFade;

  late Animation<double> _poweredFade;

  @override
  void initState() {
    super.initState();

    _rightshiftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _solutionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _poweredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rightshiftSlide =
        Tween<Offset>(begin: const Offset(0, 0.7), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _rightshiftController,
            curve: Curves.easeOutCubic,
          ),
        );

    _rightshiftFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rightshiftController, curve: Curves.easeIn),
    );

    _solutionsSlide =
        Tween<Offset>(begin: const Offset(0, 0.7), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _solutionsController,
            curve: Curves.easeOutCubic,
          ),
        );

    _solutionsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _solutionsController, curve: Curves.easeIn),
    );

    _poweredFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _poweredController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _rightshiftController.forward();

    await Future.delayed(const Duration(milliseconds: 250));
    await _solutionsController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    await _poweredController.forward();

    // Check admin status while waiting for the rest of the delay
    final prefs = await SharedPreferences.getInstance();
    final bool isAdminRegistered = prefs.containsKey('admin_name');

    // Ensure total time is at least 3 seconds or animations complete
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isAdminRegistered ? const Homepage() : const RegisterScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rightshiftController.dispose();
    _solutionsController.dispose();
    _poweredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        /// 🔥 Brand Gradient (matches arrow colors)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xffFF7E00),
              Color(0xffFDBB2D),
              Color(0xff1FA2FF),
              Color(0xff0052D4),
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              /// ✅ CIRCLE LOGO CONTAINER
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      spreadRadius: 4,
                      color: Colors.black.withOpacity(0.25),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/logo.jpeg",
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              /// RIGHTSHIFT
              SlideTransition(
                position: _rightshiftSlide,
                child: FadeTransition(
                  opacity: _rightshiftFade,
                  child: const Text(
                    "Rightshift",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 2, 17, 124),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              /// SOLUTIONS (delayed)
              SlideTransition(
                position: _solutionsSlide,
                child: FadeTransition(
                  opacity: _solutionsFade,
                  child: const Text(
                    "Solutions",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 232, 71, 18),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              /// POWERED BY BOTTOM
              FadeTransition(
                opacity: _poweredFade,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Text(
                    "Powered by Rightshift Solutions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


