// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medi_help/routes.dart';
import 'package:medi_help/services/session_service.dart';
import 'package:medi_help/providers/reminder_provider.dart';
import 'package:medi_help/providers/activity_provider.dart';
import 'package:medi_help/providers/app_settings_provider.dart';
import 'package:medi_help/providers/location_provider.dart'; // ← TAMBAHAN
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appSettings = AppSettingsProvider();
  await appSettings.initNotifications();

  final reminderProvider = ReminderProvider();
  reminderProvider.setSettingsProvider(appSettings);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await reminderProvider.loadRemindersFromFirestore();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionService()),
        ChangeNotifierProvider.value(value: reminderProvider),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider(create: (_) => LocationProvider()), // ← TAMBAHAN
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'MediHelp',
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A5F8A),
              brightness: Brightness.light,
            ),
            primaryColor: const Color(0xFF1A5F8A),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A5F8A),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: const CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A5F8A),
              brightness: Brightness.dark,
            ),
            primaryColor: const Color(0xFF1A5F8A),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A2E),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: const CardThemeData(
              elevation: 2,
              color: Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
        );
      },
    );
  }
}