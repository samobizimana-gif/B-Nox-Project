import 'package:bnox/communication/transport/transport_manager.dart';
import 'package:bnox/core/notification_manager.dart';
import 'package:bnox/core/theme_manager.dart';
import 'package:bnox/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/constants.dart';
import 'core/account_manager.dart';
import 'core/session_manager.dart';
import 'core/security_manager.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);


  await NotificationManager.init();
  await ThemeManager.loadTheme();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: BnoxColors.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BnoxApp());
}



class BnoxApp extends StatelessWidget {
  const BnoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'B-NOX',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme, // Il faut créer ce thème
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const _Bootstrapper(),
        );
      },
    );
  }
}



class _Bootstrapper extends StatefulWidget {
  const _Bootstrapper();

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // 1. Chercher si un compte est actif (session)
    final activeId = await SessionManager.getActiveAccount();
    if (!mounted) return;

    if (activeId == null) {
      // Pas de session -> Welcome
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      return;
    }

    // 2. Récupérer les infos du compte
    final account = await AccountManager.findById(activeId);
    if (!mounted) return;

    if (account == null) {
      // Compte introuvable -> logout
      await SessionManager.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      return;
    }

    // Initialise le moteur WebRTC pour ce compte
    TransportManager.init(account);

    // 3. Vérifier si la sécurité est active
    final methods = await SecurityManager.loadMethods(activeId);
    final hasSecurity = methods['biometric'] == true || methods['pin'] == true;

    if (!mounted) return;

    // 4. Redirection
    if (hasSecurity) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => LockScreen(account: account)));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => HomeScreen(account: account)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: BnoxColors.dark,
      body: Center(child: CircularProgressIndicator(color: BnoxColors.cyan)),
    );
  }
}
