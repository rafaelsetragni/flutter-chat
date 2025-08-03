import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginEntryPage extends StatefulWidget {
  const LoginEntryPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider(
        create: (_) => LoginEntryProvider(context.read<AuthProvider>()),
        child: const LoginEntryPage(),
      ),
    );
  }

  @override
  _LoginEntryPageState createState() => _LoginEntryPageState();
}

class LoginEntryProvider extends ChangeNotifier {
  final AuthProvider auth;

  LoginEntryProvider(this.auth);

  void loginWithEmail() {
    // Navegar para login com email e senha
  }

  void loginWithPhone() {
    // Navegar para login com telefone
  }

  void loginWithGoogle() {
    auth.signInWithGoogle();
  }

  void loginWithFacebook() {
    auth.signInWithFacebook();
  }

  void goToRegister() {
    // Navegar para a tela de registro
  }
}

class _LoginEntryPageState extends State<LoginEntryPage> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    // This method can be removed or left empty since email/password form is removed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<LoginEntryProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  'Sign in',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthButton(
                        onPressed: provider.loginWithEmail,
                        icon: FontAwesomeIcons.envelope,
                        label: 'Login with email and password',
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      AuthButton(
                        onPressed: provider.loginWithPhone,
                        icon: FontAwesomeIcons.phone,
                        label: 'Login with phone number',
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      AuthButton(
                        onPressed: provider.loginWithGoogle,
                        icon: FontAwesomeIcons.google,
                        label: 'Login with Google',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        borderColor: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      AuthButton(
                        onPressed: provider.loginWithFacebook,
                        icon: FontAwesomeIcons.facebookF,
                        label: 'Login with Facebook',
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: provider.goToRegister,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    "Don't have an account? Register one",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: TextDecoration.underline,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final double iconSize;

  const AuthButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 0,
            child: FaIcon(icon, size: iconSize),
          ),
          Center(
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
