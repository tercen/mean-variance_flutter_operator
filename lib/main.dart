import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:sci_tercen_client/sci_service_factory_web.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/mean_and_cv_screen.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Tercen ServiceFactory (handles auth automatically)
  try {
    final tercenFactory = await createServiceFactoryForWebApp();
    getIt.registerSingleton(tercenFactory);
    debugPrint('✓ Tercen ServiceFactory initialized successfully');
  } catch (e) {
    debugPrint('⚠ Tercen ServiceFactory initialization failed: $e');
    debugPrint('  This is expected in development mode without Tercen context');
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(MeanAndCvApp(prefs: prefs));
}

class MeanAndCvApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MeanAndCvApp({required this.prefs, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Mean-Variance',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const MeanAndCvScreen(),
          );
        },
      ),
    );
  }
}
