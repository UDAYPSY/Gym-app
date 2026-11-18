import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gym_service.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({Key? key}) : super(key: key);

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  void _sendWhatsAppNudge(BuildContext context, WalkInLead lead) async {
    final gym = GymService();
    final message = "Hello ${lead.fullName}! 👋\n\n"
        "Greetings from *${gym.branch.branchName}*! "
        "We noticed you were interested in our *${lead.fitnessGoal}* program. "
        "We'd love to invite you for a complimentary 1-day trial workout!\n\n"
        "Reply to this message or visit our front desk at ${gym.branch.address}. See you soon!";

    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse("https://wa.me/91${lead.phone}?text=$encoded");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = GymService();

    return StreamBuilder<List<WalkInLead>>(
      stream: gym.leadsStream,
      builder: (context, snapshot) {
        final allLeads = snapshot.data ?? gym.leads;
        final inquiryCount = allLeads.where((l) => l.stage == LeadStage.inquiry).length;
        final trialCount = allLeads.where((l) => l.stage == LeadStage.trial_scheduled).length;
        final convertedCount = allLeads.where((l) => l.stage == LeadStage.converted).length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Add Lead Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Walk-in Inquiries & Lead Pipeline",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$inquiryCount New Inquiries • $trialCount Trials Booked • $convertedCount Converted",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddLeadModal(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("New Inquiry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Leads List
                Expanded(
                  child: allLeads.isEmpty
                      ? const Center(
                          child: Text(
                            "No walk-in leads recorded yet.",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: allLeads.length,
                          itemBuilder: (context, index) {
                            final lead = allLeads[index];
                            final isTrial = lead.stage == LeadStage.trial_scheduled;

                            return Card(
                              color: AppColors.surface,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Colors.white12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isTrial ? const Color(0xFF78350F) : const Color(0xFF1E293B),
                                  child: Icon(
                                    isTrial ? Icons.event_available : Icons.person_outline,
                                    color: isTrial ? AppColors.statusDues : AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  lead.fullName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "🎯 Goal: ${lead.fitnessGoal} • Plan: ${lead.interestedPlan}\n"
                                  "📱 ${lead.phone} • Status: ${lead.stage.name.replaceAll('_', ' ').toUpperCase()}",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                                      tooltip: "WhatsApp Nudge",
                                      onPressed: () => _sendWhatsAppNudge(context, lead),
                                    ),
                                    PopupMenuButton<LeadStage>(
                                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                      onSelected: (newStage) => gym.updateLeadStage(lead.id, newStage),
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: LeadStage.inquiry, child: Text("Set: Inquiry")),
                                        const PopupMenuItem(value: LeadStage.trial_scheduled, child: Text("Set: Trial Scheduled")),
                                        const PopupMenuItem(value: LeadStage.trial_completed, child: Text("Set: Trial Completed")),
                                        const PopupMenuItem(value: LeadStage.converted, child: Text("Set: Converted 🎉")),
                                        const PopupMenuItem(value: LeadStage.dropped, child: Text("Set: Dropped")),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

  void _showAddLeadModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: "Weight Loss / Fat Burn");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Record Walk-in Inquiry", style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Prospect Name *")),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Phone *")),
            const SizedBox(height: 10),
            TextField(controller: goalCtrl, decoration: const InputDecoration(labelText: "Fitness Goal")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                await GymService().addLead(WalkInLead(
                  id: "lead_${DateTime.now().millisecondsSinceEpoch}",
                  fullName: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  fitnessGoal: goalCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Recorded inquiry for ${nameCtrl.text.trim()}")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Save Lead"),
          ),
        ],
      ),
    );
  }
}
