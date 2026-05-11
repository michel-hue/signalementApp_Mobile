// lib/src/widgets/confidentialite_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// CONFIDENTIALITÉ SHEET — Charte Graphique RuePropre 2026
// Vert #2E7D32 | Bleu #1565C0 | Blanc #FFFFFF
// Montserrat (titres) | Open Sans (corps)
// ============================================================

const Color _primaryGreen  = Color(0xFF2E7D32);
const Color _secondaryBlue = Color(0xFF1565C0);
const Color _lightGreen    = Color(0xFFE8F5E9);
const Color _lightBlue     = Color(0xFFE3F2FD);
const Color _surface       = Color(0xFFFFFFFF);
const Color _bgPage        = Color(0xFFF7FBF7);
const Color _textPrimary   = Color(0xFF1A2B1A);
const Color _textSecondary = Color(0xFF546E4F);
const Color _textHint      = Color(0xFF90A890);

class ConfidentialiteSheet extends StatelessWidget {
  final VoidCallback onAccept;
  const ConfidentialiteSheet({super.key, required this.onAccept});

  static const String _prefKey = 'confidentialite_accepted';

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs   = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_prefKey) ?? false;
    if (!accepted && context.mounted) {
      showModalBottomSheet(
        context:          context,
        isDismissible:    false,
        enableDrag:       false,
        isScrollControlled: true,
        backgroundColor:  Colors.transparent,
        builder: (_) => ConfidentialiteSheet(
          onAccept: () async {
            await prefs.setBool(_prefKey, true);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Poignée ──────────────────────────────────────
          SizedBox(height: 12.h),
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8D0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // ── En-tête premium ──────────────────────────────
          _buildHeader(),

          // ── Corps scrollable ─────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: Column(
                children: [
                  _buildPrivacyItem(
                    icon:    Icons.location_on_rounded,
                    color:   _primaryGreen,
                    bgColor: _lightGreen,
                    title:   'Localisation GPS',
                    desc:    'Utilisée uniquement pour situer votre signalement. Elle n\'est pas conservée une fois l\'envoi effectué.',
                  ),
                  _buildPrivacyItem(
                    icon:    Icons.shield_rounded,
                    color:   _secondaryBlue,
                    bgColor: _lightBlue,
                    title:   'Anonymat total garanti',
                    desc:    'Aucun nom, adresse email ou identifiant personnel n\'est requis. Vous restez 100 % anonyme.',
                  ),
                  _buildPrivacyItem(
                    icon:    Icons.camera_alt_rounded,
                    color:   const Color(0xFFF57F17),
                    bgColor: const Color(0xFFFFF8E1),
                    title:   'Photo facultative',
                    desc:    'Assurez-vous que vos photos ne contiennent pas de personnes identifiables avant de les partager.',
                  ),
                  _buildPrivacyItem(
                    icon:    Icons.delete_outline_rounded,
                    color:   const Color(0xFF7B1FA2),
                    bgColor: const Color(0xFFF3E5F5),
                    title:   'Conservation limitée',
                    desc:    'Vos données sont conservées 30 jours après traitement, puis supprimées définitivement.',
                    isLast:  true,
                  ),

                  SizedBox(height: 16.h),

                  // ── Note d'usage ──
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_lightGreen, const Color(0xFFF0FBF0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: _primaryGreen.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(color: _primaryGreen, shape: BoxShape.circle),
                          child: Icon(Icons.eco_rounded, size: 14.r, color: Colors.white),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notre engagement',
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 12.sp, fontWeight: FontWeight.w700, color: _primaryGreen),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                'Ces données servent exclusivement à améliorer la propreté de la rue Koné Tiémoman, Abobo. Elles ne sont jamais vendues ni partagées.',
                                style: TextStyle(fontFamily: 'OpenSans', fontSize: 11.sp, color: _textSecondary, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // ── Bouton Accepter ──────────────────────────────
          _buildAcceptButton(),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFF0D2D11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Icône avec cercles décoratifs
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Center(
                  child: Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 30.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Avant de commencer',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'RuePropre respecte votre vie privée',
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Colors.white70,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 14.h),
          // Slogan charte
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Text(
              '« Signaler aujourd\'hui, vivre mieux demain »',
              style: TextStyle(
                fontFamily: 'OpenSans',
                color: Colors.white.withOpacity(0.9),
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Item confidentialité ────────────────────────────────
  Widget _buildPrivacyItem({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne verticale + icône
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18.r),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32.h,
                margin: EdgeInsets.symmetric(vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EEE0),
                  borderRadius: BorderRadius.circular(1.r),
                ),
              ),
          ],
        ),
        SizedBox(width: 14.w),
        // Contenu
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h, top: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 12.sp,
                    color: _textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bouton Accepter ─────────────────────────────────────
  Widget _buildAcceptButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: const Color(0xFFE0EEE0), width: 1)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20.r),
                  SizedBox(width: 8.w),
                  Text(
                    'J\'ai compris et j\'accepte',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'En acceptant, vous consentez à notre politique de confidentialité.',
            style: TextStyle(fontFamily: 'OpenSans', fontSize: 11.sp, color: _textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}