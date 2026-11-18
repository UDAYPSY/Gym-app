import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';
import '../widgets/digital_gym_pass.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({Key? key}) : super(key: key);

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All"; // All, Active, Expired, Dues

  @override
  Widget build(BuildContext context) {
    final gym = GymService();

    return StreamBuilder<List<GymMember>>(
      stream: gym.membersStream,
      builder: (context, snapshot) {
        final allMembers = snapshot.data ?? gym.members;

        // Apply Search and Filters
        final filteredMembers = allMembers.where((m) {
          final matchesSearch = m.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              m.normalizedPhone.contains(_searchQuery) ||
              (m.lockerId != null && m.lockerId!.toLowerCase().contains(_searchQuery.toLowerCase()));

          if (!matchesSearch) return false;

          if (_selectedFilter == "Active") return !m.isExpired && m.status == MemberStatus.active;
          if (_selectedFilter == "Expired") return m.isExpired;
          if (_selectedFilter == "Dues") return m.hasDues;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Title and Add Member Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Members Directory",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${allMembers.length} Total Enrolled Members",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMemberWizard(context),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text("New Admission"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar & Filter Chips Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Search by member name, mobile phone, or locker...",
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                                  onPressed: () => setState(() => _searchQuery = ""),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip("All", allMembers.length),
                      const SizedBox(width: 8),
                      _filterChip("Active", allMembers.where((m) => !m.isExpired).length),
                      const SizedBox(width: 8),
                      _filterChip("Dues", allMembers.where((m) => m.hasDues).length),
                      const SizedBox(width: 8),
                      _filterChip("Expired", allMembers.where((m) => m.isExpired).length),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Members List
                Expanded(
                  child: filteredMembers.isEmpty
                      ? const Center(
                          child: Text(
                            "No members match your criteria.",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
                            return _buildMemberCard(context, member);
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
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text("$label ($count)"),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.white12,
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, GymMember member) {
    final currency = GymService().branch.currencySymbol;
    final isExpired = member.isExpired;
    final hasDues = member.hasDues;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isExpired
              ? AppColors.statusExpired
              : (hasDues ? AppColors.statusDues : Colors.white10),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            color: AppColors.surfaceElevated,
            child: member.photoBase64 != null
                ? Image.memory(base64Decode(member.photoBase64!), fit: BoxFit.cover)
                : const Icon(Icons.person, color: AppColors.textSecondary),
          ),
        ),
        title: Row(
          children: [
            Text(
              member.fullName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (member.lockerId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  member.lockerId!,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "📱 ${member.normalizedPhone} • 🏷️ ${member.currentPlan.planName}",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              isExpired
                  ? "❌ Expired on ${member.currentPlan.endDate.toString().split(' ')[0]}"
                  : "✅ Valid until ${member.currentPlan.endDate.toString().split(' ')[0]} (${member.daysRemaining} days left)",
              style: TextStyle(
                color: isExpired ? AppColors.statusExpired : AppColors.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDues)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusDues.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Dues: $currency${member.currentPlan.duesAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: AppColors.statusDues,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.qr_code, color: AppColors.primary),
              tooltip: "View Digital Pass",
              onPressed: () => _showDigitalPassModal(context, member),
            ),
          ],
        ),
      ),
    );
  }

  void _showDigitalPassModal(BuildContext context, GymMember member) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: DigitalGymPass(member: member),
      ),
    );
  }

  void _showAddMemberWizard(BuildContext context) {
    final gym = GymService();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emergencyNameCtrl = TextEditingController();
    final emergencyPhoneCtrl = TextEditingController();
    final paidAmountCtrl = TextEditingController(text: "1500");

    String selectedGender = "Male";
    String selectedShift = ShiftConstants.morning;
    MembershipPlan selectedPlan = gym.plans.first;
    bool hasBp = false;
    bool hasAsthma = false;
    bool hasInjury = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setWizardState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "New Member Admission Wizard",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Personal Details", style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Full Name *", prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Mobile Phone *", prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          dropdownColor: AppColors.surfaceElevated,
                          decoration: const InputDecoration(labelText: "Gender"),
                          items: const [
                            DropdownMenuItem(value: "Male", child: Text("Male")),
                            DropdownMenuItem(value: "Female", child: Text("Female")),
                            DropdownMenuItem(value: "Other", child: Text("Other")),
                          ],
                          onChanged: (val) {
                            if (val != null) setWizardState(() => selectedGender = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedShift,
                          dropdownColor: AppColors.surfaceElevated,
                          decoration: const InputDecoration(labelText: "Preferred Shift"),
                          items: ShiftConstants.allShifts.map((s) => DropdownMenuItem(value: s, child: Text(s.split(' ')[0]))).toList(),
                          onChanged: (val) {
                            if (val != null) setWizardState(() => selectedShift = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text("2. Emergency & Medical KYC (PAR-Q)", style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emergencyNameCtrl,
                          decoration: const InputDecoration(labelText: "Emergency Contact Name"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: emergencyPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: "Emergency Phone"),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text("High Blood Pressure / Hypertension", style: TextStyle(fontSize: 12)),
                    value: hasBp,
                    onChanged: (val) => setWizardState(() => hasBp = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text("Asthma / Respiratory Conditions", style: TextStyle(fontSize: 12)),
                    value: hasAsthma,
                    onChanged: (val) => setWizardState(() => hasAsthma = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text("Prior Spinal / Joint Injury", style: TextStyle(fontSize: 12)),
                    value: hasInjury,
                    onChanged: (val) => setWizardState(() => hasInjury = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  const Text("3. Subscription Plan & Initial Fee", style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MembershipPlan>(
                    value: selectedPlan,
                    dropdownColor: AppColors.surfaceElevated,
                    decoration: const InputDecoration(labelText: "Select Membership Package"),
                    items: gym.plans.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text("${p.name} — ${gym.branch.currencySymbol}${p.fee.toStringAsFixed(0)}"),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setWizardState(() {
                          selectedPlan = val;
                          paidAmountCtrl.text = val.fee.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: paidAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Initial Payment Collected (${gym.branch.currencySymbol})",
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name and phone number are required.")),
                  );
                  return;
                }

                final totalFee = selectedPlan.fee;
                final paid = double.tryParse(paidAmountCtrl.text) ?? 0.0;
                final dues = totalFee - paid;

                final newMember = GymMember(
                  id: "m_${DateTime.now().millisecondsSinceEpoch}",
                  fullName: nameCtrl.text.trim(),
                  normalizedPhone: phoneCtrl.text.trim(),
                  gender: selectedGender,
                  emergencyContactName: emergencyNameCtrl.text.trim(),
                  emergencyContactPhone: emergencyPhoneCtrl.text.trim(),
                  medicalKyc: MedicalKyc(
                    hasBloodPressure: hasBp,
                    hasAsthma: hasAsthma,
                    hasJointOrSpinalInjury: hasInjury,
                  ),
                  joinedDate: DateTime.now(),
                  shiftSlot: selectedShift,
                  currentPlan: SubscriptionPlanDetails(
                    planId: selectedPlan.id,
                    planName: selectedPlan.name,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(Duration(days: selectedPlan.durationMonths * 30)),
                    totalFee: totalFee,
                    paidAmount: paid,
                    duesAmount: dues < 0 ? 0 : dues,
                  ),
                );

                try {
                  await gym.addMember(newMember);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enrolled ${newMember.fullName} successfully!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Complete Admission"),
            ),
          ],
        ),
      ),
    );
  }
}
