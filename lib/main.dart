import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/monitoring/monitoring.dart';
import 'package:app_frontend/core/notifications/push_notifications.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_utils/page_transitions.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:app_frontend/splash_screen.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local development reads .env; release builds pick their environment's file, e.g.
  // --dart-define=ENV_FILE=env/staging.env (see docs/release-android.md).
  await dotenv.load(
    fileName: const String.fromEnvironment('ENV_FILE', defaultValue: '.env'),
  );
  // Error tracking first, so crashes during start-up are reported too.
  await runWithMonitoring(() async {
    Backend.configure();
    await Analytics.init();
    await PushNotifications.init();

    final userProvider = UserProvider();
    await userProvider.restoreSession();
    // Push follows the signed-in account: registered at start-up and after every sign-in.
    var signedInAs = userProvider.user?.id;
    if (signedInAs != null) PushNotifications.onSignedIn();
    userProvider.addListener(() {
      final id = userProvider.user?.id;
      if (id != null && id != signedInAs) PushNotifications.onSignedIn();
      signedInAs = id;
    });

    runApp(
      ChangeNotifierProvider(create: (_) => userProvider, child: const MyApp()),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoAwayGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorsUtil.primary),
        // Pushed pages slide and fade in from the right (iOS keeps its own swipe-back transition).
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: SharedAxisPageTransitionsBuilder(),
            TargetPlatform.linux: SharedAxisPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: SplashScreen(),
    );
  }
}
