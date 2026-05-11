import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signalementapp/src/service/api_service.dart';
import 'package:signalementapp/src/views/splash_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService.init();

  await Supabase.initialize(
       url: 'https://nhzxdpxxkakbekiuciae.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oenhkcHh4a2FrYmVraXVjaWFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0NjkwMzcsImV4cCI6MjA5MjA0NTAzN30.olMB5CHSjGPoPqlDiyf2FXx2_rlODJhBlKXSFDbL1YE',
       );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SIGNALEMENT',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            home: const SplashPage(),
          );
        }
    );
  }
}