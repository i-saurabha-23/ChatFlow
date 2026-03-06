import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:interview/firebase_options.dart';
import 'package:interview/services/push_notification_service.dart';
import 'package:interview/views/auth/sign_in_screen.dart';
import 'package:interview/views/auth/sign_up_screen.dart';
import 'package:interview/views/chat/main_chats_screen.dart';
import 'package:interview/views/splash/splash_screen_one.dart';
import 'package:interview/views/splash/splash_screen_three.dart';
import 'package:interview/views/splash/splash_screen_two.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportsFirebase =
      !kIsWeb &&
      !const {
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }.contains(defaultTargetPlatform);

  if (supportsFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.instance.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatFlow',
      initialRoute: SplashScreenOne.routeName,
      routes: {
        SplashScreenOne.routeName: (_) => const SplashScreenOne(),
        SplashScreenTwo.routeName: (_) => const SplashScreenTwo(),
        SplashScreenThree.routeName: (_) => const SplashScreenThree(),
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        SignInScreen.routeName: (_) => const SignInScreen(),
        MainChatsScreen.routeName: (_) => const MainChatsScreen(),
      },
    );
  }
}
