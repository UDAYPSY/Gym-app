import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';
import '../services/gym_service.dart';

class DigitalGymPass extends StatelessWidget {
  final GymMember member;

  const DigitalGymPass({Key? key, required this.member}) : super(key: key);

  void _shareViaWhatsApp(BuildContext context) async {
    final branch = GymService().branch;
    final message = "🏋️ *${branch.branchName} — DIGITAL MEMBERSHIP PASS*\n\n"
        "👤 *Member:* ${member.fullName}\n"
        "📱 *Phone:* ${member.normalizedPhone}\n"
        "🏷️ *Plan:* ${member.currentPlan.planName}\n"
        "📅 *Valid Until:* ${member.currentPlan.endDate.toString().split(' ')[0]}\n"
        "🔒 *Locker:* ${member.lockerId ?? 'Not Assigned'}\n"
        "⏰ *Shift Slot:* ${member.shiftSlot}\n"
        "💰 *Dues Pending:* ${branch.currencySymbol}${member.currentPlan.duesAmount.toStringAsFixed(0)}\n\n"
        "Show this pass or present your QR at reception for seamless check-in!";

    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse("https://wa.me/91${member.normalizedPhone}?text=$encoded");

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
    final branch = GymService().branch;
    final isExpired = member.isExpired;
    final hasDues = member.hasDues;

    // QR payload contains verification token
    final qrData = json.encode({
      'type': 'gym_pass',
      'id': member.id,
      'phone': member.normalizedPhone,
      'validUntil': member.currentPlan.endDate.toIso8601String(),
    });

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.surface,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: isExpired
                ? AppColors.statusExpired
                : (hasDues ? AppColors.statusDues : AppColors.primary),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Gym Name & Crest
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.branchName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "OFFICIAL DIGITAL ACCESS PASS",
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.surfaceElevated, height: 28),

            // Member Photo & Info Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: AppColors.surfaceElevated,
                    child: member.photoBase64 != null
                        ? Image.memory(
                            base64Decode(member.photoBase64!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person, color: AppColors.textSecondary, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.normalizedPhone,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isExpired
                                  ? AppColors.statusExpired
                                  : (hasDues ? AppColors.statusDues : AppColors.primary))
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isExpired
                              ? "EXPIRED"
                              : (hasDues
                                  ? "DUES: ${branch.currencySymbol}${member.currentPlan.duesAmount.toStringAsFixed(0)}"
                                  : "${member.daysRemaining} DAYS REMAINING"),
                          style: TextStyle(
                            color: isExpired
                                ? AppColors.statusExpired
                                : (hasDues ? AppColors.statusDues : AppColors.primary),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan & Locker Badges
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoColumn("PLAN", member.currentPlan.planName),
                  Container(width: 1, height: 28, color: Colors.white24),
                  _infoColumn("LOCKER", member.lockerId ?? "None"),
                  Container(width: 1, height: 28, color: Colors.white24),
                  _infoColumn("SHIFT", member.shiftSlot.split(' ')[0]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic High-Contrast QR Code
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 150.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Scan at Reception Kiosk for Instant Entry",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 16),

            // WhatsApp Dispatch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaWhatsApp(context),
                icon: const Icon(Icons.share, size: 18),
                label: const Text("Share Pass via WhatsApp"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
