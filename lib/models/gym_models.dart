import 'dart:convert';

/// Represents a Gym Member with demographic, medical KYC, and subscription details.
class GymMember {
  final String id;
  final String fullName;
  final String normalizedPhone;
  final String? photoBase64;
  final String gender;
  final String? dob;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final MedicalKyc medicalKyc;
  final DateTime joinedDate;
  final MemberStatus status;
  final SubscriptionPlanDetails currentPlan;
  final String? lockerId;
  final String shiftSlot;
  final String? assignedTrainerId;
  final String? assignedTrainerName;
  final String? notes;

  GymMember({
    required this.id,
    required this.fullName,
    required this.normalizedPhone,
    this.photoBase64,
    this.gender = "Male",
    this.dob,
    this.emergencyContactName = "",
    this.emergencyContactPhone = "",
    required this.medicalKyc,
    required this.joinedDate,
    this.status = MemberStatus.active,
    required this.currentPlan,
    this.lockerId,
    required this.shiftSlot,
    this.assignedTrainerId,
    this.assignedTrainerName,
    this.notes,
  });

  bool get isExpired => currentPlan.endDate.isBefore(DateTime.now());
  bool get hasDues => currentPlan.duesAmount > 0;
  int get daysRemaining {
    final diff = currentPlan.endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  GymMember copyWith({
    String? id,
    String? fullName,
    String? normalizedPhone,
    String? photoBase64,
    String? gender,
    String? dob,
    String? emergencyContactName,
    String? emergencyContactPhone,
    MedicalKyc? medicalKyc,
    DateTime? joinedDate,
    MemberStatus? status,
    SubscriptionPlanDetails? currentPlan,
    String? lockerId,
    String? shiftSlot,
    String? assignedTrainerId,
    String? assignedTrainerName,
    String? notes,
  }) {
    return GymMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      normalizedPhone: normalizedPhone ?? this.normalizedPhone,
      photoBase64: photoBase64 ?? this.photoBase64,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      medicalKyc: medicalKyc ?? this.medicalKyc,
      joinedDate: joinedDate ?? this.joinedDate,
      status: status ?? this.status,
      currentPlan: currentPlan ?? this.currentPlan,
      lockerId: lockerId ?? this.lockerId,
      shiftSlot: shiftSlot ?? this.shiftSlot,
      assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
      assignedTrainerName: assignedTrainerName ?? this.assignedTrainerName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'normalizedPhone': normalizedPhone,
    'photoBase64': photoBase64,
    'gender': gender,
    'dob': dob,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'medicalKyc': medicalKyc.toJson(),
    'joinedDate': joinedDate.toIso8601String(),
    'status': status.name,
    'currentPlan': currentPlan.toJson(),
    'lockerId': lockerId,
    'shiftSlot': shiftSlot,
    'assignedTrainerId': assignedTrainerId,
    'assignedTrainerName': assignedTrainerName,
    'notes': notes,
  };

  factory GymMember.fromJson(Map<String, dynamic> json) => GymMember(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    normalizedPhone: json['normalizedPhone'] ?? '',
    photoBase64: json['photoBase64'],
    gender: json['gender'] ?? 'Male',
    dob: json['dob'],
    emergencyContactName: json['emergencyContactName'] ?? '',
    emergencyContactPhone: json['emergencyContactPhone'] ?? '',
    medicalKyc: json['medicalKyc'] != null
        ? MedicalKyc.fromJson(json['medicalKyc'])
        : MedicalKyc.empty(),
    joinedDate: json['joinedDate'] != null
        ? DateTime.parse(json['joinedDate'])
        : DateTime.now(),
    status: MemberStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => MemberStatus.active,
    ),
    currentPlan: json['currentPlan'] != null
        ? SubscriptionPlanDetails.fromJson(json['currentPlan'])
        : SubscriptionPlanDetails.empty(),
    lockerId: json['lockerId'],
    shiftSlot: json['shiftSlot'] ?? 'Morning',
    assignedTrainerId: json['assignedTrainerId'],
    assignedTrainerName: json['assignedTrainerName'],
    notes: json['notes'],
  );
}

enum MemberStatus { active, expired, defaulter, frozen }

/// Health and PAR-Q Medical Clearance
class MedicalKyc {
  final bool hasBloodPressure;
  final bool hasHeartCondition;
  final bool hasAsthma;
  final bool hasJointOrSpinalInjury;
  final String medicalNotes;

  MedicalKyc({
    this.hasBloodPressure = false,
    this.hasHeartCondition = false,
    this.hasAsthma = false,
    this.hasJointOrSpinalInjury = false,
    this.medicalNotes = "",
  });

  factory MedicalKyc.empty() => MedicalKyc();

  Map<String, dynamic> toJson() => {
    'hasBloodPressure': hasBloodPressure,
    'hasHeartCondition': hasHeartCondition,
    'hasAsthma': hasAsthma,
    'hasJointOrSpinalInjury': hasJointOrSpinalInjury,
    'medicalNotes': medicalNotes,
  };

  factory MedicalKyc.fromJson(Map<String, dynamic> json) => MedicalKyc(
    hasBloodPressure: json['hasBloodPressure'] ?? false,
    hasHeartCondition: json['hasHeartCondition'] ?? false,
    hasAsthma: json['hasAsthma'] ?? false,
    hasJointOrSpinalInjury: json['hasJointOrSpinalInjury'] ?? false,
    medicalNotes: json['medicalNotes'] ?? '',
  );
}

/// Active Subscription Details
class SubscriptionPlanDetails {
  final String planId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalFee;
  final double paidAmount;
  final double duesAmount;

  SubscriptionPlanDetails({
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.totalFee,
    required this.paidAmount,
    required this.duesAmount,
  });

  factory SubscriptionPlanDetails.empty() => SubscriptionPlanDetails(
    planId: "p_1m",
    planName: "1 Month General Fitness",
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 30)),
    totalFee: 1500,
    paidAmount: 1500,
    duesAmount: 0,
  );

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'planName': planName,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalFee': totalFee,
    'paidAmount': paidAmount,
    'duesAmount': duesAmount,
  };

  factory SubscriptionPlanDetails.fromJson(Map<String, dynamic> json) => SubscriptionPlanDetails(
    planId: json['planId'] ?? '',
    planName: json['planName'] ?? '',
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
    totalFee: (json['totalFee'] as num?)?.toDouble() ?? 0.0,
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
    duesAmount: (json['duesAmount'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Catalog Membership Plan
class MembershipPlan {
  final String id;
  final String name;
  final int durationMonths;
  final String category; // General Fitness, Personal Training, CrossFit, Day Pass
  final double fee;
  final double admissionFee;
  final String description;

  MembershipPlan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.category,
    required this.fee,
    this.admissionFee = 0.0,
    this.description = "",
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'durationMonths': durationMonths,
    'category': category,
    'fee': fee,
    'admissionFee': admissionFee,
    'description': description,
  };

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    durationMonths: json['durationMonths'] ?? 1,
    category: json['category'] ?? 'General Fitness',
    fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
    admissionFee: (json['admissionFee'] as num?)?.toDouble() ?? 0.0,
    description: json['description'] ?? '',
  );
}

/// Gym Physical Locker
class Locker {
  final String id;
  final String lockerCode; // e.g. "L-01"
  final String? assignedMemberId;
  final String? assignedMemberName;
  final double depositAmount;
  final LockerStatus status;

  Locker({
    required this.id,
    required this.lockerCode,
    this.assignedMemberId,
    this.assignedMemberName,
    this.depositAmount = 500.0,
    this.status = LockerStatus.available,
  });

  bool get isOccupied => status == LockerStatus.occupied;

  Locker copyWith({
    String? id,
    String? lockerCode,
    String? assignedMemberId,
    String? assignedMemberName,
    double? depositAmount,
    LockerStatus? status,
  }) => Locker(
    id: id ?? this.id,
    lockerCode: lockerCode ?? this.lockerCode,
    assignedMemberId: assignedMemberId ?? this.assignedMemberId,
    assignedMemberName: assignedMemberName ?? this.assignedMemberName,
    depositAmount: depositAmount ?? this.depositAmount,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'lockerCode': lockerCode,
    'assignedMemberId': assignedMemberId,
    'assignedMemberName': assignedMemberName,
    'depositAmount': depositAmount,
    'status': status.name,
  };

  factory Locker.fromJson(Map<String, dynamic> json) => Locker(
    id: json['id'] ?? '',
    lockerCode: json['lockerCode'] ?? '',
    assignedMemberId: json['assignedMemberId'],
    assignedMemberName: json['assignedMemberName'],
    depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 500.0,
    status: LockerStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => LockerStatus.available,
    ),
  );
}

enum LockerStatus { available, occupied, maintenance, overdue }

/// Real-Time Attendance Check-in Record
class AttendanceRecord {
  final String id;
  final String memberId;
  final String memberName;
  final String? memberPhotoBase64;
  final DateTime checkInTime;
  final String shiftSlot;
  final String checkInMethod; // qr_scan or manual
  final String status; // approved, dues_warning, blocked

  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.memberPhotoBase64,
    required this.checkInTime,
    required this.shiftSlot,
    this.checkInMethod = "qr_scan",
    this.status = "approved",
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'memberName': memberName,
    'memberPhotoBase64': memberPhotoBase64,
    'checkInTime': checkInTime.toIso8601String(),
    'shiftSlot': shiftSlot,
    'checkInMethod': checkInMethod,
    'status': status,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    id: json['id'] ?? '',
    memberId: json['memberId'] ?? '',
    memberName: json['memberName'] ?? '',
    memberPhotoBase64: json['memberPhotoBase64'],
    checkInTime: json['checkInTime'] != null
        ? DateTime.parse(json['checkInTime'])
        : DateTime.now(),
    shiftSlot: json['shiftSlot'] ?? 'Morning',
    checkInMethod: json['checkInMethod'] ?? 'qr_scan',
    status: json['status'] ?? 'approved',
  );
}

/// Financial Transaction Record (Cash / UPI Audit)
class FinancialTransaction {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final String paymentMethod; // upi, cash, card
  final String category; // membership, pt, supplement, locker_deposit
  final String invoiceNumber;
  final double cgst;
  final double sgst;
  final DateTime date;
  final String? notes;

  FinancialTransaction({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.paymentMethod,
    required this.category,
    required this.invoiceNumber,
    this.cgst = 0.0,
    this.sgst = 0.0,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'memberName': memberName,
    'amount': amount,
    'paymentMethod': paymentMethod,
    'category': category,
    'invoiceNumber': invoiceNumber,
    'cgst': cgst,
    'sgst': sgst,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) => FinancialTransaction(
    id: json['id'] ?? '',
    memberId: json['memberId'] ?? '',
    memberName: json['memberName'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    paymentMethod: json['paymentMethod'] ?? 'upi',
    category: json['category'] ?? 'membership',
    invoiceNumber: json['invoiceNumber'] ?? '',
    cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
    sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    notes: json['notes'],
  );
}

/// Workout Set
class WorkoutSet {
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isWarmup;
  final bool isDropSet;
  final bool isCompleted;
  final int rpe; // Rate of Perceived Exertion (1 to 10)

  WorkoutSet({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isWarmup = false,
    this.isDropSet = false,
    this.isCompleted = true,
    this.rpe = 8,
  });

  double get volume => weightKg * reps;

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'weightKg': weightKg,
    'reps': reps,
    'isWarmup': isWarmup,
    'isDropSet': isDropSet,
    'isCompleted': isCompleted,
    'rpe': rpe,
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    setNumber: json['setNumber'] ?? 1,
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
    reps: json['reps'] ?? 0,
    isWarmup: json['isWarmup'] ?? false,
    isDropSet: json['isDropSet'] ?? false,
    isCompleted: json['isCompleted'] ?? true,
    rpe: json['rpe'] ?? 8,
  );
}

/// Single Exercise in a Workout
class ExerciseLog {
  final String exerciseName;
  final String targetMuscle;
  final List<WorkoutSet> sets;
  final String? notes;

  ExerciseLog({
    required this.exerciseName,
    required this.targetMuscle,
    required this.sets,
    this.notes,
  });

  double get totalVolume => sets.fold(0.0, (acc, s) => acc + s.volume);

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'targetMuscle': targetMuscle,
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    exerciseName: json['exerciseName'] ?? '',
    targetMuscle: json['targetMuscle'] ?? '',
    sets: (json['sets'] as List?)
            ?.map((s) => WorkoutSet.fromJson(s))
            .toList() ??
        [],
    notes: json['notes'],
  );
}

/// Completed Workout Session
class WorkoutSession {
  final String id;
  final String memberId;
  final String routineName; // e.g. "Chest & Triceps Hypertrophy"
  final DateTime startedAt;
  final DateTime completedAt;
  final List<ExerciseLog> exercises;
  final double totalVolumeKg;
  final String? notes;

  WorkoutSession({
    required this.id,
    required this.memberId,
    required this.routineName,
    required this.startedAt,
    required this.completedAt,
    required this.exercises,
    required this.totalVolumeKg,
    this.notes,
  });

  int get durationMinutes => completedAt.difference(startedAt).inMinutes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'routineName': routineName,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'totalVolumeKg': totalVolumeKg,
    'notes': notes,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] ?? '',
    memberId: json['memberId'] ?? '',
    routineName: json['routineName'] ?? 'Workout',
    startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : DateTime.now(),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : DateTime.now(),
    exercises: (json['exercises'] as List?)
            ?.map((e) => ExerciseLog.fromJson(e))
            .toList() ??
        [],
    totalVolumeKg: (json['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'],
  );
}

/// Personal Training (PT) Enrollment & Punch Card
class PersonalTrainingSession {
  final String id;
  final String memberId;
  final String memberName;
  final String trainerId;
  final String trainerName;
  final int totalSessions;
  final int completedSessions;
  final double commissionPercent;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  PersonalTrainingSession({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.trainerId,
    required this.trainerName,
    required this.totalSessions,
    this.completedSessions = 0,
    this.commissionPercent = 40.0,
    required this.startDate,
    required this.endDate,
    this.status = "active",
  });

  int get remainingSessions => totalSessions - completedSessions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'memberName': memberName,
    'trainerId': trainerId,
    'trainerName': trainerName,
    'totalSessions': totalSessions,
    'completedSessions': completedSessions,
    'commissionPercent': commissionPercent,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status,
  };

  factory PersonalTrainingSession.fromJson(Map<String, dynamic> json) => PersonalTrainingSession(
    id: json['id'] ?? '',
    memberId: json['memberId'] ?? '',
    memberName: json['memberName'] ?? '',
    trainerId: json['trainerId'] ?? '',
    trainerName: json['trainerName'] ?? '',
    totalSessions: json['totalSessions'] ?? 12,
    completedSessions: json['completedSessions'] ?? 0,
    commissionPercent: (json['commissionPercent'] as num?)?.toDouble() ?? 40.0,
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
    status: json['status'] ?? 'active',
  );
}

/// Walk-in Lead CRM Pipeline
class WalkInLead {
  final String id;
  final String fullName;
  final String phone;
  final String fitnessGoal; // Weight Loss, Muscle Gain, Endurance, General Fitness
  final String interestedPlan;
  final DateTime? trialDate;
  final LeadStage stage;
  final String notes;
  final DateTime createdAt;

  WalkInLead({
    required this.id,
    required this.fullName,
    required this.phone,
    this.fitnessGoal = "Muscle Gain",
    this.interestedPlan = "3 Months General Fitness",
    this.trialDate,
    this.stage = LeadStage.inquiry,
    this.notes = "",
    required this.createdAt,
  });

  WalkInLead copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? fitnessGoal,
    String? interestedPlan,
    DateTime? trialDate,
    LeadStage? stage,
    String? notes,
    DateTime? createdAt,
  }) => WalkInLead(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    fitnessGoal: fitnessGoal ?? this.fitnessGoal,
    interestedPlan: interestedPlan ?? this.interestedPlan,
    trialDate: trialDate ?? this.trialDate,
    stage: stage ?? this.stage,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'phone': phone,
    'fitnessGoal': fitnessGoal,
    'interestedPlan': interestedPlan,
    'trialDate': trialDate?.toIso8601String(),
    'stage': stage.name,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WalkInLead.fromJson(Map<String, dynamic> json) => WalkInLead(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    phone: json['phone'] ?? '',
    fitnessGoal: json['fitnessGoal'] ?? 'General Fitness',
    interestedPlan: json['interestedPlan'] ?? '3 Months',
    trialDate: json['trialDate'] != null ? DateTime.parse(json['trialDate']) : null,
    stage: LeadStage.values.firstWhere(
      (e) => e.name == json['stage'],
      orElse: () => LeadStage.inquiry,
    ),
    notes: json['notes'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );
}

enum LeadStage { inquiry, trial_scheduled, trial_completed, converted, dropped }

/// Gym Equipment Asset
class EquipmentAsset {
  final String id;
  final String name;
  final String category; // Cardio, Strength, Free Weights, Accessories
  final String serialNumber;
  final DateTime purchaseDate;
  final DateTime lastServicedDate;
  final DateTime nextServiceDue;
  final String status; // operational, needs_repair, out_of_order

  EquipmentAsset({
    required this.id,
    required this.name,
    required this.category,
    this.serialNumber = "",
    required this.purchaseDate,
    required this.lastServicedDate,
    required this.nextServiceDue,
    this.status = "operational",
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'serialNumber': serialNumber,
    'purchaseDate': purchaseDate.toIso8601String(),
    'lastServicedDate': lastServicedDate.toIso8601String(),
    'nextServiceDue': nextServiceDue.toIso8601String(),
    'status': status,
  };

  factory EquipmentAsset.fromJson(Map<String, dynamic> json) => EquipmentAsset(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    category: json['category'] ?? 'Strength',
    serialNumber: json['serialNumber'] ?? '',
    purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : DateTime.now(),
    lastServicedDate: json['lastServicedDate'] != null ? DateTime.parse(json['lastServicedDate']) : DateTime.now(),
    nextServiceDue: json['nextServiceDue'] != null ? DateTime.parse(json['nextServiceDue']) : DateTime.now().add(const Duration(days: 90)),
    status: json['status'] ?? 'operational',
  );
}

/// Gym Branch Profile
class BranchProfile {
  final String id;
  final String branchName;
  final String address;
  final String phone;
  final String gstNumber;
  final int capacityLimit;
  final String currencySymbol;

  BranchProfile({
    required this.id,
    required this.branchName,
    required this.address,
    required this.phone,
    this.gstNumber = "",
    this.capacityLimit = 150,
    this.currencySymbol = "₹",
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchName': branchName,
    'address': address,
    'phone': phone,
    'gstNumber': gstNumber,
    'capacityLimit': capacityLimit,
    'currencySymbol': currencySymbol,
  };

  factory BranchProfile.fromJson(Map<String, dynamic> json) => BranchProfile(
    id: json['id'] ?? '',
    branchName: json['branchName'] ?? 'TrackMyGym Hub',
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    gstNumber: json['gstNumber'] ?? '',
    capacityLimit: json['capacityLimit'] ?? 150,
    currencySymbol: json['currencySymbol'] ?? '₹',
  );
}
