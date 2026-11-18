import 'dart:async';
import 'dart:convert';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';
import 'local_storage_service.dart';

/// Core Singleton Service for Gym Operations, Access Control, and Workout Logging
class GymService {
  static final GymService _instance = GymService._internal();
  factory GymService() => _instance;
  GymService._internal();

  // In-Memory Reactive Stores
  final List<GymMember> _members = [];
  final List<Locker> _lockers = [];
  final List<MembershipPlan> _plans = [];
  final List<AttendanceRecord> _attendance = [];
  final List<FinancialTransaction> _transactions = [];
  final List<WorkoutSession> _workouts = [];
  final List<PersonalTrainingSession> _ptSessions = [];
  final List<WalkInLead> _leads = [];
  final List<EquipmentAsset> _equipment = [];
  final List<GymExpense> _expenses = [];
  final List<BranchProfile> _branches = [];

  BranchProfile _branch = BranchProfile(
    id: "b_1",
    branchName: "TrackMyGym Fitness Hub",
    address: "Plot 42, Sector 14, Commercial District",
    phone: "9876543210",
    gstNumber: "07AAAAA0000A1Z5",
    upiId: "trackmygym@upi",
    capacityLimit: 120,
    currencySymbol: "₹",
  );

  // Broadcast Stream Controllers
  final _membersCtrl = StreamController<List<GymMember>>.broadcast();
  final _lockersCtrl = StreamController<List<Locker>>.broadcast();
  final _plansCtrl = StreamController<List<MembershipPlan>>.broadcast();
  final _attendanceCtrl = StreamController<List<AttendanceRecord>>.broadcast();
  final _transactionsCtrl = StreamController<List<FinancialTransaction>>.broadcast();
  final _workoutsCtrl = StreamController<List<WorkoutSession>>.broadcast();
  final _ptSessionsCtrl = StreamController<List<PersonalTrainingSession>>.broadcast();
  final _leadsCtrl = StreamController<List<WalkInLead>>.broadcast();
  final _equipmentCtrl = StreamController<List<EquipmentAsset>>.broadcast();
  final _expensesCtrl = StreamController<List<GymExpense>>.broadcast();
  final _branchesCtrl = StreamController<List<BranchProfile>>.broadcast();
  final _branchCtrl = StreamController<BranchProfile>.broadcast();

  // Public Streams
  Stream<List<GymMember>> get membersStream => _membersCtrl.stream;
  Stream<List<Locker>> get lockersStream => _lockersCtrl.stream;
  Stream<List<MembershipPlan>> get plansStream => _plansCtrl.stream;
  Stream<List<AttendanceRecord>> get attendanceStream => _attendanceCtrl.stream;
  Stream<List<FinancialTransaction>> get transactionsStream => _transactionsCtrl.stream;
  Stream<List<WorkoutSession>> get workoutsStream => _workoutsCtrl.stream;
  Stream<List<PersonalTrainingSession>> get ptSessionsStream => _ptSessionsCtrl.stream;
  Stream<List<WalkInLead>> get leadsStream => _leadsCtrl.stream;
  Stream<List<EquipmentAsset>> get equipmentStream => _equipmentCtrl.stream;
  Stream<List<GymExpense>> get expensesStream => _expensesCtrl.stream;
  Stream<List<BranchProfile>> get branchesStream => _branchesCtrl.stream;
  Stream<BranchProfile> get branchStream => _branchCtrl.stream;

  // Direct Synchronous Getters
  List<GymMember> get members => List.unmodifiable(_members);
  List<Locker> get lockers => List.unmodifiable(_lockers);
  List<MembershipPlan> get plans => List.unmodifiable(_plans);
  List<AttendanceRecord> get attendance => List.unmodifiable(_attendance);
  List<FinancialTransaction> get transactions => List.unmodifiable(_transactions);
  List<WorkoutSession> get workouts => List.unmodifiable(_workouts);
  List<PersonalTrainingSession> get ptSessions => List.unmodifiable(_ptSessions);
  List<WalkInLead> get leads => List.unmodifiable(_leads);
  List<EquipmentAsset> get equipment => List.unmodifiable(_equipment);
  List<GymExpense> get expenses => List.unmodifiable(_expenses);
  List<BranchProfile> get branches => List.unmodifiable(_branches);
  BranchProfile get branch => _branch;

  bool _initialized = false;

  /// Initialize and load data from local storage, or populate sample data
  Future<void> init() async {
    if (_initialized) return;
    await LocalStorageService.instance.init();

    final dataJson = await LocalStorageService.instance.getString('trackmygym_master_db');
    if (dataJson != null && dataJson.isNotEmpty) {
      try {
        final decoded = json.decode(dataJson) as Map<String, dynamic>;
        _loadFromMap(decoded);
      } catch (e) {
        _seedInitialData();
      }
    } else {
      _seedInitialData();
    }

    _broadcastAll();
    _initialized = true;
  }

  void _broadcastAll() {
    _membersCtrl.add(List.unmodifiable(_members));
    _lockersCtrl.add(List.unmodifiable(_lockers));
    _plansCtrl.add(List.unmodifiable(_plans));
    _attendanceCtrl.add(List.unmodifiable(_attendance));
    _transactionsCtrl.add(List.unmodifiable(_transactions));
    _workoutsCtrl.add(List.unmodifiable(_workouts));
    _ptSessionsCtrl.add(List.unmodifiable(_ptSessions));
    _leadsCtrl.add(List.unmodifiable(_leads));
    _equipmentCtrl.add(List.unmodifiable(_equipment));
    _expensesCtrl.add(List.unmodifiable(_expenses));
    _branchesCtrl.add(List.unmodifiable(_branches));
    _branchCtrl.add(_branch);
  }

  void resetForTesting() {
    _seedInitialData();
    _transactions.clear();
    _attendance.clear();
    _expenses.clear();
    _broadcastAll();
  }

  Future<void> _persist() async {
    final payload = exportFullSnapshot();
    await LocalStorageService.instance.saveString('trackmygym_master_db', json.encode(payload));
  }

  // ==========================================
  // MEMBER MANAGEMENT
  // ==========================================

  Future<void> addMember(GymMember member) async {
    // Normalization & duplicate protection
    final normalized = normalizePhone(member.normalizedPhone);
    final existingIndex = _members.indexWhere((m) => m.normalizedPhone == normalized);
    if (existingIndex != -1) {
      throw Exception("A member with phone $normalized already exists.");
    }

    _members.add(member);
    _membersCtrl.add(List.unmodifiable(_members));

    // Record initial financial transaction if payment was made
    if (member.currentPlan.paidAmount > 0) {
      await recordTransaction(FinancialTransaction(
        id: "tx_${DateTime.now().millisecondsSinceEpoch}",
        memberId: member.id,
        memberName: member.fullName,
        amount: member.currentPlan.paidAmount,
        paymentMethod: "upi",
        category: "membership",
        invoiceNumber: "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
        cgst: member.currentPlan.paidAmount * 0.09,
        sgst: member.currentPlan.paidAmount * 0.09,
        date: DateTime.now(),
        notes: "Admission & Subscription fee for ${member.currentPlan.planName}",
      ));
    }

    await _persist();
  }

  Future<void> updateMember(GymMember updated) async {
    final idx = _members.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _members[idx] = updated;
      _membersCtrl.add(List.unmodifiable(_members));
      await _persist();
    }
  }

  Future<void> deleteMember(String id) async {
    _members.removeWhere((m) => m.id == id);
    _membersCtrl.add(List.unmodifiable(_members));
    await _persist();
  }

  GymMember? getMemberById(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  GymMember? findMemberByPhone(String phone) {
    final norm = normalizePhone(phone);
    try {
      return _members.firstWhere((m) => m.normalizedPhone == norm);
    } catch (_) {
      return null;
    }
  }

  Future<void> collectDues({
    required String memberId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    final member = getMemberById(memberId);
    if (member == null) return;

    final currentPlan = member.currentPlan;
    final newPaid = currentPlan.paidAmount + amount;
    final newDues = currentPlan.totalFee - newPaid;

    final updatedMember = member.copyWith(
      currentPlan: SubscriptionPlanDetails(
        planId: currentPlan.planId,
        planName: currentPlan.planName,
        startDate: currentPlan.startDate,
        endDate: currentPlan.endDate,
        totalFee: currentPlan.totalFee,
        paidAmount: newPaid,
        duesAmount: newDues < 0 ? 0 : newDues,
      ),
      status: (newDues <= 0 && !member.isExpired) ? MemberStatus.active : member.status,
    );

    await updateMember(updatedMember);

    await recordTransaction(FinancialTransaction(
      id: "tx_${DateTime.now().millisecondsSinceEpoch}",
      memberId: member.id,
      memberName: member.fullName,
      amount: amount,
      paymentMethod: paymentMethod,
      category: "dues_clearance",
      invoiceNumber: "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      cgst: amount * 0.09,
      sgst: amount * 0.09,
      date: DateTime.now(),
      notes: notes ?? "Dues settlement",
    ));
  }

  // ==========================================
  // LOCKER ALLOCATION ENGINE
  // ==========================================

  Future<void> allocateLocker({
    required String lockerId,
    required String memberId,
    double deposit = 500.0,
  }) async {
    final member = getMemberById(memberId);
    if (member == null) throw Exception("Member not found");

    final lIndex = _lockers.indexWhere((l) => l.id == lockerId);
    if (lIndex == -1) throw Exception("Locker not found");

    final updatedLocker = _lockers[lIndex].copyWith(
      assignedMemberId: member.id,
      assignedMemberName: member.fullName,
      depositAmount: deposit,
      status: LockerStatus.occupied,
    );

    _lockers[lIndex] = updatedLocker;
    _lockersCtrl.add(List.unmodifiable(_lockers));

    // Update member locker reference
    await updateMember(member.copyWith(lockerId: updatedLocker.lockerCode));

    // Record locker deposit transaction
    if (deposit > 0) {
      await recordTransaction(FinancialTransaction(
        id: "tx_${DateTime.now().millisecondsSinceEpoch}",
        memberId: member.id,
        memberName: member.fullName,
        amount: deposit,
        paymentMethod: "cash",
        category: "locker_deposit",
        invoiceNumber: "INV-LCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
        date: DateTime.now(),
        notes: "Refundable security deposit for Locker ${updatedLocker.lockerCode}",
      ));
    }

    await _persist();
  }

  Future<void> releaseLocker(String lockerId) async {
    final lIndex = _lockers.indexWhere((l) => l.id == lockerId);
    if (lIndex == -1) return;

    final locker = _lockers[lIndex];
    if (locker.assignedMemberId != null) {
      final member = getMemberById(locker.assignedMemberId!);
      if (member != null) {
        await updateMember(member.copyWith(lockerId: null));
      }
    }

    _lockers[lIndex] = locker.copyWith(
      assignedMemberId: null,
      assignedMemberName: null,
      status: LockerStatus.available,
    );
    _lockersCtrl.add(List.unmodifiable(_lockers));
    await _persist();
  }

  // ==========================================
  // ATTENDANCE & ACCESS GATEKEEPER
  // ==========================================

  Future<AttendanceCheckResult> recordCheckIn({
    required String memberId,
    String method = "qr_scan",
  }) async {
    final member = getMemberById(memberId);
    if (member == null) {
      return AttendanceCheckResult(
        isApproved: false,
        message: "Invalid Pass: Member profile not found in gym registry.",
        colorCode: "red",
      );
    }

    // Anti-Passback: Prevent multiple scans within 60 minutes
    final now = DateTime.now();
    final recentScan = _attendance.where((a) =>
      a.memberId == member.id &&
      now.difference(a.checkInTime).inMinutes < 60
    ).toList();

    if (recentScan.isNotEmpty) {
      return AttendanceCheckResult(
        isApproved: false,
        message: "Anti-Passback Alert: Entry already recorded ${now.difference(recentScan.first.checkInTime).inMinutes} min ago.",
        colorCode: "amber",
        member: member,
      );
    }

    // Check membership validity
    if (member.isExpired) {
      final rec = AttendanceRecord(
        id: "att_${DateTime.now().millisecondsSinceEpoch}",
        memberId: member.id,
        memberName: member.fullName,
        memberPhotoBase64: member.photoBase64,
        checkInTime: now,
        shiftSlot: member.shiftSlot,
        checkInMethod: method,
        status: "blocked",
      );
      _attendance.insert(0, rec);
      _attendanceCtrl.add(List.unmodifiable(_attendance));
      await _persist();

      return AttendanceCheckResult(
        isApproved: false,
        message: "Access Blocked: Membership expired on ${member.currentPlan.endDate.toString().split(' ')[0]}. Renew at desk.",
        colorCode: "red",
        member: member,
      );
    }

    // Has Dues Warning
    String status = "approved";
    String msg = "Welcome back, ${member.fullName}! Check-in confirmed.";
    String color = "green";

    if (member.hasDues) {
      status = "dues_warning";
      msg = "Check-in Approved with Note: Pending balance of ${branch.currencySymbol}${member.currentPlan.duesAmount.toStringAsFixed(0)}.";
      color = "amber";
    }

    final record = AttendanceRecord(
      id: "att_${DateTime.now().millisecondsSinceEpoch}",
      memberId: member.id,
      memberName: member.fullName,
      memberPhotoBase64: member.photoBase64,
      checkInTime: now,
      shiftSlot: member.shiftSlot,
      checkInMethod: method,
      status: status,
    );

    _attendance.insert(0, record);
    _attendanceCtrl.add(List.unmodifiable(_attendance));
    await _persist();

    return AttendanceCheckResult(
      isApproved: true,
      message: msg,
      colorCode: color,
      member: member,
    );
  }

  int getTodayAttendanceCount() {
    final today = DateTime.now();
    return _attendance.where((a) =>
      a.checkInTime.year == today.year &&
      a.checkInTime.month == today.month &&
      a.checkInTime.day == today.day &&
      a.status != "blocked"
    ).length;
  }

  // ==========================================
  // FINANCIAL LEDGER & POS
  // ==========================================

  Future<void> recordTransaction(FinancialTransaction tx) async {
    _transactions.insert(0, tx);
    _transactionsCtrl.add(List.unmodifiable(_transactions));
    await _persist();
  }

  double getTodayCollections() {
    final today = DateTime.now();
    return _transactions
        .where((t) =>
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day)
        .fold(0.0, (acc, t) => acc + t.amount);
  }

  double getTotalPendingDues() {
    return _members.fold(0.0, (acc, m) => acc + m.currentPlan.duesAmount);
  }

  // ==========================================
  // EXPENSES & OPERATING PROFIT
  // ==========================================

  Future<void> addExpense(GymExpense expense) async {
    _expenses.insert(0, expense);
    _expensesCtrl.add(List.unmodifiable(_expenses));
    await _persist();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    _expensesCtrl.add(List.unmodifiable(_expenses));
    await _persist();
  }

  double getTotalExpenses() {
    return _expenses.fold(0.0, (acc, e) => acc + e.amount);
  }

  double getNetProfit() {
    final revenue = _transactions.fold(0.0, (acc, t) => acc + t.amount);
    final totalExpenses = getTotalExpenses();
    return revenue - totalExpenses;
  }

  // ==========================================
  // MULTI-BRANCH MANAGEMENT
  // ==========================================

  void switchBranch(String branchId) {
    final found = _branches.where((b) => b.id == branchId).toList();
    if (found.isNotEmpty) {
      _branch = found.first;
      _branchCtrl.add(_branch);
      _persist();
    }
  }

  Future<void> addBranch(BranchProfile branch) async {
    _branches.add(branch);
    _branchesCtrl.add(List.unmodifiable(_branches));
    await _persist();
  }

  // ==========================================
  // WORKOUT LOGGING ENGINE
  // ==========================================

  Future<void> saveWorkoutSession(WorkoutSession session) async {
    _workouts.insert(0, session);
    _workoutsCtrl.add(List.unmodifiable(_workouts));
    await _persist();
  }

  // ==========================================
  // LEADS CRM
  // ==========================================

  Future<void> addLead(WalkInLead lead) async {
    _leads.insert(0, lead);
    _leadsCtrl.add(List.unmodifiable(_leads));
    await _persist();
  }

  Future<void> updateLeadStage(String leadId, LeadStage newStage) async {
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx != -1) {
      _leads[idx] = _leads[idx].copyWith(stage: newStage);
      _leadsCtrl.add(List.unmodifiable(_leads));
      await _persist();
    }
  }

  // ==========================================
  // PERSONAL TRAINING (PT)
  // ==========================================

  Future<void> deductPtSession(String ptId) async {
    final idx = _ptSessions.indexWhere((pt) => pt.id == ptId);
    if (idx != -1) {
      final current = _ptSessions[idx];
      if (current.completedSessions < current.totalSessions) {
        _ptSessions[idx] = PersonalTrainingSession(
          id: current.id,
          memberId: current.memberId,
          memberName: current.memberName,
          trainerId: current.trainerId,
          trainerName: current.trainerName,
          totalSessions: current.totalSessions,
          completedSessions: current.completedSessions + 1,
          commissionPercent: current.commissionPercent,
          startDate: current.startDate,
          endDate: current.endDate,
          status: current.completedSessions + 1 >= current.totalSessions ? "completed" : "active",
        );
        _ptSessionsCtrl.add(List.unmodifiable(_ptSessions));
        await _persist();
      }
    }
  }

  // ==========================================
  // DATA SOVEREIGNTY: SNAPSHOT & REHYDRATION
  // ==========================================

  Map<String, dynamic> exportFullSnapshot() {
    return {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'branch': _branch.toJson(),
      'branches': _branches.map((b) => b.toJson()).toList(),
      'members': _members.map((m) => m.toJson()).toList(),
      'lockers': _lockers.map((l) => l.toJson()).toList(),
      'plans': _plans.map((p) => p.toJson()).toList(),
      'attendance': _attendance.map((a) => a.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
      'workouts': _workouts.map((w) => w.toJson()).toList(),
      'ptSessions': _ptSessions.map((pt) => pt.toJson()).toList(),
      'leads': _leads.map((l) => l.toJson()).toList(),
      'equipment': _equipment.map((e) => e.toJson()).toList(),
      'expenses': _expenses.map((e) => e.toJson()).toList(),
    };
  }

  Future<void> restoreFromSnapshot(Map<String, dynamic> data) async {
    _loadFromMap(data);
    _broadcastAll();
    await _persist();
  }

  void _loadFromMap(Map<String, dynamic> data) {
    if (data['branch'] != null) {
      _branch = BranchProfile.fromJson(data['branch']);
    }

    if (data['branches'] != null) {
      _branches.clear();
      _branches.addAll((data['branches'] as List).map((b) => BranchProfile.fromJson(b)));
    }

    if (data['members'] != null) {
      _members.clear();
      _members.addAll((data['members'] as List).map((m) => GymMember.fromJson(m)));
    }

    if (data['lockers'] != null) {
      _lockers.clear();
      _lockers.addAll((data['lockers'] as List).map((l) => Locker.fromJson(l)));
    }

    if (data['plans'] != null) {
      _plans.clear();
      _plans.addAll((data['plans'] as List).map((p) => MembershipPlan.fromJson(p)));
    }

    if (data['attendance'] != null) {
      _attendance.clear();
      _attendance.addAll((data['attendance'] as List).map((a) => AttendanceRecord.fromJson(a)));
    }

    if (data['transactions'] != null) {
      _transactions.clear();
      _transactions.addAll((data['transactions'] as List).map((t) => FinancialTransaction.fromJson(t)));
    }

    if (data['workouts'] != null) {
      _workouts.clear();
      _workouts.addAll((data['workouts'] as List).map((w) => WorkoutSession.fromJson(w)));
    }

    if (data['ptSessions'] != null) {
      _ptSessions.clear();
      _ptSessions.addAll((data['ptSessions'] as List).map((pt) => PersonalTrainingSession.fromJson(pt)));
    }

    if (data['leads'] != null) {
      _leads.clear();
      _leads.addAll((data['leads'] as List).map((l) => WalkInLead.fromJson(l)));
    }

    if (data['equipment'] != null) {
      _equipment.clear();
      _equipment.addAll((data['equipment'] as List).map((e) => EquipmentAsset.fromJson(e)));
    }

    if (data['expenses'] != null) {
      _expenses.clear();
      _expenses.addAll((data['expenses'] as List).map((e) => GymExpense.fromJson(e)));
    }
  }

  // ==========================================
  // INITIAL SEED DATA
  // ==========================================

  void _seedInitialData() {
    _plans.clear();
    _plans.addAll([
      MembershipPlan(
        id: "p_1m",
        name: "1 Month General Fitness",
        durationMonths: 1,
        category: "General Fitness",
        fee: 1500,
        admissionFee: 500,
        description: "Full access to gym floor, cardio, and steam room.",
      ),
      MembershipPlan(
        id: "p_3m",
        name: "3 Months Quarterly Pro",
        durationMonths: 3,
        category: "General Fitness",
        fee: 3800,
        admissionFee: 0,
        description: "Includes free fitness assessment and locker key.",
      ),
      MembershipPlan(
        id: "p_6m",
        name: "6 Months Half-Yearly Gold",
        durationMonths: 6,
        category: "General Fitness",
        fee: 6800,
        admissionFee: 0,
        description: "Includes diet consultation and priority locker.",
      ),
      MembershipPlan(
        id: "p_12m",
        name: "1 Year Annual VIP",
        durationMonths: 12,
        category: "All-Access",
        fee: 11999,
        admissionFee: 0,
        description: "All access + 2 Personal Training trial sessions.",
      ),
      MembershipPlan(
        id: "p_pt_24",
        name: "Personal Training (24 Sessions)",
        durationMonths: 2,
        category: "Personal Training",
        fee: 12000,
        admissionFee: 0,
        description: "1-on-1 coach guidance with tailored nutrition plan.",
      ),
    ]);

    // Seed 40 Lockers (L-01 to L-40)
    _lockers.clear();
    for (int i = 1; i <= 40; i++) {
      final code = "L-${i.toString().padLeft(2, '0')}";
      _lockers.add(Locker(
        id: "lck_$i",
        lockerCode: code,
        status: i == 3 || i == 7 || i == 12 ? LockerStatus.occupied : LockerStatus.available,
        assignedMemberName: i == 3 ? "Rahul Sharma" : (i == 7 ? "Priya Patel" : (i == 12 ? "Vikram Singh" : null)),
        assignedMemberId: i == 3 ? "m_1" : (i == 7 ? "m_2" : (i == 12 ? "m_3" : null)),
      ));
    }

    // Seed Realistic Sample Members
    _members.clear();
    _members.addAll([
      GymMember(
        id: "m_1",
        fullName: "Rahul Sharma",
        normalizedPhone: "9876543210",
        gender: "Male",
        dob: "1995-04-12",
        emergencyContactName: "Anil Sharma (Father)",
        emergencyContactPhone: "9876543211",
        medicalKyc: MedicalKyc(hasBloodPressure: false, medicalNotes: "No known issues"),
        joinedDate: DateTime.now().subtract(const Duration(days: 45)),
        status: MemberStatus.active,
        currentPlan: SubscriptionPlanDetails(
          planId: "p_3m",
          planName: "3 Months Quarterly Pro",
          startDate: DateTime.now().subtract(const Duration(days: 15)),
          endDate: DateTime.now().add(const Duration(days: 75)),
          totalFee: 3800,
          paidAmount: 3800,
          duesAmount: 0,
        ),
        lockerId: "L-03",
        shiftSlot: ShiftConstants.morning,
        assignedTrainerName: "Coach Rocky",
      ),
      GymMember(
        id: "m_2",
        fullName: "Priya Patel",
        normalizedPhone: "9876543220",
        gender: "Female",
        dob: "1998-08-22",
        emergencyContactName: "Kavita Patel",
        emergencyContactPhone: "9876543221",
        medicalKyc: MedicalKyc(hasAsthma: true, medicalNotes: "Carries inhaler"),
        joinedDate: DateTime.now().subtract(const Duration(days: 60)),
        status: MemberStatus.active,
        currentPlan: SubscriptionPlanDetails(
          planId: "p_6m",
          planName: "6 Months Half-Yearly Gold",
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now().add(const Duration(days: 120)),
          totalFee: 6800,
          paidAmount: 4800,
          duesAmount: 2000, // Has dues
        ),
        lockerId: "L-07",
        shiftSlot: ShiftConstants.evening,
        assignedTrainerName: "Coach Ananya",
      ),
      GymMember(
        id: "m_3",
        fullName: "Vikram Singh",
        normalizedPhone: "9876543230",
        gender: "Male",
        dob: "1992-11-05",
        emergencyContactName: "Sunita Singh",
        emergencyContactPhone: "9876543231",
        medicalKyc: MedicalKyc.empty(),
        joinedDate: DateTime.now().subtract(const Duration(days: 90)),
        status: MemberStatus.expired,
        currentPlan: SubscriptionPlanDetails(
          planId: "p_1m",
          planName: "1 Month General Fitness",
          startDate: DateTime.now().subtract(const Duration(days: 35)),
          endDate: DateTime.now().subtract(const Duration(days: 5)), // Expired 5 days ago
          totalFee: 1500,
          paidAmount: 1500,
          duesAmount: 0,
        ),
        lockerId: "L-12",
        shiftSlot: ShiftConstants.evening,
      ),
    ]);

    // Seed Sample Leads
    _leads.clear();
    _leads.addAll([
      WalkInLead(
        id: "lead_1",
        fullName: "Amit Verma",
        phone: "9811122233",
        fitnessGoal: "Weight Loss (Target: -10 kg)",
        interestedPlan: "3 Months Quarterly Pro",
        trialDate: DateTime.now().add(const Duration(days: 1)),
        stage: LeadStage.trial_scheduled,
        notes: "Requested evening session with trainer guidance.",
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      WalkInLead(
        id: "lead_2",
        fullName: "Sneha Reddy",
        phone: "9822233344",
        fitnessGoal: "Muscle Tone & Core Strength",
        interestedPlan: "1 Year Annual VIP",
        stage: LeadStage.inquiry,
        notes: "Follow up over WhatsApp on Saturday morning.",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Seed Sample Equipment
    _equipment.clear();
    _equipment.addAll([
      EquipmentAsset(
        id: "eq_1",
        name: "Commercial Treadmill T-9000",
        category: "Cardio",
        serialNumber: "TR-9001-A",
        purchaseDate: DateTime.now().subtract(const Duration(days: 300)),
        lastServicedDate: DateTime.now().subtract(const Duration(days: 30)),
        nextServiceDue: DateTime.now().add(const Duration(days: 60)),
        status: "operational",
      ),
      EquipmentAsset(
        id: "eq_2",
        name: "Dual Adjustable Pulley Cable Cross",
        category: "Strength",
        serialNumber: "CC-4402-B",
        purchaseDate: DateTime.now().subtract(const Duration(days: 200)),
        lastServicedDate: DateTime.now().subtract(const Duration(days: 15)),
        nextServiceDue: DateTime.now().add(const Duration(days: 75)),
        status: "operational",
      ),
    ]);

    // Seed Multi-Branches
    _branch = BranchProfile(
      id: "b_1",
      branchName: "TrackMyGym Flagship Club (Main Hub)",
      address: "Plot 42, Fitness Avenue, Sector 18",
      phone: "9876543210",
      gstNumber: "07AAAAA0000A1Z5",
      upiId: "trackmygym@upi",
      capacityLimit: 150,
      currencySymbol: "₹",
    );
    _branches.clear();
    _branches.addAll([
      _branch,
      BranchProfile(
        id: "b_2",
        branchName: "TrackMyGym Elite Club (Mall Road)",
        address: "3rd Floor, Galleria Mall, Mall Road",
        phone: "9876543299",
        gstNumber: "07AAAAA0000A2Z4",
        upiId: "trackmygym.elite@upi",
        capacityLimit: 200,
        currencySymbol: "₹",
      ),
    ]);

    // Seed Running Operational Expenses
    _expenses.clear();
    _expenses.addAll([
      GymExpense(
        id: "exp_1",
        title: "Commercial Treadmill AMC & Belt Lubrication",
        category: "Equipment AMC & Repair",
        amount: 4500,
        date: DateTime.now().subtract(const Duration(days: 5)),
        paymentMode: "UPI",
        note: "Quarterly preventative maintenance for all 6 treadmills",
      ),
      GymExpense(
        id: "exp_2",
        title: "Commercial High-Load HVAC & AC Electricity Bill",
        category: "Electricity/HVAC",
        amount: 18500,
        date: DateTime.now().subtract(const Duration(days: 10)),
        paymentMode: "Bank Transfer",
        note: "Monthly power utility for 8-ton central AC plant",
      ),
      GymExpense(
        id: "exp_3",
        title: "Trainer Salary Advance (Coach Rocky)",
        category: "Trainer Salaries",
        amount: 15000,
        date: DateTime.now().subtract(const Duration(days: 12)),
        paymentMode: "UPI",
        note: "Mid-month advance for personal training sessions",
      ),
      GymExpense(
        id: "exp_4",
        title: "Housekeeping, Floor Sanitizer & Water Dispenser",
        category: "Cleaning/Sanitization",
        amount: 2200,
        date: DateTime.now().subtract(const Duration(days: 18)),
        paymentMode: "Cash",
        note: "Disinfectant wipes, hand wash, and 20L mineral water cans",
      ),
    ]);
  }

  // Helper
  static String normalizePhone(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }
}

class AttendanceCheckResult {
  final bool isApproved;
  final String message;
  final String colorCode; // green, red, amber
  final GymMember? member;

  AttendanceCheckResult({
    required this.isApproved,
    required this.message,
    required this.colorCode,
    this.member,
  });
}
