import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../services/disaster_recovery_service.dart';
import '../services/file_export_service.dart';
import '../services/excel_import_service.dart';
import '../services/vcard_export_service.dart';
import '../constants/app_constants.dart';
import '../models/gym_models.dart';

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

  void _downloadTemplateCsv() async {
    final template = ExcelImportService.generateTemplateCsv();
    await FileExportService.exportFile(
      filename: "trackmygym_import_template.csv",
      content: template,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Excel import template downloaded: trackmygym_import_template.csv")),
    );
  }

  void _exportVcfContacts() async {
    final gym = GymService();
    final vcfContent = VCardExportService.generateVcf(gym.members, gym.branch);
    final filename = "gym_contacts_vcard_${DateTime.now().toIso8601String().split('T')[0]}.vcf";

    await FileExportService.exportFile(
      filename: filename,
      content: vcfContent,
      mimeType: 'text/vcard',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exported ${gym.members.length} member contacts to $filename for phone book sync!")),
    );
  }

  void _showExcelImportDialog() {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Excel / Google Sheets Importer", style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Copy rows from Microsoft Excel or Google Sheets and paste below. Automatically detects tabs or commas!",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 8,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: "Full Name\tPhone Number\tShift\tLocker Number\tPlan Name\tFee\n"
                      "Aarav Sharma\t9876543210\tMorning\tL-01\t3 Months Pro\t3800",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final raw = textCtrl.text.trim();
              if (raw.isEmpty) return;

              final result = await ExcelImportService.parseAndImport(raw, GymService());
              Navigator.pop(ctx);

              showDialog(
                context: context,
                builder: (resCtx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Text("Import Summary", style: TextStyle(color: AppColors.textPrimary)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• Total Rows Detected: ${result.totalRows}", style: const TextStyle(color: AppColors.textPrimary)),
                      Text("• Successfully Imported: ${result.successfullyImported}", style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                      Text("• Skipped Rows: ${result.skippedRows}", style: const TextStyle(color: AppColors.statusDues)),
                      if (result.warnings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text("Warnings: ${result.warnings.take(3).join('\n')}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(resCtx), child: const Text("Close")),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Validate & Import Rows"),
          ),
        ],
      ),
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
              "Data Sovereignty & Enterprise Tools",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Excel Bulk Import, vCard Phone Sync, 100% Offline Backup, and Multi-Branch Management",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Excel TSV & Contact Sync Section
            _toolSectionCard(
              title: "Excel / Spreadsheet Sync & Contact Book Export",
              description: "Copy rows straight from Excel/Google Sheets and paste them in, download a standard column template, or export all members as a vCard (.vcf) file to instantly sync member caller IDs into your phone.",
              icon: Icons.table_view,
              color: const Color(0xFF10B981),
              actions: [
                ElevatedButton.icon(
                  onPressed: _showExcelImportDialog,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text("Paste Excel Rows"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _downloadTemplateCsv,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Download Template"),
                  style: ElevatedButton.styleFrom(foregroundColor: AppColors.primaryLight),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _exportVcfContacts,
                  icon: const Icon(Icons.contact_phone, size: 18),
                  label: const Text("vCard Phone Sync (.vcf)"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Disaster Recovery Section
            _toolSectionCard(
              title: "1-Click Full System Snapshot (Disaster Recovery)",
              description: "Create an encrypted JSON snapshot of your entire database including members, medical KYC, lockers, financial ledger, running expenses, and workout logs.",
              icon: Icons.shield,
              color: const Color(0xFF3B82F6),
              actions: [
                ElevatedButton.icon(
                  onPressed: _downloadBackupJson,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Download Backup JSON"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showRestoreDialog,
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text("Restore Backup"),
                  style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFF60A5FA)),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _exportMembersCsv,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text("Export CSV"),
                  style: ElevatedButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Multi-Branch Management Card
            StreamBuilder<List<BranchProfile>>(
              stream: gym.branchesStream,
              builder: (context, snapshot) {
                final branches = snapshot.data ?? gym.branches;

                return Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.business, color: AppColors.accent),
                                SizedBox(width: 10),
                                Text(
                                  "Multi-Branch Hub Configuration",
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        const Text(
                          "Active Branch Profile:",
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _branchInfoRow("Branch Name", gym.branch.branchName),
                        _branchInfoRow("Physical Address", gym.branch.address),
                        _branchInfoRow("Helpdesk Mobile", gym.branch.phone),
                        _branchInfoRow("Official UPI VPA", gym.branch.effectiveUpiId),
                        _branchInfoRow("GST Identification #", gym.branch.gstNumber),
                        _branchInfoRow("Max Capacity Limit", "${gym.branch.capacityLimit} Members"),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12, height: 20),
                        const Text("Switch Active Location:", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: branches.map((b) {
                            final isCurrent = b.id == gym.branch.id;
                            return ChoiceChip(
                              label: Text(b.branchName),
                              selected: isCurrent,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceElevated,
                              labelStyle: TextStyle(color: isCurrent ? Colors.white : AppColors.textSecondary),
                              onSelected: (_) => gym.switchBranch(b.id),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
            Wrap(spacing: 8, runSpacing: 8, children: actions),
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
