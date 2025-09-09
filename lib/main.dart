import 'package:flutter/material.dart';
import 'package:campus_life_hub/pages/onboarding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:campus_life_hub/pages/login.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:campus_life_hub/pages/home.dart';
import 'package:campus_life_hub/pages/timetable/timetable_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => TimetableState(),
      child: MyApp(seenOnboarding: seenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: seenOnboarding ? Login() : OnboardingScreen(),
      routes: {
        '/home': (context) => const Home(),
      },
    );
  }
}