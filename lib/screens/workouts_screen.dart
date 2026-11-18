import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';
import '../widgets/rest_timer_dialog.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String _selectedRoutine = "Chest & Triceps Hypertrophy";
  String? _selectedMemberId;

  // Active workout draft state
  final List<DraftExercise> _activeExercises = [];
  DateTime _workoutStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPresetRoutine(_selectedRoutine);
  }

  void _loadPresetRoutine(String routine) {
    _activeExercises.clear();
    _workoutStartedAt = DateTime.now();

    if (routine.contains("Chest")) {
      _activeExercises.addAll([
        DraftExercise(name: "Barbell Bench Press", targetMuscle: "Chest", sets: [
          DraftSet(weight: 60, reps: 12, isWarmup: true),
          DraftSet(weight: 80, reps: 10),
          DraftSet(weight: 90, reps: 8),
          DraftSet(weight: 100, reps: 6),
        ]),
        DraftExercise(name: "Incline Dumbbell Press", targetMuscle: "Chest", sets: [
          DraftSet(weight: 24, reps: 12),
          DraftSet(weight: 28, reps: 10),
          DraftSet(weight: 30, reps: 8),
        ]),
        DraftExercise(name: "Triceps Rope Pushdown", targetMuscle: "Triceps", sets: [
          DraftSet(weight: 20, reps: 15),
          DraftSet(weight: 25, reps: 12),
          DraftSet(weight: 30, reps: 10),
        ]),
      ]);
    } else if (routine.contains("Back")) {
      _activeExercises.addAll([
        DraftExercise(name: "Barbell Deadlift", targetMuscle: "Back", sets: [
          DraftSet(weight: 70, reps: 10, isWarmup: true),
          DraftSet(weight: 110, reps: 8),
          DraftSet(weight: 130, reps: 5),
        ]),
        DraftExercise(name: "Lat Pulldown (Wide Grip)", targetMuscle: "Back", sets: [
          DraftSet(weight: 45, reps: 12),
          DraftSet(weight: 55, reps: 10),
          DraftSet(weight: 65, reps: 8),
        ]),
        DraftExercise(name: "Barbell Bicep Curl", targetMuscle: "Biceps", sets: [
          DraftSet(weight: 25, reps: 12),
          DraftSet(weight: 30, reps: 10),
          DraftSet(weight: 35, reps: 8),
        ]),
      ]);
    } else {
      _activeExercises.addAll([
        DraftExercise(name: "Barbell Back Squat", targetMuscle: "Legs", sets: [
          DraftSet(weight: 60, reps: 12, isWarmup: true),
          DraftSet(weight: 100, reps: 10),
          DraftSet(weight: 120, reps: 8),
        ]),
        DraftExercise(name: "Leg Press (45 Degree)", targetMuscle: "Legs", sets: [
          DraftSet(weight: 140, reps: 12),
          DraftSet(weight: 180, reps: 10),
        ]),
      ]);
    }
  }

  double get _totalVolumeKg {
    double total = 0.0;
    for (var ex in _activeExercises) {
      for (var s in ex.sets) {
        if (s.isCompleted) total += s.weight * s.reps;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final gym = GymService();
    final members = gym.members;
    if (_selectedMemberId == null && members.isNotEmpty) {
      _selectedMemberId = members.first.id;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Routine Selector, Member Selector, Rest Timer, Finish Workout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Interactive Workout Logger",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Volume: ${_totalVolumeKg.toStringAsFixed(0)} kg lifted",
                      style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const RestTimerDialog(),
                        );
                      },
                      icon: const Icon(Icons.timer, size: 18),
                      label: const Text("Rest Timer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _saveWorkoutSession,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text("Finish & Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Select Member and Routine Controls
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedMemberId,
                    dropdownColor: AppColors.surfaceElevated,
                    decoration: const InputDecoration(labelText: "Lifting Member / Athlete"),
                    items: members.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text("${m.fullName} (${m.shiftSlot.split(' ')[0]})"),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedMemberId = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    value: _selectedRoutine,
                    dropdownColor: AppColors.surfaceElevated,
                    decoration: const InputDecoration(labelText: "Workout Routine"),
                    items: const [
                      DropdownMenuItem(value: "Chest & Triceps Hypertrophy", child: Text("Chest & Triceps Hypertrophy")),
                      DropdownMenuItem(value: "Back & Biceps Power", child: Text("Back & Biceps Power")),
                      DropdownMenuItem(value: "Leg Day Quad Focus", child: Text("Leg Day Quad Focus")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRoutine = val;
                          _loadPresetRoutine(val);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Exercises and Sets List
            Expanded(
              child: ListView.builder(
                itemCount: _activeExercises.length,
                itemBuilder: (context, exIndex) {
                  final exercise = _activeExercises[exIndex];
                  return _buildExerciseCard(exercise, exIndex);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(DraftExercise exercise, int exIndex) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exercise.targetMuscle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      exercise.sets.add(DraftSet(
                        weight: exercise.sets.isNotEmpty ? exercise.sets.last.weight : 20,
                        reps: 10,
                      ));
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Set"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sets Header Table
            Row(
              children: const [
                SizedBox(width: 40, child: Text("SET", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text("WEIGHT (KG)", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text("REPS", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 70, child: Text("DONE", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),

            // Sets Rows
            ...exercise.sets.asMap().entries.map((entry) {
              final sIndex = entry.key;
              final set = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        "${sIndex + 1}",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextFormField(
                          initialValue: set.weight.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                          onChanged: (val) {
                            set.weight = double.tryParse(val) ?? set.weight;
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextFormField(
                          initialValue: set.reps.toString(),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                          onChanged: (val) {
                            set.reps = int.tryParse(val) ?? set.reps;
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 70,
                      child: Checkbox(
                        value: set.isCompleted,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            set.isCompleted = val ?? false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _saveWorkoutSession() async {
    if (_selectedMemberId == null) return;

    final exercises = _activeExercises.map((e) => ExerciseLog(
      exerciseName: e.name,
      targetMuscle: e.targetMuscle,
      sets: e.sets.map((s) => WorkoutSet(
        setNumber: e.sets.indexOf(s) + 1,
        weightKg: s.weight,
        reps: s.reps,
        isWarmup: s.isWarmup,
        isCompleted: s.isCompleted,
      )).toList(),
    )).toList();

    final session = WorkoutSession(
      id: "w_${DateTime.now().millisecondsSinceEpoch}",
      memberId: _selectedMemberId!,
      routineName: _selectedRoutine,
      startedAt: _workoutStartedAt,
      completedAt: DateTime.now(),
      exercises: exercises,
      totalVolumeKg: _totalVolumeKg,
    );

    await GymService().saveWorkoutSession(session);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Workout session saved! Total volume: ${_totalVolumeKg.toStringAsFixed(0)} kg.")),
    );
  }
}

class DraftExercise {
  final String name;
  final String targetMuscle;
  final List<DraftSet> sets;

  DraftExercise({required this.name, required this.targetMuscle, required this.sets});
}

class DraftSet {
  double weight;
  int reps;
  bool isWarmup;
  bool isCompleted;

  DraftSet({
    required this.weight,
    required this.reps,
    this.isWarmup = false,
    this.isCompleted = true,
  });
}
