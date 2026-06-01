import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double progress = 0.0;

  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  Timer? _progressTimer;

  static const Color brandGreen = Color(0xFF8CC63F);

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: .97, end: 1.03).animate(_logoController);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(_textController);

    _textController.forward();

    startLoading();
  }

  void startLoading() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        progress += 0.01;
      });

      if (progress >= 1) {
        timer.cancel();
      }
    });

    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      bool seenOnboarding = prefs.getBool('onboarding_done') ?? false;

      bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      String savedEmail = prefs.getString('user_email') ?? '';

      if (!mounted) return;

      Widget nextScreen;

      if (!seenOnboarding) {
        nextScreen = const OnboardingScreen();
      } else if (isLoggedIn) {
        nextScreen = HomeScreen(email: savedEmail);
      } else {
        nextScreen = const LoginScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();

    _logoController.dispose();
    _textController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.center,
            colors: [Color(0xFF0A1208), Color(0xFF111C0D), Color(0xFF020402)],
          ),
        ),

        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset("assets/logo.png", width: 190.w),
                  );
                },
              ),

              SizedBox(height: 35.h),
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      "SMART AI ATTENDANCE",
                      style: TextStyle(
                        color: brandGreen,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.w,
                      ),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6.h,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(brandGreen),
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
