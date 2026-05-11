import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signalementapp/src/Theme/app_colors.dart';
import 'package:signalementapp/src/views/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _fadeController.forward();
    _slideController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MyHomePage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF1B5E20),
                  Color(0xFF0D2D11),
                ],
              ),
            ),
          ),

          // Lignes décoratives
          CustomPaint(
            painter: DiagonalLinesPainter(),
            child: const SizedBox.expand(),
          ),

          // Cercle décoratif flou en haut à droite
          Positioned(
            top: -80.r,
            right: -60.r,
            child: Container(
              width: 260.r,
              height: 260.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40.r,
            left: -80.r,
            child: Container(
              width: 200.r,
              height: 200.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Icône animée
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          padding: EdgeInsets.all(22.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(28.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.energy_savings_leaf_rounded,
                            size: 56.r,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Nom de l'app
                      Text(
                        'RuePropre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Sous-titre
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'Rue Koné Tiémoman · Abobo',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      SizedBox(height: 48.h),

                      // Slogan
                      Text(
                        'Signalez.\nEnsemble.\nAméliorons.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Séparateur décoratif
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              height: 2,
                              width: 20.w,
                              color: Colors.white24),
                          SizedBox(width: 8.w),
                          Container(
                              height: 4,
                              width: 40.w,
                              color: Colors.white54),
                          SizedBox(width: 8.w),
                          Container(
                              height: 2,
                              width: 20.w,
                              color: Colors.white24),
                        ],
                      ),

                      const Spacer(flex: 2),

                      // Barre de progression animée
                      Column(
                        children: [
                          AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: _progressAnim.value,
                                backgroundColor: Colors.white24,
                                valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Chargement...',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12.sp,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32.h),

                      // Footer
                      Text(
                        'CITOYENNETÉ • ABIDJAN • 2026',
                        style: TextStyle(
                          color: Colors.white38,
                          letterSpacing: 2,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5;
    for (var i = -size.width; i < size.width * 2; i += 40) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}