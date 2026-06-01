import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<String, dynamic>? calendarData;
  bool isLoading = true;
  String? errorMsg;
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final data = await ApiService.getCalendar(now.month, now.year);
      setState(() {
        calendarData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat('MMM yyyy').format(now);

    final stats = calendarData?['stats'] ?? {};
    final attRate = stats['attendance_rate'] ?? "--";
    final avgCheckIn = stats['avg_check_in'] ?? "--";
    final daysAbsent = stats['days_absent'] ?? "--";
    final leaveDays = stats['leave_days'] ?? "--";

    final days = calendarData?['days'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF031B0F),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    "Calendar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                )
              else if (errorMsg != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMsg!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        TextButton(
                          onPressed: _loadCalendar,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F2E1C), Color(0xFF0A1F15)],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Personal Calendar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                          Text(
                            monthYear,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),
                      GridView.builder(
                        shrinkWrap: true,
                        itemCount: DateTime(now.year, now.month + 1, 0).day,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 10.h,
                          crossAxisSpacing: 10.w,
                        ),
                        itemBuilder: (context, index) {
                          int day = index + 1;

                          String status = 'none';
                          if (days is List) {
                            for (var d in days) {
                              if (d['day'] == day ||
                                  (d['date'] != null &&
                                      d['date'].toString().endsWith(
                                        '-${day.toString().padLeft(2, '0')}',
                                      ))) {
                                status = d['status'] ?? 'none';
                                break;
                              }
                            }
                          }

                          Color bgCol = Colors.transparent;
                          Color txtCol = Colors.white;
                          if (status == 'present') {
                            bgCol = Colors.green.withOpacity(0.3);
                            txtCol = Colors.green;
                          } else if (status == 'absent') {
                            bgCol = Colors.red.withOpacity(0.3);
                            txtCol = Colors.red;
                          } else if (status == 'leave') {
                            bgCol = Colors.orange.withOpacity(0.3);
                            txtCol = Colors.orange;
                          } else {
                            if (day == 24 && days.isEmpty) {
                              bgCol = Colors.green.withOpacity(0.3);
                              txtCol = Colors.green;
                            }
                          }

                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgCol,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "$day",
                              style: TextStyle(color: txtCol),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 10.h),

                      const Text(
                        "Present • Absent • Leave",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15.w,
                    mainAxisSpacing: 15.h,
                    children: [
                      StatCard(
                        title: "Attendance Rate",
                        value: attRate.toString(),
                      ),
                      StatCard(
                        title: "Avg Check-In",
                        value: avgCheckIn.toString(),
                      ),
                      StatCard(
                        title: "Days Absent",
                        value: daysAbsent.toString(),
                      ),
                      StatCard(
                        title: "Leave Days",
                        value: leaveDays.toString(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, this.value = "--"});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2E1C), Color(0xFF0A1F15)],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 20.sp),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
