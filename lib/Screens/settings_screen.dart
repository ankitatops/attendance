import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'notifiction_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      setState(() => profileData = data);
    } catch (_) {}
  }

  bool attendanceAlert=true;
  bool scanReminder=false;
  bool faceConsent=true;

  static const bg=Color(0xFF0B1408);
  static const card=Color(0xFF111D0D);
  static const green=Color(0xFF8CC63F);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: (){
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            /// PROFILE CARD
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: card,
                borderRadius:
                BorderRadius.circular(22.r),
              ),
              child: Row(
                children: [

                  Container(
                    height:60.w,
                    width:60.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: green,
                        width:2.w,
                      ),
                      color: Colors.black26,
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white38,
                      size:30.sp,
                    ),
                  ),

                  SizedBox(width:15.w),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          profileData?['full_name'] ?? "User",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:20.sp,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        SizedBox(height:6.h),

                        Text(
                          profileData?['email'] ?? "ID: ----",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize:13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                    EdgeInsets.symmetric(
                      horizontal:16.w,
                      vertical:8.h,
                    ),
                    decoration: BoxDecoration(
                      color: green.withOpacity(.18),
                      borderRadius:
                      BorderRadius.circular(30.r),
                    ),
                    child: const Text(
                      "Verified",
                      style: TextStyle(
                        color: green,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height:30.h),

            /// NOTIFICATIONS
            Text(
              "NOTIFICATIONS",
              style: TextStyle(
                color: green,
                letterSpacing:2.w,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height:14.h),

            sectionCard(
              children: [

                switchTile(
                  Icons.calendar_month,
                  "Attendance Alerts",
                  "Notify when attendance is logged",
                  attendanceAlert,
                      (v){
                    setState(() {
                      attendanceAlert=v;
                    });
                  },
                ),

                divider(),

                switchTile(
                  Icons.camera_alt_outlined,
                  "Scan Reminders",
                  "Periodic reminders to scan device",
                  scanReminder,
                      (v){
                    setState(() {
                      scanReminder=v;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height:28.h),

            /// ACCOUNT
            Text(
              "ACCOUNT MANAGEMENT",
              style: TextStyle(
                color: green,
                letterSpacing:2.w,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height:14.h),
            GestureDetector(
              onTap: () async {
                try {
                  await ApiService.logout();
                  NotificationService.stopPolling();
                  NotificationService.clearShownIds();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                }
              },
              child: Container(
                height:58.h,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius:
                  BorderRadius.circular(18.r),
                ),
                child: Center(
                  child: Text(
                    "Sign Out of Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:17.sp,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionCard({
    required List<Widget> children,
  }){
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
        BorderRadius.circular(22.r),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget divider(){
    return Divider(
      color: Colors.white12,
      height:25.h,
    );
  }

  Widget iconBox(IconData icon){
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: green.withOpacity(.15),
        borderRadius:
        BorderRadius.circular(14.r),
      ),
      child: Icon(
        icon,
        color: green,
      ),
    );
  }

  Widget switchTile(
      IconData icon,
      String title,
      String sub,
      bool value,
      Function(bool) onChanged){
    return Row(
      children: [

        iconBox(icon),

        SizedBox(width:14.w),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: Colors.white,
                    fontSize:16.sp,
                    fontWeight:
                    FontWeight.w600),
              ),
              Text(
                sub,
                style: TextStyle(
                    color: Colors.white54,
                    fontSize:12.sp),
              )
            ],
          ),
        ),

        Switch(
          value:value,
          activeColor: green,
          onChanged:onChanged,
        )
      ],
    );
  }

  Widget arrowTile(
      IconData icon,
      String title,
      String sub){
    return Row(
      children: [

        iconBox(icon),

        SizedBox(width:14.w),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: Colors.white,
                    fontSize:16.sp,
                    fontWeight:
                    FontWeight.w600),
              ),
              if(sub.isNotEmpty)
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize:12.sp,
                  ),
                ),
            ],
          ),
        ),

        const Icon(
          Icons.chevron_right,
          color: Colors.white54,
        )
      ],
    );
  }
}