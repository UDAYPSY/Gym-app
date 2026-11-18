import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';
import '../widgets/digital_gym_pass.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardScreen({Key? key, required this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gym = GymService();

    return StreamBuilder<List<GymMember>>(
      stream: gym.membersStream,
      builder: (context, memberSnapshot) {
        final members = memberSnapshot.data ?? gym.members;
        final activeMembers = members.where((m) => !m.isExpired && m.status == MemberStatus.active).length;
        final duesMembers = members.where((m) => m.hasDues).toList();
        final expiredMembers = members.where((m) => m.isExpired).toList();

        return StreamBuilder<List<AttendanceRecord>>(
          stream: gym.attendanceStream,
          builder: (context, attSnapshot) {
            final todayAttendance = gym.getTodayAttendanceCount();

            return StreamBuilder<List<FinancialTransaction>>(
              stream: gym.transactionsStream,
              builder: (context, txSnapshot) {
                final todayCollections = gym.getTodayCollections();
                final totalDues = gym.getTotalPendingDues();
                final currency = gym.branch.currencySymbol;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gym Title & Welcome Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gym.branch.branchName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Live Operations & Floor Status",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: AppColors.primary, size: 10),
                                const SizedBox(width: 6),
                                Text(
                                  "Gate: Active",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Metric Stat Cards Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _statCard(
                                width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                                title: "TODAY'S REVENUE",
                                value: "$currency${todayCollections.toStringAsFixed(0)}",
                                icon: Icons.payments,
                                color: AppColors.primary,
                              ),
                              _statCard(
                                width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                                title: "ACTIVE MEMBERS",
                                value: "$activeMembers",
                                icon: Icons.people,
                                color: const Color(0xFF3B82F6),
                              ),
                              _statCard(
                                width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                                title: "TODAY'S CHECK-INS",
                                value: "$todayAttendance",
                                icon: Icons.how_to_reg,
                                color: const Color(0xFF8B5CF6),
                              ),
                              _statCard(
                                width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                                title: "PENDING DUES",
                                value: "$currency${totalDues.toStringAsFixed(0)}",
                                icon: Icons.warning_amber,
                                color: AppColors.statusDues,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Quick Action Launchpad
                      const Text(
                        "Quick Actions",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _actionButton(
                            label: "New Admission",
                            icon: Icons.person_add,
                            color: AppColors.primary,
                            onTap: () => onNavigate(1), // Members screen
                          ),
                          const SizedBox(width: 12),
                          _actionButton(
                            label: "QR Gate Kiosk",
                            icon: Icons.qr_code_scanner,
                            color: const Color(0xFF8B5CF6),
                            onTap: () => onNavigate(2), // Attendance screen
                          ),
                          const SizedBox(width: 12),
                          _actionButton(
                            label: "Locker Grid",
                            icon: Icons.lock,
                            color: const Color(0xFF3B82F6),
                            onTap: () => onNavigate(3), // Lockers screen
                          ),
                          const SizedBox(width: 12),
                          _actionButton(
                            label: "Log Workout",
                            icon: Icons.fitness_center,
                            color: AppColors.accent,
                            onTap: () => onNavigate(4), // Workouts screen
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Dues Collection Alert Section
                      if (duesMembers.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Pending Fee Settlements (${duesMembers.length})",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => onNavigate(5), // Payments screen
                              child: const Text("View All Dues"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...duesMembers.take(3).map((m) => Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.statusDues, width: 1),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF78350F),
                              child: Icon(Icons.currency_rupee, color: AppColors.statusDues),
                            ),
                            title: Text(
                              m.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Plan: ${m.currentPlan.planName} • Phone: ${m.normalizedPhone}",
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _showQuickPayDialog(context, m),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusDues,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text("Collect $currency${m.currentPlan.duesAmount.toStringAsFixed(0)}"),
                            ),
                          ),
                        )),
                      ],

                      // Expired Members Notice
                      if (expiredMembers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.statusExpired.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.statusExpired.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.statusExpired, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${expiredMembers.length} Expired Members Flagged",
                                      style: const TextStyle(
                                        color: AppColors.statusExpired,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      "Gate check-in will automatically block entry until membership is renewed.",
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => onNavigate(1),
                                child: const Text("Review"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickPayDialog(BuildContext context, GymMember member) {
    final amountCtrl = TextEditingController(text: member.currentPlan.duesAmount.toStringAsFixed(0));
    String paymentMethod = "upi";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            "Collect Dues: ${member.fullName}",
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount (${GymService().branch.currencySymbol})",
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                dropdownColor: AppColors.surfaceElevated,
                items: const [
                  DropdownMenuItem(value: "upi", child: Text("UPI (Google Pay / PhonePe)")),
                  DropdownMenuItem(value: "cash", child: Text("Cash")),
                  DropdownMenuItem(value: "card", child: Text("Card")),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => paymentMethod = val);
                },
                decoration: const InputDecoration(labelText: "Payment Method"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt > 0) {
                  await GymService().collectDues(
                    memberId: member.id,
                    amount: amt,
                    paymentMethod: paymentMethod,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Settled ${GymService().branch.currencySymbol}$amt for ${member.fullName}")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Confirm Receipt"),
            ),
          ],
        ),
      ),
    );
  }
}
