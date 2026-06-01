import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color primaryGreen = Color(0xFF8CC63F);

  List<dynamic> notifications = [];
  bool isLoading = true;
  String? errorMsg;
  String currentFilter = 'all';

  final filters = ['all', 'unread', 'attendance', 'system'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { isLoading = true; errorMsg = null; });
    try {
      final data = await ApiService.getNotifications(filter: currentFilter);
      setState(() {
        notifications = data['results'] ?? data['notifications'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg  = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllRead();
      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1408),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read', style: TextStyle(color: Color(0xFF8CC63F), fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: filters.map((f) {
                final isActive = f == currentFilter;
                return GestureDetector(
                  onTap: () { setState(() => currentFilter = f); _loadNotifications(); },
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: isActive ? primaryGreen : const Color(0x108CC63F),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isActive ? primaryGreen : const Color(0x288CC63F),
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white60,
                        fontSize: 12.sp,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8CC63F)))
                : errorMsg != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMsg!, style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadNotifications, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : notifications.isEmpty
                        ? const Center(
                            child: Text('No notifications', style: TextStyle(color: Colors.white38)),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: notifications.length,
                            itemBuilder: (ctx, i) => _notifTile(notifications[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _notifTile(dynamic n) {
    final isRead = n['is_read'] ?? false;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isRead ? const Color(0x06FFFFFF) : const Color(0x148CC63F),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isRead ? const Color(0x10FFFFFF) : const Color(0x288CC63F),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w, height: 8.w,
            margin: EdgeInsets.only(top: 5.h),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRead ? Colors.transparent : primaryGreen,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['title'] ?? n['message'] ?? '',
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w500),
                ),
                if ((n['body'] ?? '').isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    n['body'] ?? '',
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ],
                SizedBox(height: 4.h),
                Text(
                  n['created_at'] ?? '',
                  style: TextStyle(color: Colors.white24, fontSize: 10.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
