import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'gym_service.dart';

class DisasterRecoveryService {
  static Map<String, dynamic> createFullBackup() {
    final snapshot = GymService().exportFullSnapshot();
    final normalized = json.decode(json.encode(snapshot)) as Map<String, dynamic>;
    final jsonStr = json.encode(normalized);
    final checksum = sha256.convert(utf8.encode(jsonStr)).toString();

    return {
      'header': {
        'system': 'TrackMyGym',
        'version': '1.0.0',
        'backupDate': DateTime.now().toIso8601String(),
        'checksum': checksum,
        'itemCounts': {
          'members': GymService().members.length,
          'lockers': GymService().lockers.length,
          'transactions': GymService().transactions.length,
          'attendance': GymService().attendance.length,
          'leads': GymService().leads.length,
        }
      },
      'payload': normalized,
    };
  }

  static BackupValidationResult validateBackup(String rawJson) {
    try {
      final decoded = json.decode(rawJson) as Map<String, dynamic>;
      if (!decoded.containsKey('header') || !decoded.containsKey('payload')) {
        return BackupValidationResult(isValid: false, errorMessage: "Invalid backup format: Missing header or payload.");
      }

      final payload = decoded['payload'] as Map<String, dynamic>;
      final counts = decoded['header']['itemCounts'] as Map<String, dynamic>? ?? {};
      return BackupValidationResult(
        isValid: true,
        summary: "Valid Backup from ${decoded['header']['backupDate'] ?? 'Unknown'}.\n"
            "• Members: ${counts['members'] ?? 0}\n"
            "• Lockers: ${counts['lockers'] ?? 0}\n"
            "• Transactions: ${counts['transactions'] ?? 0}",
        payload: payload,
      );
    } catch (e) {
      return BackupValidationResult(isValid: false, errorMessage: "Malformed JSON string: $e");
    }
  }

  static Future<void> restoreBackup(Map<String, dynamic> payload) async {
    await GymService().restoreFromSnapshot(payload);
  }
}

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? summary;
  final Map<String, dynamic>? payload;

  BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.summary,
    this.payload,
  });
}
