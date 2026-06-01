import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryGreen = Color(0xFF8CC63F);
  static const Color bgGreen = Color(0xFF0B1408);

  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? errorMsg;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final data = await ApiService.getProfile();
      setState(() {
        profileData = data;
        nameController.text = data['full_name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);
    try {
      await ApiService.updateProfile(
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: 48.w),
                ],
              ),

              SizedBox(height: 20.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primaryGreen, Color(0xFFA5D84A)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 10.w,
                    child: Container(
                      height: 18.w,
                      width: 18.w,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30.h),
              if (isLoading)
                const CircularProgressIndicator(color: primaryGreen)
              else if (errorMsg != null)
                Column(
                  children: [
                    Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else ...[
                _infoTile('Email', profileData?['email'] ?? '-', Icons.email),
                SizedBox(height: 12.h),

                _editField('Full Name', nameController, Icons.person),
                SizedBox(height: 12.h),

                _editField('Phone', phoneController, Icons.phone),
                SizedBox(height: 12.h),

                if (profileData?['organization'] != null)
                  _infoTile(
                    'Organization',
                    profileData!['organization'],
                    Icons.business,
                  ),
                if (profileData?['role'] != null) ...[
                  SizedBox(height: 12.h),
                  _infoTile('Role', profileData!['role'], Icons.badge),
                ],

                SizedBox(height: 30.h),

                GestureDetector(
                  onTap: isSaving ? null : _saveProfile,
                  child: Container(
                    height: 50.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.r),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                      ),
                    ),
                    child: Center(
                      child: isSaving
                          ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.w,
                            )
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0x288CC63F)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 20.sp),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white38, fontSize: 11.sp),
              ),
              Text(
                value,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8CC63F)),
        prefixIcon: Icon(icon, color: const Color(0xFF8CC63F)),
        filled: true,
        fillColor: const Color(0x1A8CC63F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: const Color(0xFF66BB6A), width: 1.5.w),
        ),
      ),
    );
  }
}
