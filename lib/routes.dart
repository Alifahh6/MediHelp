// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:medi_help/screens/splash_screen.dart';
import 'package:medi_help/screens/home_screen.dart';
import 'package:medi_help/screens/login_screen.dart';
import 'package:medi_help/screens/register_screen.dart';
import 'package:medi_help/screens/profile_screen.dart';
import 'package:medi_help/screens/record_screen.dart';
import 'package:medi_help/screens/nearby_screen.dart';
import 'package:medi_help/screens/queue_screen.dart';
import 'package:medi_help/screens/reminder_screen.dart';
import 'package:medi_help/screens/history_screen.dart';
import 'package:medi_help/screens/faq_screen.dart';        // TAMBAHKAN
import 'package:medi_help/screens/activity_screen.dart';   // TAMBAHKAN

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String records = '/records';
  static const String nearby = '/nearby';
  static const String queue = '/queue';
  static const String reminder = '/reminder';
  static const String history = '/history';
  static const String faq = '/faq';           // TAMBAHKAN
  static const String activity = '/activity'; // TAMBAHKAN

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case records:
        return MaterialPageRoute(builder: (_) => const RecordsScreen());
      case nearby:
        return MaterialPageRoute(builder: (_) => const NearbyScreen());
      case queue:
        return MaterialPageRoute(builder: (_) => const QueueScreen());
      case reminder:
        return MaterialPageRoute(builder: (_) => const ReminderScreen());
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case faq:                               // TAMBAHKAN
        return MaterialPageRoute(builder: (_) => const FaqScreen());
      case activity:                          // TAMBAHKAN
        return MaterialPageRoute(builder: (_) => const ActivityScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}