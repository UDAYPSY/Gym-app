import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class RestTimerDialog extends StatefulWidget {
  final int initialSeconds;

  const RestTimerDialog({Key? key, this.initialSeconds = 90}) : super(key: key);

  @override
  State<RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<RestTimerDialog> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
      }
    });
  }

  void _addSeconds(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
      if (!_isRunning) _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.initialSeconds > 0
        ? (_remainingSeconds / widget.initialSeconds).clamp(0.0, 1.0)
        : 0.0;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.timer, color: AppColors.primary),
          SizedBox(width: 8),
          Text(
            "Rest Interval Timer",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remainingSeconds > 10 ? AppColors.primary : AppColors.statusExpired,
                  ),
                ),
              ),
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _timerButton("+30s", () => _addSeconds(30)),
              _timerButton("+60s", () => _addSeconds(60)),
              _timerButton("+90s", () => _addSeconds(90)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
          child: const Text("Skip Rest", style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isRunning) {
              _timer?.cancel();
              setState(() => _isRunning = false);
            } else {
              _startTimer();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRunning ? AppColors.accent : AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_isRunning ? "Pause" : "Resume"),
        ),
      ],
    );
  }

  Widget _timerButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(text),
    );
  }
}
