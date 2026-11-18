import 'package:flutter/material.dart';
import 'services/gym_service.dart';
import 'services/theme_service.dart';
import 'screens/main_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline-first reactive services
  final themeService = ThemeService();
  await themeService.init();

  final gymService = GymService();
  await gymService.init();

  runApp(const TrackMyGymApp());
}

class TrackMyGymApp extends StatefulWidget {
  const TrackMyGymApp({Key? key}) : super(key: key);

  @override
  State<TrackMyGymApp> createState() => _TrackMyGymAppState();
}

class _TrackMyGymAppState extends State<TrackMyGymApp> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackMyGym — Operating System',
      debugShowCheckedModeBanner: false,
      theme: _themeService.currentTheme,
      home: const MainHubScreen(),
    );
  }
}
