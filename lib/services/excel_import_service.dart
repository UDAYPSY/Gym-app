import '../models/gym_models.dart';
import '../constants/app_constants.dart';
import 'gym_service.dart';

class ExcelImportResult {
  final int totalRows;
  final int successfullyImported;
  final int skippedRows;
  final List<String> warnings;
  final List<String> errorMessages;

  ExcelImportResult({
    required this.totalRows,
    required this.successfullyImported,
    required this.skippedRows,
    required this.warnings,
    required this.errorMessages,
  });
}

class ExcelImportService {
  /// Generates a standard CSV template for gym owners to fill in Excel or Google Sheets
  static String generateTemplateCsv() {
    return 'Full Name,Phone Number,Shift Slot,Locker Number,Plan Name,Monthly Fee,Gender,Emergency Contact,Address,Past Dues\n'
        'Aarav Sharma,9876543210,Morning (6:00 AM – 10:00 AM),L-01,3 Months Quarterly Pro,3800,Male,Ramesh Sharma (Father),Sector 14,0\n'
        'Priya Patel,9876543220,Evening Peak (5:00 PM – 10:00 PM),L-02,6 Months Half-Yearly Gold,6800,Female,Kavita Patel,Model Town,2000\n'
        'Rohan Verma,9988776655,All-Access Full Day (24/7),,1 Month General Fitness,1500,Male,Suresh Verma,Civil Lines,0\n';
  }

  /// Parses CSV or TSV text pasted from Excel clipboard or uploaded as CSV
  static Future<ExcelImportResult> parseAndImport(String input, GymService gym) async {
    final lines = input.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) {
      return ExcelImportResult(
        totalRows: 0,
        successfullyImported: 0,
        skippedRows: 0,
        warnings: [],
        errorMessages: ['Provided spreadsheet text is empty.'],
      );
    }

    // Auto-detect delimiter: TSV (Tab separated from Excel copy-paste) vs CSV (comma)
    final firstLine = lines.first;
    final isTsv = firstLine.contains('\t');
    final delimiter = isTsv ? '\t' : ',';

    int startIndex = 0;
    // Check if first row is a header
    final lowerFirst = firstLine.toLowerCase();
    if (lowerFirst.contains('name') || lowerFirst.contains('phone')) {
      startIndex = 1;
    }

    int successCount = 0;
    int skippedCount = 0;
    final List<String> warnings = [];
    final List<String> errorMessages = [];
    final Set<String> batchPhoneSet = {};

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final cols = _splitRow(line, delimiter);

      if (cols.length < 2) {
        skippedCount++;
        warnings.add("Row ${i + 1} skipped: insufficient columns.");
        continue;
      }

      final fullName = cols[0].trim();
      final rawPhone = cols[1].trim();

      if (fullName.isEmpty || rawPhone.isEmpty) {
        skippedCount++;
        warnings.add("Row ${i + 1} skipped: missing name or phone.");
        continue;
      }

      final cleanPhone = GymService.normalizePhone(rawPhone);
      if (cleanPhone.length < 10) {
        skippedCount++;
        errorMessages.add("Row ${i + 1}: Invalid phone number '$rawPhone'. Must be at least 10 digits.");
        continue;
      }

      if (batchPhoneSet.contains(cleanPhone)) {
        skippedCount++;
        warnings.add("Row ${i + 1}: Duplicate phone $cleanPhone within spreadsheet batch. Skipped.");
        continue;
      }

      if (gym.findMemberByPhone(cleanPhone) != null) {
        skippedCount++;
        warnings.add("Row ${i + 1}: Member with phone $cleanPhone already exists in database. Skipped.");
        continue;
      }

      batchPhoneSet.add(cleanPhone);

      // Extract optional columns
      final shift = cols.length > 2 && cols[2].trim().isNotEmpty ? cols[2].trim() : ShiftConstants.morning;
      final locker = cols.length > 3 && cols[3].trim().isNotEmpty ? cols[3].trim() : null;
      final planName = cols.length > 4 && cols[4].trim().isNotEmpty ? cols[4].trim() : "1 Month General Fitness";
      final fee = cols.length > 5 ? (double.tryParse(cols[5].trim()) ?? 1500.0) : 1500.0;
      final gender = cols.length > 6 && cols[6].trim().isNotEmpty ? cols[6].trim() : "Male";
      final emergency = cols.length > 7 ? cols[7].trim() : "";
      final dues = cols.length > 9 ? (double.tryParse(cols[9].trim()) ?? 0.0) : 0.0;

      final newMember = GymMember(
        id: "m_${DateTime.now().millisecondsSinceEpoch}_$i",
        fullName: fullName,
        normalizedPhone: cleanPhone,
        gender: gender,
        emergencyContactName: emergency,
        medicalKyc: MedicalKyc.empty(),
        joinedDate: DateTime.now(),
        shiftSlot: shift,
        lockerId: locker,
        currentPlan: SubscriptionPlanDetails(
          planId: "imported_plan",
          planName: planName,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          totalFee: fee,
          paidAmount: fee - dues,
          duesAmount: dues < 0 ? 0 : dues,
        ),
      );

      try {
        await gym.addMember(newMember);
        successCount++;
      } catch (e) {
        skippedCount++;
        errorMessages.add("Row ${i + 1} ($fullName): ${e.toString()}");
      }
    }

    return ExcelImportResult(
      totalRows: lines.length - startIndex,
      successfullyImported: successCount,
      skippedRows: skippedCount,
      warnings: warnings,
      errorMessages: errorMessages,
    );
  }

  static List<String> _splitRow(String line, String delimiter) {
    if (delimiter == '\t') {
      return line.split('\t');
    }

    // Handles CSV commas with quoted strings
    final List<String> result = [];
    final StringBuffer sb = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString());
    return result;
  }
}
