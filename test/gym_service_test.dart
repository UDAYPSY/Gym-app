import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/services/gym_service.dart';
import 'package:gym_manager/services/disaster_recovery_service.dart';
import 'package:gym_manager/services/excel_import_service.dart';
import 'package:gym_manager/services/vcard_export_service.dart';
import 'package:gym_manager/models/gym_models.dart';
import 'package:gym_manager/main.dart';
import 'package:gym_manager/screens/main_hub_screen.dart';
import 'package:gym_manager/screens/members_screen.dart';
import 'package:gym_manager/screens/attendance_screen.dart';
import 'package:gym_manager/screens/lockers_screen.dart';
import 'package:gym_manager/screens/workouts_screen.dart';
import 'package:gym_manager/screens/payments_screen.dart';
import 'package:gym_manager/screens/leads_screen.dart';
import 'package:gym_manager/screens/dashboard_screen.dart';
import 'package:gym_manager/screens/tools_screen.dart';
import 'package:gym_manager/widgets/digital_gym_pass.dart';

void main() {
  group('GymService Core Operations Tests', () {
    late GymService gym;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      gym = GymService();
      await gym.init();
      gym.resetForTesting();
    });

    test('Initializes with default plans and seed members', () {
      expect(gym.plans.isNotEmpty, true);
      expect(gym.members.isNotEmpty, true);
      expect(gym.lockers.length, 40);
    });

    test('Normalize phone removes prefixes and special characters', () {
      expect(GymService.normalizePhone("+91 98765-43210"), "9876543210");
      expect(GymService.normalizePhone("09876543210"), "9876543210");
      expect(GymService.normalizePhone("919876543210"), "9876543210");
    });

    test('Collect dues reduces member dues and records financial transaction', () async {
      final initialTxCount = gym.transactions.length;
      final duesMember = gym.members.firstWhere((m) => m.hasDues);
      final initialDues = duesMember.currentPlan.duesAmount;

      await gym.collectDues(
        memberId: duesMember.id,
        amount: 500.0,
        paymentMethod: "upi",
      );

      final updated = gym.getMemberById(duesMember.id);
      expect(updated != null, true);
      expect(updated!.currentPlan.duesAmount, closeTo(initialDues - 500.0, 0.01));
      expect(gym.transactions.length, initialTxCount + 1);
    });

    test('Locker allocation and release updates locker status', () async {
      final availableLocker = gym.lockers.firstWhere((l) => l.status == LockerStatus.available);
      final member = gym.members.first;

      await gym.allocateLocker(
        lockerId: availableLocker.id,
        memberId: member.id,
        deposit: 500.0,
      );

      final updatedLocker = gym.lockers.firstWhere((l) => l.id == availableLocker.id);
      expect(updatedLocker.status, LockerStatus.occupied);
      expect(updatedLocker.assignedMemberId, member.id);

      // Release locker
      await gym.releaseLocker(availableLocker.id);
      final releasedLocker = gym.lockers.firstWhere((l) => l.id == availableLocker.id);
      expect(releasedLocker.status, LockerStatus.available);
      expect(releasedLocker.assignedMemberId, isNull);
    });

    test('Disaster recovery creates verifiable backup snapshot', () {
      final backup = DisasterRecoveryService.createFullBackup();
      expect(backup.containsKey('header'), true);
      expect(backup.containsKey('payload'), true);

      final validation = DisasterRecoveryService.validateBackup(
        json.encode(backup),
      );
      expect(validation.isValid, true);
    });

    test('GymExpense logs operational costs and computes operating profit', () async {
      await gym.addExpense(GymExpense(
        id: "exp_test_1",
        title: "Treadmill Service",
        category: "Equipment AMC & Repair",
        amount: 2000.0,
        date: DateTime.now(),
      ));

      expect(gym.expenses.any((e) => e.id == "exp_test_1"), true);
      expect(gym.getTotalExpenses() >= 2000.0, true);

      await gym.deleteExpense("exp_test_1");
      expect(gym.expenses.any((e) => e.id == "exp_test_1"), false);
    });

    test('Multi-branch switcher updates active branch profile', () {
      expect(gym.branches.isNotEmpty, true);
      final otherBranch = gym.branches.firstWhere((b) => b.id == "b_2");
      gym.switchBranch("b_2");
      expect(gym.branch.id, "b_2");
      expect(gym.branch.branchName, otherBranch.branchName);
    });

    test('VCardExportService generates valid vCard string with member details', () {
      final vcf = VCardExportService.generateVcf(gym.members, gym.branch);
      expect(vcf.contains("BEGIN:VCARD"), true);
      expect(vcf.contains("END:VCARD"), true);
      expect(vcf.contains(gym.members.first.fullName), true);
    });

    test('ExcelImportService generates valid template and parses rows', () async {
      final template = ExcelImportService.generateTemplateCsv();
      expect(template.contains("Full Name"), true);
      expect(template.contains("Phone Number"), true);

      const tsvData = "Test Member\t9800011122\tMorning\tL-15\t3 Months Pro\t3000\tMale\tEmergency Contact\tSector 5\t0";
      final result = await ExcelImportService.parseAndImport(tsvData, gym);
      expect(result.successfullyImported, 1);
      expect(gym.findMemberByPhone("9800011122") != null, true);
    });

    test('All UI screens and widgets compile and instantiate cleanly', () {
      expect(const TrackMyGymApp(), isNotNull);
      expect(const MainHubScreen(), isNotNull);
      expect(const MembersScreen(), isNotNull);
      expect(const AttendanceScreen(), isNotNull);
      expect(const LockersScreen(), isNotNull);
      expect(const WorkoutsScreen(), isNotNull);
      expect(const PaymentsScreen(), isNotNull);
      expect(const LeadsScreen(), isNotNull);
      expect(const DashboardScreen(), isNotNull);
      expect(const ToolsScreen(), isNotNull);
      expect(DigitalGymPass(member: gym.members.first), isNotNull);
    });
  });
}
