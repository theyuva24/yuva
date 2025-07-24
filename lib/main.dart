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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'chat/page/chats_page.dart';
import 'connect/pages/post_details_loader.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Optionally handle background notification
}

void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            channelDescription: 'Default channel for notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Handle notification tap (navigate to chat, etc.)
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ChallengeAdapter());
  Hive.registerAdapter(SubmissionAdapter());
  Hive.registerAdapter(TimestampAdapter());

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  setupFirebaseMessaging();

  // Request notification permission (for Android 13+ and iOS)
  await FirebaseMessaging.instance.requestPermission();

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
            darkTheme: AppThemeDark.theme,
            themeMode: ThemeMode.system,
            home: const SplashScreen(),
            navigatorObservers: [routeObserver],
          ),
        );
      },
    );
  }
}
