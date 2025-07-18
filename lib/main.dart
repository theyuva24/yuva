import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'universal/theme/app_theme.dart';
import 'firebase_options.dart';
import 'initial pages/presentation/screens/splash_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        return MaterialApp(
          title: 'YUVA',
          debugShowCheckedModeBanner: false,
          theme: AppThemeLight.theme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
