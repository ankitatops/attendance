import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'analytics_report_screen.dart';
import 'calendar_screen.dart';
import 'leave_request_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? profileData;
  Map<String, dynamic>? analyticsData;
  int unreadCount = 0;
  List<dynamic> notificationsList = [];
  bool isLoading = true;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    try {
      final futures = await Future.wait([
        ApiService.getProfile(),
        ApiService.getUnreadCount(),
        ApiService.getNotifications(filter: 'all'),
      ]);
      setState(() {
        profileData = futures[0];
        final unread = futures[1];
        unreadCount = unread['count'] ?? unread['unread_count'] ?? 0;
        final notifs = futures[2];
        notificationsList = notifs['results'] ?? notifs['notifications'] ?? [];
      });

      try {
        final analytics = await ApiService.getAnalytics(months: 1);
        setState(() => analyticsData = analytics);
      } catch (e) {
        debugPrint("Analytics error (ignoring): $e");
      }
    } catch (e) {
      debugPrint("Error loading dashboard: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String getName() {
    if (profileData?['full_name'] != null &&
        profileData!['full_name'].toString().isNotEmpty) {
      return profileData!['full_name'];
    }
    if (widget.email.isEmpty) return "User";
    return widget.email.split("@")[0];
  }

  String getDate() => DateFormat("EEEE, dd MMM yyyy").format(DateTime.now());

  String getTime() => DateFormat("hh:mm a").format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final name = getName();
    final dist = analyticsData?['distribution'] ?? {};
    final present = dist['present'] ?? 0;
    final total = dist['total_days'] ?? 1;
    final attPct = total > 0
        ? ((present / total) * 100).toStringAsFixed(1)
        : (analyticsData?['attendance_percentage'] ?? 0).toString();

    final semPct = attPct;
    final overallPct = attPct;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A09),
      bottomNavigationBar: Container(
        height: 72.h,
        decoration: BoxDecoration(
          color: const Color(0xFF111C0D),
          border: Border(
            top: BorderSide(color: const Color(0x268CC63F), width: 1.w),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.home_rounded,
              isActive: selectedIndex == 0,
              onTap: () {
                setState(() {
                  selectedIndex = 0;
                });
              },
            ),
            _navItem(
              icon: Icons.bar_chart_rounded,
              isActive: selectedIndex == 1,
              onTap: () {
                setState(() {
                  selectedIndex = 1;
                });
              },
            ),
            _navItem(
              icon: Icons.calendar_month_rounded,
              isActive: selectedIndex == 2,
              onTap: () {
                setState(() {
                  selectedIndex = 2;
                });
              },
            ),
            _navItem(
              icon: Icons.settings_rounded,
              isActive: selectedIndex == 3,
              onTap: () {
                setState(() {
                  selectedIndex = 3;
                });
              },
            ),
          ],
        ),
      ),
      body: selectedIndex == 0
          ? SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: const Color(0xFF8CC63F),
                backgroundColor: const Color(0xFF111C0D),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ).then((_) => _loadDashboardData()),
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.06),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.08),
                                ),
                              ),
                              child: Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x1A8CC63F),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: const Color(0x308CC63F),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22.w,
                                  height: 22.w,
                                  decoration: const BoxDecoration(
                                    color: Color(0x338CC63F),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: const Color(0xFF8CC63F),
                                    size: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            ).then((_) => _loadDashboardData()),
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.06),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.08),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 8.w,
                                      top: 8.h,
                                      child: Container(
                                        width: 8.w,
                                        height: 8.w,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8CC63F),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF0D1A09),
                                            width: 1.5.w,
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
                      SizedBox(height: 22.h),
                      Text(
                        "Hello, $name",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        getDate(),
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3010),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: const Color(0x308CC63F)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x1A8CC63F),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: const Color(0x508CC63F),
                                        ),
                                      ),
                                      child: Text(
                                        "PRESENT TODAY",
                                        style: TextStyle(
                                          color: const Color(0xFF8CC63F),
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8.w,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      getTime(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30.sp,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5.w,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      "Check-in time  ·  On Time",
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 64.w,
                                  height: 64.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A8CC63F),
                                    borderRadius: BorderRadius.circular(18.r),
                                    border: Border.all(
                                      color: const Color(0x408CC63F),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.how_to_reg_rounded,
                                    color: const Color(0xFF8CC63F),
                                    size: 30.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 14.h,
                                horizontal: 10.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.04),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _inlineStat("$attPct%", "This Month"),
                                  _verticalDivider(),
                                  _inlineStat("$semPct%", "Semester"),
                                  _verticalDivider(),
                                  _inlineStat("$overallPct%", "Overall"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 22.h),
                      Text(
                        "Quick Actions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AttendanceReportScreen(),
                                ),
                              ),
                              child: _quickCard(
                                "View Report",
                                "Attendance details",
                                Icons.description_rounded,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LeaveRequestScreen(),
                                ),
                              ),
                              child: _quickCard(
                                "Apply Leave",
                                "Request in few taps",
                                Icons.calendar_month_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 22.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent Activity",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            ),
                            child: Text(
                              "View All",
                              style: TextStyle(
                                color: const Color(0xFF8CC63F),
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      if (isLoading && notificationsList.isEmpty)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8CC63F),
                          ),
                        )
                      else if (notificationsList.isEmpty)
                        Column(
                          children: [
                            _activity(
                              "Checked In",
                              "Today, ${getTime()}",
                              "On Time",
                            ),
                            _activity("Leave Approved", "dd mm yyyy", "1 Day"),
                            _activity("Holiday", "dd mm yyyy", "Notified"),
                          ],
                        )
                      else
                        ...notificationsList.take(3).map((n) {
                          final title =
                              n['title'] ?? n['message'] ?? "Notification";
                          final sub = n['time_ago'] ?? n['created_at'] ?? "";
                          return _activity(title, sub, "Notified");
                        }),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            )
          : selectedIndex == 1
          ? const AnalyticsReportScreen()
          : selectedIndex == 2
          ? const CalendarScreen()
          : const SettingsScreen(),
    );
  }

  static Widget _navItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF8CC63F) : Colors.white30,
            size: 24.sp,
          ),
          SizedBox(height: 5.h),
          if (isActive)
            Container(
              width: 5.w,
              height: 5.w,
              decoration: const BoxDecoration(
                color: Color(0xFF8CC63F),
                shape: BoxShape.circle,
              ),
            )
          else
            SizedBox(height: 5.h),
        ],
      ),
    );
  }

  static Widget _inlineStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: TextStyle(color: Colors.white38, fontSize: 10.sp),
        ),
      ],
    );
  }

  static Widget _verticalDivider() =>
      Container(width: 1.w, height: 30.h, color: Colors.white12);

  static Widget _quickCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0x108CC63F),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0x288CC63F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: const Color(0x228CC63F),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(icon, color: const Color(0xFF8CC63F), size: 18.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white38, fontSize: 9.5.sp),
          ),
        ],
      ),
    );
  }

  static Widget _activity(String title, String sub, String status) {
    Color dotColor, badgeBg, badgeText;
    if (status == "On Time" || status == "Notified" || status == "1 Day") {
      dotColor = const Color(0xFF8CC63F);
      badgeBg = const Color(0x1A8CC63F);
      badgeText = const Color(0xFF8CC63F);
    } else if (status == "Late") {
      dotColor = const Color(0xFFEF5350);
      badgeBg = const Color(0x1AEF5350);
      badgeText = const Color(0xFFEF5350);
    } else {
      dotColor = Colors.white24;
      badgeBg = Colors.white10;
      badgeText = Colors.white54;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  sub,
                  style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: badgeText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
