import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool hidePass = true;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
        );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Email and password are required');
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.login(email, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', email);

      if (!mounted) return;

      _showSnack('Login successful!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0F),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0x22388E3C), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.h),
                          Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1B5E20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x5533691E),
                                  blurRadius: 30.r,
                                  spreadRadius: 5.r,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Image.asset('assets/logo.png'),
                            ),
                          ),

                          SizedBox(height: 20.h),

                          Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 40.h),

                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: const Color(0x2881C784),
                                width: 1.w,
                              ),
                            ),
                            child: Column(
                              children: [
                                _field(
                                  'Email Address',
                                  Icons.email,
                                  controller: emailController,
                                ),
                                SizedBox(height: 25.h),
                                _field(
                                  'Password',
                                  Icons.lock,
                                  controller: passwordController,
                                  isPass: true,
                                  hidden: hidePass,
                                  toggle: () =>
                                      setState(() => hidePass = !hidePass),
                                ),
                                SizedBox(height: 30.h),
                                GestureDetector(
                                  onTap: isLoading ? null : loginUser,
                                  child: Container(
                                    height: 55.h,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.r),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2E7D32),
                                          Color(0xFF66BB6A),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: isLoading
                                          ? CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.w,
                                            )
                                          : AnimatedBuilder(
                                              animation: _shimmerController,
                                              builder: (context, child) {
                                                return ShaderMask(
                                                  shaderCallback: (bounds) {
                                                    return LinearGradient(
                                                      colors: const [
                                                        Colors.white,
                                                        Colors.white54,
                                                        Colors.white,
                                                      ],
                                                      stops: [
                                                        _shimmerController
                                                                .value -
                                                            0.3,
                                                        _shimmerController
                                                            .value,
                                                        _shimmerController
                                                                .value +
                                                            0.3,
                                                      ],
                                                      begin: const Alignment(
                                                        -1,
                                                        -0.5,
                                                      ),
                                                      end: const Alignment(
                                                        1,
                                                        0.5,
                                                      ),
                                                      tileMode: TileMode.clamp,
                                                    ).createShader(bounds);
                                                  },
                                                  child: Text(
                                                    'Login',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String hint,
    IconData icon, {
    bool isPass = false,
    bool hidden = false,
    VoidCallback? toggle,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass ? hidden : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x8881C784)),
        prefixIcon: Icon(icon, color: const Color(0xFF81C784)),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  hidden ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF81C784),
                ),
                onPressed: toggle,
              )
            : null,
        filled: true,
        fillColor: const Color(0x1A81C784),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: BorderSide(color: const Color(0xFF66BB6A), width: 1.5.w),
        ),
      ),
    );
  }
}
