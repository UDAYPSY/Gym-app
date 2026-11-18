import 'package:flutter/material.dart';
import '../services/gym_service.dart';
import '../services/theme_service.dart';
import '../constants/app_constants.dart';
import 'dashboard_screen.dart';
import 'members_screen.dart';
import 'attendance_screen.dart';
import 'lockers_screen.dart';
import 'workouts_screen.dart';
import 'payments_screen.dart';
import 'leads_screen.dart';
import 'tools_screen.dart';

class MainHubScreen extends StatefulWidget {
  const MainHubScreen({Key? key}) : super(key: key);

  @override
  State<MainHubScreen> createState() => _MainHubScreenState();
}

class _MainHubScreenState extends State<MainHubScreen> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gym = GymService();
    final themeService = ThemeService();

    final screens = [
      DashboardScreen(onNavigate: _navigateTo),
      const MembersScreen(),
      const AttendanceScreen(),
      const LockersScreen(),
      const WorkoutsScreen(),
      const PaymentsScreen(),
      const LeadsScreen(),
      const ToolsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  gym.branch.branchName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              // Theme Toggle
              IconButton(
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: AppColors.primaryLight,
                ),
                tooltip: "Toggle Theme",
                onPressed: () => themeService.toggleTheme(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              // Persistent Navigation Rail on Wide Screens (Desktop/Web/Tablet)
              if (isWide)
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _navigateTo,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.surface,
                  selectedIconTheme: const IconThemeData(color: AppColors.primary),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text("Dashboard")),
                    NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text("Members")),
                    NavigationRailDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: Text("QR Gate")),
                    NavigationRailDestination(icon: Icon(Icons.lock_outline), selectedIcon: Icon(Icons.lock), label: Text("Lockers")),
                    NavigationRailDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: Text("Workouts")),
                    NavigationRailDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: Text("Ledger")),
                    NavigationRailDestination(icon: Icon(Icons.filter_alt_outlined), selectedIcon: Icon(Icons.filter_alt), label: Text("Leads")),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text("Tools")),
                  ],
                ),
              if (isWide) const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),

              // Screen Viewport
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),
          // Bottom Navigation Bar on Compact Mobile Screens
          bottomNavigationBar: !isWide
              ? BottomNavigationBar(
                  currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
                  onTap: _navigateTo,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppColors.surface,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textSecondary,
                  selectedFontSize: 11,
                  unselectedFontSize: 10,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Hub"),
                    BottomNavigationBarItem(icon: Icon(Icons.people), label: "Members"),
                    BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Gate"),
                    BottomNavigationBarItem(icon: Icon(Icons.lock), label: "Lockers"),
                    BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Workouts"),
                  ],
                )
              : null,
        );
      },
    );
  }
}
