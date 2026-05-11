// lib/src/views/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signalementapp/src/Theme/app_colors.dart';
import 'package:signalementapp/src/views/confidentialite_page.dart';
import 'package:signalementapp/src/views/navigation/acceuil_page.dart';
import 'package:signalementapp/src/views/navigation/signalement_page.dart';
import 'package:signalementapp/src/views/navigation/suivi_page.dart';
import 'package:signalementapp/src/widgets/bottomNavigate_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Afficher le sheet de confidentialité au premier lancement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConfidentialiteSheet.showIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemsTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          AcceuilPage(),
          SuiviPage(),
          SignalementPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigatBar(
        currentIndex: _selectedIndex,
        onTap: _onItemsTapped,
      ),
    );
  }
}