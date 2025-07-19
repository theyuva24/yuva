import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'universal/theme/app_theme.dart';
import 'firebase_options.dart';
import 'initial pages/presentation/screens/splash_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'profile/controllers/profile_controller.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'challenge/model/challenge_model.dart';
import 'challenge/model/submission_model.dart';
import 'challenge/model/timestamp_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ChallengeAdapter());
  Hive.registerAdapter(SubmissionAdapter());
  Hive.registerAdapter(TimestampAdapter());

  // Open boxes
  await Hive.openBox('challenges');
  print('Hive box "challenges" opened');
  await Hive.openBox('challenge_details');
  print('Hive box "challenge_details" opened');
  await Hive.openBox('submissions');
  print('Hive box "submissions" opened');

  runApp(const YuvaApp());
}

class YuvaApp extends StatelessWidget {
  const YuvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
        375,
        812,
      ), // iPhone X size, adjust if your design uses a different base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (_) => ProfileController(),
          child: MaterialApp(
            title: 'YUVA',
            debugShowCheckedModeBanner: false,
            theme: AppThemeLight.theme,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
