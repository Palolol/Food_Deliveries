import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(const StepOutApp());
}

class StepOutApp extends StatelessWidget {
  const StepOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STEP-OUT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}
