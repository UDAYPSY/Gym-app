import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/services/gym_service.dart';
import 'package:gym_manager/services/disaster_recovery_service.dart';
import 'package:gym_manager/models/gym_models.dart';

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
        amount: 500,
        paymentMethod: "upi",
      );

      final updated = gym.getMemberById(duesMember.id);
      expect(updated!.currentPlan.duesAmount, initialDues - 500);
      expect(gym.transactions.length, initialTxCount + 1);
      expect(gym.transactions.first.amount, 500);
    });

    test('Locker allocation and release updates locker status', () async {
      final availableLocker = gym.lockers.firstWhere((l) => l.status == LockerStatus.available);
      final member = gym.members.first;

      await gym.allocateLocker(
        lockerId: availableLocker.id,
        memberId: member.id,
        deposit: 500,
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
        const JsonEncoder().convert(backup),
      );
      expect(validation.isValid, true);
    });
  });
}
