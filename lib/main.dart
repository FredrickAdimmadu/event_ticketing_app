import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:event/signallingservice.dart';
import 'event_upload.dart';
import 'firebase_options.dart';
import 'homepage.dart';
import 'joinscreen.dart';
import 'loginpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';


late Size mq;
final navigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Set up portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set up immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Firebase and other services asynchronously
  await _initializeApp();

  runApp(MyApp());
}


Future<void> _initializeApp() async {
  if (kIsWeb) {
    // Specific initialization for Firebase when running on web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBZSM4Zn50SXPpf1xv_uWfv4U1AKcJmBzI',
        appId: '1:1056062674368:web:18c6e70c12adedb4d26425',
        messagingSenderId: '1056062674368',
        projectId: 'instagram-8be62',
        storageBucket: 'instagram-8be62.appspot.com',
      ),
    );
  } else {
    // Initialization for non-web platforms
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await requestPermissions();
  }
}

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.location,
    Permission.notification,
    Permission.bluetooth,
    Permission.accessMediaLocation,
    Permission.microphone,
    Permission.photos,
    Permission.videos,
  ].request();

  if (kDebugMode) {
    statuses.forEach((permission, status) {
      print('$permission: $status');
    });
  }
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Return MaterialApp
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          return HomePage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
