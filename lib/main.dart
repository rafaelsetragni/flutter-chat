import 'package:flutter/material.dart';
import 'package:chatpoc/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chatpoc/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://mpykvngknvdnphclcacd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1weWt2bmdrbnZkbnBoY2xjYWNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNTgyNDIsImV4cCI6MjA2ODgzNDI0Mn0.Sqy5_lcLWlc9vDVnMSmnJJIAXBw0omX2yZWJCMDwBDg',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Chat App',
      theme: appTheme,
      home: const SplashPage(),
    );
  }
}
