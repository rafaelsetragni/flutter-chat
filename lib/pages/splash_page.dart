import 'package:chatpoc/pages/chat_list_page.dart';
import 'package:chatpoc/pages/login_entry_page.dart';
import 'package:chatpoc/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Page to redirect users to the appropriate page depending on the initial auth state
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    final currentUser = authProvider.currentUserProfile;
    if (currentUser == null) {
      Navigator.of(context).pushAndRemoveUntil(
        LoginEntryPage.route(),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      ChatListPage.route(currentUser.id),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: preloader);
  }
}
