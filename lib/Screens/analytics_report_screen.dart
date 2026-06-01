import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class AnalyticsReportScreen extends StatefulWidget {
  const AnalyticsReportScreen({super.key});

  @override
  State<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends State<AnalyticsReportScreen> {
  Map<String, dynamic>? analyticsData;
  bool isLoading = true;
  String? errorMsg;
  int selectedMonths = 5;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final data = await ApiService.getAnalytics(
        months: selectedMonths,
      );

      print("Analytics Response => $data");

      setState(() {
        analyticsData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        isLoading = false;
      });

      print("Analytics Error => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111C0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics Report',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          DropdownButton<int>(
            value: selectedMonths,
            dropdownColor: const Color(0xFF1A2E12),
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: [3, 5, 6, 12]
                .map(
                  (m) => DropdownMenuItem(value: m, child: Text('$m months')),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedMonths = val);
                _loadAnalytics();
              }
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: isLoading
            ? Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60.h),
                  child: const CircularProgressIndicator(
                    color: Color(0xFF8CC63F),
                  ),
                ),
              )
            : errorMsg != null
            ? _errorWidget()
            : _buildContent(),
      ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(errorMsg!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final data = analyticsData ?? {};
    final attendancePct = (data['attendance_percentage'] ?? 0).toString();
    final punctualityPct = (data['punctuality_percentage'] ?? 0).toString();
    final dist = data['distribution'] ?? {};
    final presentDays = (dist['present'] ?? 0).toString();
    final absentDays = (dist['absent'] ?? 0).toString();
    final lateDays = (dist['late'] ?? 0).toString();
    final totalDays = (dist['total_days'] ?? 0).toString();
    final monthlyTrends = data['monthly_trends'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _card(
                'ATTENDANCE',
                '$attendancePct%',
                '',
                const Color(0xFF8CC63F),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _card(
                'PUNCTUALITY',
                '$punctualityPct%',
                '',
                const Color(0xFF8CC63F),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        _sectionTitle('Details'),
        SizedBox(height: 10.h),

        Row(
          children: [
            Expanded(
              child: _statTile(
                'Present',
                presentDays,
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _statTile(
                'Absent',
                absentDays,
                Icons.cancel_outlined,
                Colors.redAccent,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _statTile('Late', lateDays, Icons.schedule, Colors.orange),
            ),
          ],
        ),

        SizedBox(height: 16.h),
        _statTile(
          'Total Working Days',
          totalDays,
          Icons.calendar_today,
          const Color(0xFF8CC63F),
        ),
        if (monthlyTrends.isNotEmpty) ...[
          SizedBox(height: 20.h),
          _sectionTitle('Monthly Trends'),
          SizedBox(height: 10.h),
          ...monthlyTrends.map((m) => _monthRow(m)),
        ],
      ],
    );
  }

  Widget _monthRow(dynamic m) {
    final month = m['month'] ?? '';
    final present = m['present'] ?? 0;
    final total = m['total'] ?? 1;
    final pct = total > 0 ? ((present / total) * 100).toStringAsFixed(1) : '0';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0x108CC63F),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0x288CC63F)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              color: const Color(0xFF8CC63F),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: TextStyle(
      color: Colors.white,
      fontSize: 15.sp,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _card(String title, String value, String sub, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0x108CC63F),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0x288CC63F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11.sp,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (sub.isNotEmpty)
            Text(
              sub,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
            ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white38, fontSize: 11.sp),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
