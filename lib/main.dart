import 'package:chatpoc/models/chat.dart';
import 'package:chatpoc/pages/splash_page.dart';
import 'package:chatpoc/providers/auth_provider.dart';
import 'package:chatpoc/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'configs/supabase_config.dart';
import 'models/message.dart';
import 'models/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(MessageAdapter());

  //await Hive.deleteBoxFromDisk('profiles');

  await Supabase.initialize(
    url: SupabaseConfig.URL,
    anonKey: SupabaseConfig.ANON_KEY,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
