import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  static const Color primaryGreen = Color(0xFF8CC63F);
  static const Color bgGreen = Color(0xFF0B1408);

  String selectedCategory = "VACATION";
  DateTime? startDate;
  DateTime? endDate;
  final reasonController = TextEditingController();

  List<dynamic> recentLeaves = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? loadError;
  PlatformFile? selectedFile;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final data = await ApiService.getLeaveRequests();
      setState(() {
        recentLeaves = data['results'] ?? data['data'] ?? data['leaves'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        loadError = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryGreen,
              onPrimary: Colors.black,
              surface: bgGreen,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(picked)) {
            endDate = null;
          }
        } else {
          if (startDate != null && picked.isBefore(startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select valid date!")),
            );
            return;
          }
          endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (startDate == null ||
        endDate == null ||
        reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all details")));
      return;
    }
    setState(() => isSubmitting = true);
    try {
      await ApiService.submitLeaveRequest(
        reason: selectedCategory,
        description: reasonController.text.trim(),
        startDate: DateFormat('yyyy-MM-dd').format(startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(endDate!),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Leave request submitted!")));
      reasonController.clear();
      setState(() {
        startDate = null;
        endDate = null;
      });
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() => isSubmitting = false);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "Leave Request",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: primaryGreen),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              const Text(
                "LEAVE CATEGORY",
                style: TextStyle(color: Colors.white54),
              ),
              SizedBox(height: 10.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    category("VACATION"),
                    category("SICK"),
                    category("PERSONAL"),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              const Text("DURATION", style: TextStyle(color: Colors.white54)),
              SizedBox(height: 10.h),
              Row(
                children: [
                  dateBox(
                    "START DATE",
                    startDate != null
                        ? DateFormat('dd MMM yyyy').format(startDate!)
                        : "dd mm yyyy",
                    true,
                  ),
                  SizedBox(width: 10.w),
                  const Text("-", style: TextStyle(color: Colors.white)),
                  SizedBox(width: 10.w),
                  dateBox(
                    "END DATE",
                    endDate != null
                        ? DateFormat('dd MMM yyyy').format(endDate!)
                        : "dd mm yyyy",
                    false,
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              const Text(
                "REASON FOR LEAVE",
                style: TextStyle(color: Colors.white54),
              ),
              SizedBox(height: 10.h),
              Container(
                height: 120.h,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.05),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Tell us why you need time off...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              GestureDetector(
                onTap: pickFile,
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_file, color: Colors.white),
                      SizedBox(width: 10.w),
                      Text(
                        selectedFile?.name ?? "Upload file",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              GestureDetector(
                onTap: isSubmitting ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryGreen, Color(0xFF6FAF2E)],
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Center(
                    child: isSubmitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Submit Request",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECENT ACTIVITY",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                )
              else if (loadError != null)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          loadError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadRequests,
                        child: const Text(
                          "Retry",
                          style: TextStyle(color: primaryGreen, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...recentLeaves.take(5).map((l) {
                  String rawReason = l['reason']?.toString() ?? "Leave";
                  String displayReason = rawReason.isNotEmpty
                      ? '${rawReason[0].toUpperCase()}${rawReason.substring(1)}'
                      : rawReason;
                  return activity(
                    displayReason,
                    l['status']?.toString() ?? "Pending",
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget category(String text) {
    bool active = text == selectedCategory;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = text),
      child: Container(
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: active ? primaryGreen : Colors.white10,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: TextStyle(color: active ? Colors.white : Colors.grey),
        ),
      ),
    );
  }

  Widget dateBox(String title, String date, bool isStart) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectDate(isStart),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white54, fontSize: 12.sp),
              ),
              SizedBox(height: 5.h),
              Text(date, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget activity(String title, String status) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(
            status,
            style: TextStyle(
              color: (status == "Approved" || status == "approved")
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
