import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeSlideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.face_retouching_natural,
      'title': "Smart AI Attendance",
      'desc':
          "Mark attendance instantly with AI-powered face recognition. No more manual entries.",
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': "Leave & Reports",
      'desc':
          "Apply for leaves and view detailed attendance analytics right from your phone.",
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': "Stay Notified",
      'desc':
          "Get real-time alerts, calendar updates, and never miss an important attendance event.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut),
        );

    _fadeSlideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeSlideController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _fadeSlideController.reset();
    _fadeSlideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0F),
      body: Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_done', true);

                  if (!mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: const Color(0xFF8CC63F),
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with glow
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x448CC63F),
                              blurRadius: 40.r,
                              spreadRadius: 10.r,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 120.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 40.h),

                      Container(
                        width: 110.w,
                        height: 110.h,
                        decoration: BoxDecoration(
                          color: const Color(0x1A8CC63F),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x448CC63F),
                            width: 1.5.w,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 52.sp,
                            color: const Color(0xFF8CC63F),
                          ),
                        ),
                      ),
                      SizedBox(height: 36.h),

                      Text(
                        slide['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 14.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          slide['desc'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            color: const Color(0xFF81C784),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.h, left: 28.w, right: 28.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_slides.length, (index) {
                      bool isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: isActive ? 22.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF8CC63F)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    }),
                  ),

                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 26.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
