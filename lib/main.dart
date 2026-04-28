import 'package:flutter/material.dart';

import 'constants/colors.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Operating System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.canvasWhite,
        colorScheme: const ColorScheme.light(
          primary: AppColors.nearBlack,
          onPrimary: AppColors.canvasWhite,
          secondary: AppColors.deepGreen,
          surface: AppColors.canvasWhite,
          onSurface: AppColors.ink,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.canvasWhite,
    );
  }
}
