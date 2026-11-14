import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/backend.dart';
import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/monitoring/monitoring.dart';
import 'package:app_frontend/core/notifications/push_notifications.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_utils/page_transitions.dart';
import 'package:app_frontend/global_utils/bottom_bar/bottom_bar.dart';
import 'package:app_frontend/providers/language_provider.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:app_frontend/splash_screen.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local development reads .env; release builds pick their environment's file, e.g.
  // --dart-define=ENV_FILE=env/prod.env (see README.md, Android releases).
  await dotenv.load(
    fileName: const String.fromEnvironment('ENV_FILE', defaultValue: '.env'),
  );
  // Error tracking first, so crashes during start-up are reported too.
  await runWithMonitoring(() async {
    // The language's texts load before the first screen, so nothing flashes in English.
    await I18n.load(await I18n.detect());
    await I18n.loadCurrency();
    Backend.configure();
    await Analytics.init();
    await PushNotifications.init();

    final userProvider = UserProvider();
    // Speed (4.7): the session is restored (a network call) while the splash screen plays, not before the app
    // starts; the splash screen waits for it before opening Home or sign-in.
    int? signedInAs;
    userProvider.restoreSession().then((_) {
      // Push follows the signed-in account: registered at start-up and after every sign-in.
      signedInAs = userProvider.user?.id;
      if (signedInAs != null) PushNotifications.onSignedIn();
      userProvider.addListener(() {
        final id = userProvider.user?.id;
        if (id != null && id != signedInAs) PushNotifications.onSignedIn();
        signedInAs = id;
      });
    });

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => userProvider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final user = context.read<UserProvider>().user;
    // Rebuilt from scratch in a new language (every text is read again); after changing it on the Profile tab,
    // the app opens there instead of the splash screen.
    return MaterialApp(
      key: ValueKey(language.code),
      title: 'GoAwayGo',
      locale: Locale(language.code),
      supportedLocales: [for (final l in appLanguages) Locale(l.code)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
      home: language.changedHere
          ? BottomBar(user: user, initialPage: 3)
          : SplashScreen(),
    );
  }
}
