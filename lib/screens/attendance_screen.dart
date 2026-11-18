import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _manualInputCtrl = TextEditingController();
  AttendanceCheckResult? _lastCheckResult;

  void _processCheckIn(String input) async {
    final gym = GymService();
    String? memberId;

    // First check if it's JSON from QR scan
    if (input.contains('"id"')) {
      try {
        final regex = RegExp(r'"id":\s*"([^"]+)"');
        final match = regex.firstMatch(input);
        if (match != null) memberId = match.group(1);
      } catch (_) {}
    }

    // Otherwise treat input as phone number or ID
    if (memberId == null) {
      final found = gym.findMemberByPhone(input) ?? gym.getMemberById(input);
      if (found != null) memberId = found.id;
    }

    if (memberId == null) {
      setState(() {
        _lastCheckResult = AttendanceCheckResult(
          isApproved: false,
          message: "No member found matching '$input'. Check phone number.",
          colorCode: "red",
        );
      });
      return;
    }

    final result = await gym.recordCheckIn(memberId: memberId, method: "kiosk_scan");
    setState(() {
      _lastCheckResult = result;
    });
    _manualInputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gym = GymService();

    return StreamBuilder<List<AttendanceRecord>>(
      stream: gym.attendanceStream,
      builder: (context, snapshot) {
        final records = snapshot.data ?? gym.attendance;
        final todayCount = gym.getTodayAttendanceCount();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Kiosk Check-In Station
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Access Control Kiosk",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Scan member QR code or enter phone number to check in",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // Interactive Input Box
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _manualInputCtrl,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Enter Mobile Number (e.g. 9876543210)",
                                        prefixIcon: const Icon(Icons.qr_code, color: AppColors.primary),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.send, color: AppColors.primary),
                                          onPressed: () {
                                            if (_manualInputCtrl.text.isNotEmpty) {
                                              _processCheckIn(_manualInputCtrl.text.trim());
                                            }
                                          },
                                        ),
                                      ),
                                      onSubmitted: (val) {
                                        if (val.isNotEmpty) _processCheckIn(val.trim());
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Quick Sample Buttons for Instant Testing
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  const Text("Quick Test:", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  _quickTestChip("Active: Rahul", "9876543210"),
                                  _quickTestChip("Dues: Priya", "9876543220"),
                                  _quickTestChip("Expired: Vikram", "9876543230"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Check-in Gatekeeper Status Card
                        if (_lastCheckResult != null) _buildGateResultCard(_lastCheckResult!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Today's Live Attendance Feed
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Live Feed",
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$todayCount Check-ins",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        Expanded(
                          child: records.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No check-ins recorded yet today.",
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: records.length,
                                  itemBuilder: (context, index) {
                                    final item = records[index];
                                    final isBlocked = item.status == "blocked";
                                    final isDues = item.status == "dues_warning";

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: isBlocked
                                            ? const Color(0xFF7F1D1D)
                                            : (isDues ? const Color(0xFF78350F) : const Color(0xFF064E3B)),
                                        child: Icon(
                                          isBlocked
                                              ? Icons.close
                                              : (isDues ? Icons.priority_high : Icons.check),
                                          color: isBlocked
                                              ? AppColors.statusExpired
                                              : (isDues ? AppColors.statusDues : AppColors.primary),
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        item.memberName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${item.shiftSlot.split(' ')[0]} • ${_formatTime(item.checkInTime)}",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                      trailing: Text(
                                        item.checkInMethod.toUpperCase(),
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickTestChip(String label, String phone) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
      onPressed: () {
        _manualInputCtrl.text = phone;
        _processCheckIn(phone);
      },
    );
  }

  Widget _buildGateResultCard(AttendanceCheckResult result) {
    Color cardColor;
    IconData icon;

    if (result.colorCode == "green") {
      cardColor = AppColors.primary;
      icon = Icons.check_circle;
    } else if (result.colorCode == "amber") {
      cardColor = AppColors.statusDues;
      icon = Icons.warning;
    } else {
      cardColor = AppColors.statusExpired;
      icon = Icons.cancel;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cardColor, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.isApproved ? "ACCESS GRANTED" : "ACCESS DENIED",
                      style: TextStyle(
                        color: cardColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.message,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.member != null) ...[
            const Divider(color: Colors.white24, height: 24),
            Row(
              children: [
                _memberMetaTag("Member", result.member!.fullName),
                const SizedBox(width: 16),
                _memberMetaTag("Plan", result.member!.currentPlan.planName),
                const SizedBox(width: 16),
                _memberMetaTag("Locker", result.member!.lockerId ?? "None"),
                const SizedBox(width: 16),
                _memberMetaTag("Days Left", "${result.member!.daysRemaining}"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberMetaTag(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute $ampm";
  }
}
