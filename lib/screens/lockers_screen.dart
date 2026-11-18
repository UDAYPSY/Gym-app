import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';
import '../widgets/locker_tile.dart';

class LockersScreen extends StatefulWidget {
  const LockersScreen({Key? key}) : super(key: key);

  @override
  State<LockersScreen> createState() => _LockersScreenState();
}

class _LockersScreenState extends State<LockersScreen> {
  String _filter = "All"; // All, Available, Occupied

  @override
  Widget build(BuildContext context) {
    final gym = GymService();

    return StreamBuilder<List<Locker>>(
      stream: gym.lockersStream,
      builder: (context, snapshot) {
        final allLockers = snapshot.data ?? gym.lockers;
        final availableCount = allLockers.where((l) => l.status == LockerStatus.available).length;
        final occupiedCount = allLockers.where((l) => l.status == LockerStatus.occupied).length;
        final totalDeposits = allLockers
            .where((l) => l.status == LockerStatus.occupied)
            .fold(0.0, (acc, l) => acc + l.depositAmount);
        final currency = gym.branch.currencySymbol;

        final displayedLockers = allLockers.where((l) {
          if (_filter == "Available") return l.status == LockerStatus.available;
          if (_filter == "Occupied") return l.status == LockerStatus.occupied;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Locker Management Floor Grid",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$occupiedCount Occupied • $availableCount Available • Total Deposits: $currency${totalDeposits.toStringAsFixed(0)}",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _filterChip("All", allLockers.length),
                        const SizedBox(width: 8),
                        _filterChip("Available", availableCount),
                        const SizedBox(width: 8),
                        _filterChip("Occupied", occupiedCount),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Locker Grid View
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 110,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: displayedLockers.length,
                    itemBuilder: (context, index) {
                      final locker = displayedLockers[index];
                      return LockerTile(
                        locker: locker,
                        onTap: () => _handleLockerTap(context, locker),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, int count) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text("$label ($count)"),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = label),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : Colors.white12),
    );
  }

  void _handleLockerTap(BuildContext context, Locker locker) {
    if (locker.isOccupied) {
      _showOccupiedModal(context, locker);
    } else {
      _showAllocateModal(context, locker);
    }
  }

  void _showOccupiedModal(BuildContext context, Locker locker) {
    final gym = GymService();
    final currency = gym.branch.currencySymbol;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              "Locker ${locker.lockerCode} Details",
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Occupant Member", locker.assignedMemberName ?? "Unknown"),
            const SizedBox(height: 10),
            _detailRow("Security Deposit Held", "$currency${locker.depositAmount.toStringAsFixed(0)}"),
            const SizedBox(height: 10),
            _detailRow("Status", "Occupied"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () async {
              await gym.releaseLocker(locker.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Locker ${locker.lockerCode} has been vacated and deposit marked for refund.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusExpired,
              foregroundColor: Colors.white,
            ),
            child: const Text("Release & Vacate"),
          ),
        ],
      ),
    );
  }

  void _showAllocateModal(BuildContext context, Locker locker) {
    final gym = GymService();
    final membersWithoutLocker = gym.members.where((m) => m.lockerId == null).toList();
    GymMember? selectedMember = membersWithoutLocker.isNotEmpty ? membersWithoutLocker.first : null;
    final depositCtrl = TextEditingController(text: "500");

    if (membersWithoutLocker.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All currently enrolled members already have a locker assigned.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setAllocState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            "Allocate Locker ${locker.lockerCode}",
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<GymMember>(
                value: selectedMember,
                dropdownColor: AppColors.surfaceElevated,
                decoration: const InputDecoration(labelText: "Assign to Member"),
                items: membersWithoutLocker.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text("${m.fullName} (${m.normalizedPhone})"),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setAllocState(() => selectedMember = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: depositCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Refundable Security Deposit (${gym.branch.currencySymbol})",
                  prefixIcon: const Icon(Icons.security),
                ),
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
                if (selectedMember != null) {
                  final deposit = double.tryParse(depositCtrl.text) ?? 500.0;
                  await gym.allocateLocker(
                    lockerId: locker.id,
                    memberId: selectedMember!.id,
                    deposit: deposit,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Assigned ${locker.lockerCode} to ${selectedMember!.fullName}")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Confirm Allocation"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
