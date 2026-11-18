import '../models/gym_models.dart';
import 'gym_service.dart';

class VCardExportService {
  /// Generates a standard vCard 3.0 string for all enrolled gym members
  static String generateVcf(List<GymMember> members, BranchProfile branch) {
    final sb = StringBuffer();

    for (final member in members) {
      final lockerTag = member.lockerId != null ? " • Locker ${member.lockerId}" : "";
      final displayName = "${member.fullName} (${branch.branchName}$lockerTag)";
      final phone = member.normalizedPhone.startsWith('+') ? member.normalizedPhone : "+91${member.normalizedPhone}";

      sb.writeln("BEGIN:VCARD");
      sb.writeln("VERSION:3.0");
      sb.writeln("FN:$displayName");
      sb.writeln("N:${member.fullName};;;;");
      sb.writeln("ORG:${branch.branchName}");
      sb.writeln("TEL;TYPE=CELL,VOICE:$phone");
      sb.writeln("NOTE:Plan: ${member.currentPlan.planName} | Shift: ${member.shiftSlot} | Expiry: ${member.currentPlan.endDate.toString().split(' ')[0]} | Dues: ${branch.currencySymbol}${member.currentPlan.duesAmount.toStringAsFixed(0)}");
      sb.writeln("END:VCARD");
      sb.writeln();
    }

    return sb.toString();
  }
}
