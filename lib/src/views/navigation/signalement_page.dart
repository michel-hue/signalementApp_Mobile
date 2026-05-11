// lib/src/views/navigation/signalement_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signalementapp/src/Theme/app_colors.dart';
import 'package:signalementapp/src/service/api_service.dart';

// ============================================================
// SIGNALEMENT PAGE — Charte Graphique RuePropre 2026
// Vert #2E7D32 | Bleu #1565C0 | Blanc #FFFFFF
// Montserrat (titres) | Open Sans (corps)
// ============================================================

const List<Map<String, dynamic>> _fallbackTypes = [
  {'id': 'depot-sauvage',       'libelle': 'Dépôt sauvage'},
  {'id': 'dechets-menagers',    'libelle': 'Déchets ménagers'},
  {'id': 'eaux-usees',          'libelle': 'Eaux usées'},
  {'id': 'encombrants',         'libelle': 'Encombrants'},
  {'id': 'dechets-industriels', 'libelle': 'Déchets industriels'},
  {'id': 'nuisibles',           'libelle': 'Nuisibles'},
];

// ─── Palette charte ───────────────────────────────────────────
const Color _primaryGreen   = Color(0xFF2E7D32);
const Color _secondaryBlue  = Color(0xFF1565C0);
const Color _lightGreen     = Color(0xFFE8F5E9);
const Color _lightBlue      = Color(0xFFE3F2FD);
const Color _textPrimary    = Color(0xFF1A2B1A);
const Color _textSecondary  = Color(0xFF546E4F);
const Color _textHint       = Color(0xFF90A890);
const Color _border         = Color(0xFFE0EEE0);
const Color _surface        = Color(0xFFFFFFFF);
const Color _bgPage         = Color(0xFFFFFFFF);

class SignalementPage extends StatefulWidget {
  const SignalementPage({super.key});

  @override
  State<SignalementPage> createState() => _SignalementPageState();
}

class _SignalementPageState extends State<SignalementPage>
    with TickerProviderStateMixin {

  int _step = 0;
  String? _selectedTypeId;
  String? _selectedTypeLabel;
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;
  bool _sending = false;
  XFile? _selectedPhoto;
  final TextEditingController _descController = TextEditingController();

  List<Map<String, dynamic>> _types = [];
  bool _loadingTypes = true;
  bool _typesFromFallback = false;

  // Animation pour step 3
  late AnimationController _successController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final Map<String, IconData> _typeIcons = {
    'Dépôt sauvage':      Icons.delete_rounded,
    'Déchets ménagers':   Icons.recycling_rounded,
    'Eaux usées':         Icons.water_drop_rounded,
    'Encombrants':        Icons.chair_rounded,
    'Déchets industriels':Icons.science_rounded,
    'Nuisibles':          Icons.pest_control_rounded,
  };

  final Map<String, Color> _typeColors = {
    'Dépôt sauvage':      const Color(0xFFEF4444),
    'Déchets ménagers':   _primaryGreen,
    'Eaux usées':         _secondaryBlue,
    'Encombrants':        const Color(0xFF8B5CF6),
    'Déchets industriels':const Color(0xFFF59E0B),
    'Nuisibles':          const Color(0xFF6B7280),
  };

  @override
  void initState() {
    super.initState();
    _loadTypes();
    // Récupère une photo perdue si Android a recréé l'activité
    // pendant l'ouverture de la caméra
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPhoto());
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _successController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    setState(() { _loadingTypes = true; _typesFromFallback = false; });
    try {
      final types = await ApiService.getTypes();
      if (mounted) {
        setState(() {
          _types = types.isEmpty ? List.from(_fallbackTypes) : types;
          _typesFromFallback = types.isEmpty;
          _loadingTypes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _types = List.from(_fallbackTypes);
          _typesFromFallback = true;
          _loadingTypes = false;
        });
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { _showSnack('Activez le GPS sur votre appareil'); setState(() => _loadingLocation = false); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) { _showSnack('Permission GPS refusée'); setState(() => _loadingLocation = false); return; }
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _latitude = position.latitude; _longitude = position.longitude; _loadingLocation = false; });
    } catch (e) {
      _showSnack('Impossible de récupérer la position');
      setState(() => _loadingLocation = false);
    }
  }

  // ─── Choix source photo (caméra ou galerie) ───────────────
  Future<void> _pickPhoto() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD0E8D0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Ajouter une photo',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textPrimary),
            ),
            SizedBox(height: 20.h),
            _buildPhotoOption(
              icon: Icons.photo_library_rounded,
              label: 'Choisir depuis la galerie',
              sublabel: 'Sélectionner une photo existante',
              onTap: () async {
                Navigator.pop(ctx);
                await _launchPicker(ImageSource.gallery);
              },
            ),
            SizedBox(height: 12.h),
           _buildPhotoOption(
              icon: Icons.camera_alt_rounded,
              label: 'Prendre une photo',
              sublabel: 'Ouvrir l\'appareil photo',
              onTap: () async {
                Navigator.pop(ctx);
                await _launchPicker(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: _lightGreen,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: Colors.white, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontFamily: 'Montserrat', fontSize: 13.sp, fontWeight: FontWeight.w700, color: _textPrimary)),
                  SizedBox(height: 2.h),
                  Text(sublabel, style: TextStyle(fontFamily: 'OpenSans', fontSize: 11.sp, color: _textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: _textHint),
          ],
        ),
      ),
    );
  }

  // ─── Lancement effectif du picker avec protection ─────────
  // ⚠️  Sur Android, quand la caméra s'ouvre, Flutter peut
  //     recréer l'activité (low memory). Sans le check
  //     `mounted`, l'appel à setState() crasherait ou
  //     le navigateur repartirait au premier écran.
  Future<void> _launchPicker(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo  = await picker.pickImage(
        source:       source,
        maxWidth:     1920,
        maxHeight:    1080,
        imageQuality: 85,
      );
      // Widget peut avoir été démonté pendant l'ouverture caméra
      if (!mounted) return;
      if (photo != null) setState(() => _selectedPhoto = photo);
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Erreur picker : $e');
      _showSnack('Impossible d\'accéder à la photo. Réessayez.');
    }
  }

  // ─── Récupération des données perdues (Android) ───────────
  // Android peut tuer l'app pendant l'ouverture caméra et
  // perdre la sélection. Cette méthode récupère la photo si
  // elle a quand même été prise.
  Future<void> _recoverLostPhoto() async {
    try {
      final picker   = ImagePicker();
      final response = await picker.retrieveLostData();
      if (response.isEmpty || !mounted) return;
      if (response.file != null) {
        setState(() => _selectedPhoto = response.file);
      }
    } catch (_) {}
  }
  Future<void> _envoyer() async {
    if (_selectedTypeId == null) return;
    if (_latitude == null || _longitude == null) {
      _showSnack('Veuillez d\'abord obtenir votre position GPS');
      return;
    }

    setState(() => _sending = true);

    try {
      // Étape 1 : Upload photo vers Supabase Storage (si présente)
      String? photoUrl;
      if (_selectedPhoto != null) {
        photoUrl = await ApiService.uploadPhotoToSupabase(_selectedPhoto!);
        if (photoUrl == null) {
          _showSnack('Erreur lors de l\'upload de la photo');
          // Continue quand même sans photo, ou return selon ton choix
        }
      }

      // Étape 2 : Envoie le signalement avec photo_url (String)
      await ApiService.envoyerSignalement(
        typeId: _selectedTypeId!,
        latitude: _latitude!,
        longitude: _longitude!,
        description: _descController.text.isEmpty ? null : _descController.text,
        photoUrl: photoUrl, // ← URL texte ou null
      );

      setState(() { _step = 2; _sending = false; });
      _successController.forward(from: 0.0);
    } catch (e) {
      debugPrint('❌ Erreur envoi: $e');
      _showSnack('Erreur lors de l\'envoi. Réessayez.');
      setState(() => _sending = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'OpenSans')),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          children: [
            if (_step < 2) _buildAppBar(),
            if (_step < 2) _buildStepper(),
            Expanded(
              child: _step == 0
                  ? _buildCategoryStep()
                  : _step == 1
                  ? _buildLocationStep()
                  : _buildConfirmStep(),
            ),
            if (_step < 2) _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.energy_savings_leaf_rounded, color: _primaryGreen, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau signalement',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  'Rue Koné Tiémoman, Abobo',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 12.sp,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: _secondaryBlue, size: 13.r),
                SizedBox(width: 4.w),
                Text(
                  'Anonyme',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: _secondaryBlue,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stepper ─────────────────────────────────────────────
  Widget _buildStepper() {
    final steps = ['Catégorie', 'Localisation', 'Envoi'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone   = i < _step;
          final isActive = i == _step;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 34.r,
                      height: 34.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? _primaryGreen
                            : isActive
                            ? _primaryGreen
                            : const Color(0xFFEEF5EE),
                        boxShadow: isActive
                            ? [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check_rounded, color: Colors.white, size: 16.r)
                            : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: isActive ? Colors.white : _textHint,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 10.sp,
                        color: isActive ? _primaryGreen : _textHint,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.5,
                      margin: EdgeInsets.only(bottom: 20.h, left: 6.w, right: 6.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.r),
                        color: i < _step ? _primaryGreen : const Color(0xFFE0EEE0),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ÉTAPE 1 — CATÉGORIE
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategoryStep() {
    if (_loadingTypes) {
      return Center(
        child: CircularProgressIndicator(color: _primaryGreen, strokeWidth: 2.5),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quel type de problème ?',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Sélectionnez la catégorie qui correspond le mieux à votre signalement.',
            style: TextStyle(fontFamily: 'OpenSans', fontSize: 13.sp, color: _textSecondary, height: 1.4),
          ),
          SizedBox(height: 16.h),

          if (_typesFromFallback)
            Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: const Color(0xFFF59E0B), size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Catégories en mode hors-ligne',
                      style: TextStyle(fontFamily: 'OpenSans', fontSize: 12.sp, color: const Color(0xFF92400E), fontWeight: FontWeight.w500),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadTypes,
                    child: Text('Actualiser', style: TextStyle(fontFamily: 'OpenSans', fontSize: 12.sp, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 1.05,
            ),
            itemCount: _types.length,
            itemBuilder: (_, i) {
              final type      = _types[i];
              final id        = type['id'] as String;
              final libelle   = type['libelle'] as String? ?? '';
              final isSelected = _selectedTypeId == id;
              final color     = _typeColors[libelle] ?? _primaryGreen;
              final icon      = _typeIcons[libelle] ?? Icons.report_problem_rounded;

              return GestureDetector(
                onTap: () => setState(() { _selectedTypeId = id; _selectedTypeLabel = libelle; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryGreen.withOpacity(0.04) : _surface,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isSelected ? _primaryGreen : _border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? _primaryGreen.withOpacity(0.12)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryGreen.withOpacity(0.12) : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(icon, color: isSelected ? _primaryGreen : color, size: 22.r),
                      ),
                      const Spacer(),
                      Text(
                        libelle,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? _primaryGreen : _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      if (isSelected)
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12.r, color: _primaryGreen),
                            SizedBox(width: 4.w),
                            Text(
                              'Sélectionné',
                              style: TextStyle(fontFamily: 'OpenSans', fontSize: 10.sp, color: _primaryGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Appuyer pour choisir',
                          style: TextStyle(fontFamily: 'OpenSans', fontSize: 10.sp, color: _textHint),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ÉTAPE 2 — LOCALISATION
  // ═══════════════════════════════════════════════════════════
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Où se situe le problème ?',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Indiquez l\'emplacement précis pour permettre une intervention rapide.',
            style: TextStyle(fontFamily: 'OpenSans', fontSize: 13.sp, color: _textSecondary, height: 1.4),
          ),
          SizedBox(height: 20.h),

          // Résumé catégorie choisie
          if (_selectedTypeLabel != null)
            Container(
              margin: EdgeInsets.only(bottom: 20.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _typeIcons[_selectedTypeLabel] ?? Icons.report_problem_rounded,
                    color: _primaryGreen,
                    size: 18.r,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Catégorie : $_selectedTypeLabel',
                    style: TextStyle(fontFamily: 'OpenSans', fontSize: 13.sp, color: _primaryGreen, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _step = 0),
                    child: Text('Changer', style: TextStyle(fontFamily: 'OpenSans', fontSize: 12.sp, color: _secondaryBlue, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          // GPS Card
          _buildSectionTitle('📍 Localisation GPS', required: true),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _loadingLocation ? null : _getLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: _latitude != null ? _lightGreen : _surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _latitude != null ? _primaryGreen : _border,
                  width: _latitude != null ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _latitude != null
                        ? _primaryGreen.withOpacity(0.08)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: _latitude != null ? _primaryGreen : _lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: _loadingLocation
                        ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen),
                    )
                        : Icon(
                      _latitude != null ? Icons.location_on_rounded : Icons.my_location_rounded,
                      color: _latitude != null ? Colors.white : _primaryGreen,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _latitude != null ? 'Position détectée ✓' : 'Utiliser ma position GPS',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _latitude != null ? _primaryGreen : _textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _latitude != null
                              ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                              : 'Appuyez pour détecter automatiquement',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 12.sp,
                            color: _latitude != null ? _textSecondary : _textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_latitude == null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Détecter',
                        style: TextStyle(fontFamily: 'OpenSans', color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // Photo
          _buildSectionTitle('📷 Photo', required: false),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _pickPhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: _selectedPhoto != null ? _lightGreen : _surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _selectedPhoto != null ? _primaryGreen : _border,
                  width: _selectedPhoto != null ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: _selectedPhoto != null ? _primaryGreen : _lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedPhoto != null ? Icons.check_rounded : Icons.camera_alt_rounded,
                      color: _selectedPhoto != null ? Colors.white : _primaryGreen,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPhoto != null ? 'Photo ajoutée ✓' : 'Ajouter une photo',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _selectedPhoto != null ? _primaryGreen : _textPrimary,
                          ),
                        ),
                        Text(
                          _selectedPhoto != null ? 'Appuyez pour changer la photo' : 'Documentez le problème visuellement',
                          style: TextStyle(fontFamily: 'OpenSans', fontSize: 12.sp, color: _textHint),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPhoto == null)
                    Icon(Icons.arrow_forward_ios_rounded, color: _textHint, size: 14.r),
                ],
              ),
            ),
          ),

          if (_selectedPhoto != null) ...[
            SizedBox(height: 10.h),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: Image.file(
                    File(_selectedPhoto!.path),
                    height: 130.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPhoto = null),
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 14.r),
                    ),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 24.h),

          // Description
          _buildSectionTitle('📝 Description', required: false),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _border, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _descController,
              maxLines: 4,
              style: TextStyle(fontFamily: 'OpenSans', fontSize: 13.sp, color: _textPrimary),
              decoration: InputDecoration(
                hintText: 'Décrivez brièvement le problème (lieu, gravité, durée…)',
                hintStyle: TextStyle(fontFamily: 'OpenSans', fontSize: 13.sp, color: _textHint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.r),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Bandeau anonymat
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: _secondaryBlue.withOpacity(0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_rounded, color: _secondaryBlue, size: 18.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Votre signalement est 100 % anonyme. Aucune donnée personnelle n\'est collectée ou stockée.',
                    style: TextStyle(fontFamily: 'OpenSans', fontSize: 12.sp, color: _secondaryBlue, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool required}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14.sp, fontWeight: FontWeight.w700, color: _textPrimary),
        ),
        if (!required) ...[
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text('Facultatif', style: TextStyle(fontFamily: 'OpenSans', fontSize: 10.sp, color: _textHint, fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ÉTAPE 3 — CONFIRMATION (redesignée)
  // ═══════════════════════════════════════════════════════════
  Widget _buildConfirmStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 40.h),

            // Icône succès animée
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 110.r,
                height: 110.r,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 52.r),
                ),
              ),
            ),

            SizedBox(height: 28.h),

            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Text(
                    'Signalement envoyé !',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: _primaryGreen,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Merci pour votre contribution à la propreté\nde la rue Koné Tiémoman.',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 14.sp,
                      color: _textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 32.h),

                  // Card : pris en charge
                  _buildInfoCard(
                    icon: Icons.handyman_rounded,
                    iconColor: _primaryGreen,
                    iconBg: _lightGreen,
                    title: 'Votre signalement a été pris en charge',
                    body: 'Nos équipes ont bien reçu votre signalement. Il sera examiné et traité dans les meilleurs délais.',
                  ),

                  SizedBox(height: 14.h),

                  // Card : notification
                  _buildInfoCard(
                    icon: Icons.notifications_active_rounded,
                    iconColor: _secondaryBlue,
                    iconBg: _lightBlue,
                    title: 'Vous serez informé',
                    body: 'Dès que le problème sera résolu, vous recevrez une notification sur cette application.',
                  ),

                  SizedBox(height: 14.h),

                  // Card : slogan
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.energy_savings_leaf_rounded, color: Colors.white, size: 28.r),
                        SizedBox(height: 8.h),
                        Text(
                          '« Signaler aujourd\'hui,\nvivre mieux demain »',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'RuePropre · Abobo · 2026',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            color: Colors.white60,
                            fontSize: 11.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),



                  SizedBox(height: 12.h),

                  // Bouton nouveau signalement
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _step = 0;
                          _selectedTypeId = null;
                          _selectedTypeLabel = null;
                          _latitude = null;
                          _longitude = null;
                          _selectedPhoto = null;
                          _descController.clear();
                        });
                      },
                      icon: Icon(Icons.add_rounded, size: 18.r),
                      label: Text(
                        'Faire un autre signalement',
                        style: TextStyle(fontFamily: 'Montserrat', fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: BorderSide(color: _primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String body,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: iconColor, size: 22.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Montserrat', fontSize: 13.sp, fontWeight: FontWeight.w700, color: _textPrimary)),
                SizedBox(height: 4.h),
                Text(body, style: TextStyle(fontFamily: 'OpenSans', fontSize: 12.sp, color: _textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bouton bas ───────────────────────────────────────────
  Widget _buildBottomButton() {
    final isEnabled = _step == 0 ? _selectedTypeId != null : _latitude != null;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      decoration: BoxDecoration(
        color: _bgPage,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          onPressed: isEnabled && !_sending
              ? () async {
            if (_step == 0) {
              setState(() => _step = 1);
            } else if (_step == 1) {
              await _envoyer();
            }
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? _primaryGreen : const Color(0xFFE0EEE0),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE0EEE0),
            disabledForegroundColor: _textHint,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            elevation: isEnabled ? 0 : 0,
            shadowColor: _primaryGreen.withOpacity(0.3),
          ),
          child: _sending
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _step == 1 ? 'Envoyer le signalement' : 'Continuer',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 8.w),
              Icon(_step == 1 ? Icons.send_rounded : Icons.arrow_forward_rounded, size: 18.r),
            ],
          ),
        ),
      ),
    );
  }
}