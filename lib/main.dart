import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:app_frontend/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs();

  runApp(
    ChangeNotifierProvider(create: (_) => userProvider, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goaway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorsUtil.primary),
      ),
      home: SplashScreen(),
    );
  }
}
