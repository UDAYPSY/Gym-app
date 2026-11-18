import 'package:flutter/material.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';

class LockerTile extends StatelessWidget {
  final Locker locker;
  final VoidCallback onTap;

  const LockerTile({
    Key? key,
    required this.locker,
    required this.onTap,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (locker.status) {
      case LockerStatus.available:
        return const Color(0xFF334155); // Available Dark Slate
      case LockerStatus.occupied:
        return AppColors.primary; // Active Emerald
      case LockerStatus.overdue:
        return AppColors.statusDues; // Amber Overdue
      case LockerStatus.maintenance:
        return AppColors.statusExpired; // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isOccupied = locker.isOccupied;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOccupied ? statusColor : Colors.white12,
            width: isOccupied ? 2 : 1,
          ),
          boxShadow: isOccupied
              ? [
                  BoxShadow(
                    color: statusColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOccupied ? Icons.lock : Icons.lock_open,
              color: statusColor,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              locker.lockerCode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isOccupied ? (locker.assignedMemberName ?? "Occupied") : "Available",
              style: TextStyle(
                color: isOccupied ? AppColors.textSecondary : AppColors.textMuted,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
