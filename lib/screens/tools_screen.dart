import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../services/disaster_recovery_service.dart';
import '../services/file_export_service.dart';
import '../constants/app_constants.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  void _downloadBackupJson() async {
    final backup = DisasterRecoveryService.createFullBackup();
    final jsonContent = const JsonEncoder.withIndent('  ').convert(backup);
    final filename = "trackmygym_backup_${DateTime.now().toIso8601String().split('T')[0]}.json";

    await FileExportService.exportFile(
      filename: filename,
      content: jsonContent,
      mimeType: 'application/json',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Backup generated & exported: $filename")),
    );
  }

  void _exportMembersCsv() async {
    final members = GymService().members;
    final csvBuffer = StringBuffer();
    csvBuffer.writeln("ID,Full Name,Phone,Gender,Plan,Valid Until,Locker,Dues");

    for (var m in members) {
      csvBuffer.writeln(
        "${m.id},\"${m.fullName}\",${m.normalizedPhone},${m.gender},\"${m.currentPlan.planName}\",${m.currentPlan.endDate.toString().split(' ')[0]},${m.lockerId ?? 'None'},${m.currentPlan.duesAmount}",
      );
    }

    final filename = "gym_members_${DateTime.now().toIso8601String().split('T')[0]}.csv";
    await FileExportService.exportFile(filename: filename, content: csvBuffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exported members to $filename")),
    );
  }

  void _showRestoreDialog() {
    final jsonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Restore Database from JSON", style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Paste your encrypted JSON snapshot backup below:",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: jsonCtrl,
              maxLines: 8,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(hintText: "{\"header\": { ... }, \"payload\": { ... }}"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final raw = jsonCtrl.text.trim();
              if (raw.isEmpty) return;

              final validation = DisasterRecoveryService.validateBackup(raw);
              if (!validation.isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(validation.errorMessage ?? "Invalid backup data.")),
                );
                return;
              }

              await DisasterRecoveryService.restoreBackup(validation.payload!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Database rehydrated successfully!\n${validation.summary}")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Verify & Restore"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = GymService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Data Sovereignty & System Tools",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "100% Offline-First Backup, Data Export, and Branch Configuration",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Disaster Recovery Section
            _toolSectionCard(
              title: "1-Click Full System Snapshot (Disaster Recovery)",
              description: "Create an encrypted JSON snapshot of your entire database including members, medical KYC, lockers, financial ledger, and workout logs.",
              icon: Icons.shield,
              color: AppColors.primary,
              actions: [
                ElevatedButton.icon(
                  onPressed: _downloadBackupJson,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Download Backup JSON"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showRestoreDialog,
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text("Restore Backup"),
                  style: ElevatedButton.styleFrom(foregroundColor: AppColors.primaryLight),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Spreadsheet & CSV Export Section
            _toolSectionCard(
              title: "Spreadsheet & Financial CSV Export",
              description: "Export member directories and transaction records into clean CSV files compatible with Microsoft Excel, Google Sheets, or tally accounting.",
              icon: Icons.table_chart,
              color: const Color(0xFF3B82F6),
              actions: [
                ElevatedButton.icon(
                  onPressed: _exportMembersCsv,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text("Export Members (CSV)"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Branch Details Card
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.business, color: AppColors.accent),
                        SizedBox(width: 10),
                        Text(
                          "Gym Branch Profile",
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    _branchInfoRow("Branch Name", gym.branch.branchName),
                    _branchInfoRow("Physical Address", gym.branch.address),
                    _branchInfoRow("Helpdesk Mobile", gym.branch.phone),
                    _branchInfoRow("GST Identification #", gym.branch.gstNumber),
                    _branchInfoRow("Max Capacity Limit", "${gym.branch.capacityLimit} Members"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolSectionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<Widget> actions,
  }) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: actions),
          ],
        ),
      ),
    );
  }

  Widget _branchInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
