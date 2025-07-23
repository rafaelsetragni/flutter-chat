import 'package:chatpoc/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:chatpoc/pages/chat_page.dart';
import 'package:chatpoc/pages/register_page.dart';
import 'package:chatpoc/utils/constants.dart';

/// Page to redirect users to the appropriate page depending on the initial auth state
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // await for for the widget to mount
    await Future.delayed(Duration.zero);

    final session = supabase.auth.currentSession;
    if (session == null) {
      Navigator.of(context)
          .pushAndRemoveUntil(LoginPage.route(), (route) => false);
      return;
    }

    final myUserId = supabase.auth.currentUser?.id;
    if (myUserId == null){
      Navigator.of(context)
          .pushAndRemoveUntil(LoginPage.route(), (route) => false);
      return;
    }


    Navigator.of(context)
        .pushAndRemoveUntil(ChatPage.route(myUserId), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: preloader);
  }
}
