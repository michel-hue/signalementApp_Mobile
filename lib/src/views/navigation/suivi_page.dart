// lib/src/views/navigation/suivi_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signalementapp/src/Theme/app_colors.dart';
import 'package:signalementapp/src/service/api_service.dart';

// ============================================================
// SUIVI PAGE — Charte Graphique RuePropre 2026
// Vert #2E7D32 | Bleu #1565C0 | Blanc #FFFFFF
// Montserrat (titres) | Open Sans (corps)
// ============================================================

// ─── Palette charte ───────────────────────────────────────────
const Color _primaryGreen  = Color(0xFF2E7D32);
const Color _secondaryBlue = Color(0xFF1565C0);
const Color _lightGreen    = Color(0xFFE8F5E9);
const Color _lightBlue     = Color(0xFFE3F2FD);
const Color _textPrimary   = Color(0xFF1A2B1A);
const Color _textSecondary = Color(0xFF546E4F);
const Color _textHint      = Color(0xFF90A890);
const Color _border        = Color(0xFFE0EEE0);
const Color _surface       = Color(0xFFFFFFFF);
const Color _bgPage        = Color(0xFFFFFFFF);

class SuiviPage extends StatefulWidget {
  const SuiviPage({super.key});

  @override
  State<SuiviPage> createState() => _SuiviPageState();
}

class _SuiviPageState extends State<SuiviPage> {
  int _filterIndex = 0;
  List<Map<String, dynamic>> _signalements = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  bool _signalementsError = false;
  bool _statsError = false;

  final List<Map<String, dynamic>> _filters = [
    {'label': 'Tous',       'icon': Icons.list_rounded},
    {'label': 'En attente', 'icon': Icons.schedule_rounded},
    {'label': 'En cours',   'icon': Icons.handyman_rounded},
    {'label': 'Résolus',    'icon': Icons.check_circle_rounded},
  ];

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _signalementsError = false; _statsError = false; });

    List<Map<String, dynamic>> signalements = [];
    Map<String, dynamic> stats = {};

    try {
      signalements = await ApiService.getSignalements();
    } catch (e) {
      debugPrint('⚠️ getSignalements : $e');
      _signalementsError = true;
      signalements = _signalements;
    }

    try {
      stats = await ApiService.getStats();
      if (stats.isEmpty) throw Exception('Stats vides');
    } catch (e) {
      debugPrint('⚠️ getStats : $e');
      _statsError = true;
      stats = {
        'total':      signalements.length,
        'en_attente': signalements.where((s) => s['statut'] == 'en_attente').length,
        'en_cours':   signalements.where((s) => s['statut'] == 'en_cours').length,
        'traite':     signalements.where((s) => s['statut'] == 'traite').length,
      };
    }

    if (mounted) {
      setState(() { _signalements = signalements; _stats = stats; _loading = false; });
      _applyFilter();
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_filterIndex) {
        case 1: _filtered = _signalements.where((s) => s['statut'] == 'en_attente').toList(); break;
        case 2: _filtered = _signalements.where((s) => s['statut'] == 'en_cours').toList(); break;
        case 3: _filtered = _signalements.where((s) => s['statut'] == 'traite').toList(); break;
        default: _filtered = List.from(_signalements);
      }
    });
  }

  String _statutLabel(String statut) {
    switch (statut) { case 'en_cours': return 'En cours'; case 'traite': return 'Résolu'; default: return 'Soumis'; }
  }

  Color _statutColor(String statut) {
    switch (statut) { case 'en_cours': return const Color(0xFFF59E0B); case 'traite': return _primaryGreen; default: return _secondaryBlue; }
  }

  double _statutProgress(String statut) {
    switch (statut) { case 'en_cours': return 0.5; case 'traite': return 1.0; default: return 0.1; }
  }

  IconData _statutIcon(String statut) {
    switch (statut) { case 'en_cours': return Icons.handyman_rounded; case 'traite': return Icons.check_circle_rounded; default: return Icons.send_rounded; }
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 12.h),
            _buildStatsRow(),
            if (_signalementsError || _statsError) _buildErrorBanner(),
            _buildFilterChips(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: _primaryGreen, strokeWidth: 2.5))
                  : RefreshIndicator(
                onRefresh: _loadData,
                color: _primaryGreen,
                backgroundColor: _surface,
                child: _filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, i) {
                    final s       = _filtered[i];
                    final statut  = s['statut'] as String? ?? 'en_attente';
                    final type    = s['types_problemes'] as Map<String, dynamic>?;
                    final libelle = type?['libelle'] as String? ?? s['type'] as String? ?? 'Signalement';
                    final token   = s['token_suivi'] as String? ?? '';
                    final desc    = s['description'] as String? ?? 'Rue Koné Tiémoman';

                    return _ReportCard(
                      title:       libelle,
                      ref:         token,
                      location:    'Rue Koné Tiémoman, Abobo',
                      description: desc,
                      status:      _statutLabel(statut),
                      statusColor: _statutColor(statut),
                      statusBg:    _statutColor(statut).withOpacity(0.1),
                      statusIcon:  _statutIcon(statut),
                      date:        _formatDate(s['created_at'] as String?),
                      timeAgo:     _timeAgo(s['created_at'] as String?),
                      icon:        _typeIcons[libelle] ?? Icons.report_problem_rounded,
                      iconColor:   _typeColors[libelle] ?? _primaryGreen,
                      iconBg:      (_typeColors[libelle] ?? _primaryGreen).withOpacity(0.1),
                      progress:    _statutProgress(statut),
                      isUrgent:    statut == 'en_attente',
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suivi des signalements',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Rue Koné Tiémoman — Données en temps réel',
                  style: TextStyle(fontFamily: 'OpenSans', fontSize: 12.sp, color: _textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.refresh_rounded, color: _primaryGreen, size: 20.r),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ───────────────────────────────────────────
  Widget _buildStatsRow() {
    final items = [
      {'value': '${_stats['total'] ?? 0}',      'label': 'Total',      'color': _textPrimary,   'bg': const Color(0xFFF5F8F5)},
      {'value': '${_stats['en_attente'] ?? 0}',  'label': 'En attente', 'color': _secondaryBlue, 'bg': _lightBlue},
      {'value': '${_stats['en_cours'] ?? 0}',    'label': 'En cours',   'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
      {'value': '${_stats['traite'] ?? 0}',      'label': 'Résolus',    'color': _primaryGreen,  'bg': _lightGreen},
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: e.key < items.length - 1 ? 8.w : 0),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: item['bg'] as Color,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                children: [
                  Text(
                    item['value'] as String,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: item['color'] as Color,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item['label'] as String,
                    style: TextStyle(fontFamily: 'OpenSans', fontSize: 10.sp, color: _textHint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Error Banner ────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
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
                _signalementsError ? 'Données en cache — tirez pour actualiser' : 'Stats calculées localement',
                style: TextStyle(fontFamily: 'OpenSans', fontSize: 11.sp, color: const Color(0xFF92400E), fontWeight: FontWeight.w500),
              ),
            ),
            GestureDetector(
              onTap: _loadData,
              child: Text('Réessayer', style: TextStyle(fontFamily: 'OpenSans', fontSize: 11.sp, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Chips ────────────────────────────────────────
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final isSelected = _filterIndex == i;
          final filter     = _filters[i];
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () { setState(() => _filterIndex = i); _applyFilter(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryGreen : _surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: isSelected ? _primaryGreen : _border, width: 1),
                  boxShadow: [
                    BoxShadow(color: isSelected ? _primaryGreen.withOpacity(0.2) : Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(filter['icon'] as IconData, color: isSelected ? Colors.white : _textHint, size: 14.r),
                    SizedBox(width: 6.w),
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 12.sp,
                        color: isSelected ? Colors.white : _textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── État vide ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: 60.h),
        Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _signalementsError ? Icons.cloud_off_rounded : Icons.inbox_rounded,
                    size: 38.r,
                    color: _primaryGreen,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  _signalementsError ? 'Connexion indisponible' : 'Aucun signalement',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 17.sp, fontWeight: FontWeight.w700, color: _textPrimary),
                ),
                SizedBox(height: 6.h),
                Text(
                  _signalementsError
                      ? 'Vérifiez votre connexion internet et réessayez'
                      : _filterIndex == 0
                      ? 'Aucun signalement n\'a encore été déposé'
                      : 'Aucun signalement dans cette catégorie',
                  style: TextStyle(fontFamily: 'OpenSans', fontSize: 13.sp, color: _textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: Icon(Icons.refresh_rounded, size: 18.r),
                  label: Text('Actualiser', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Report Card — Design Élégant ────────────────────────────

class _ReportCard extends StatelessWidget {
  final String title, ref, location, description, status, date, timeAgo;
  final Color statusColor, statusBg, iconColor, iconBg;
  final IconData statusIcon, icon;
  final bool isUrgent;
  final double progress;

  const _ReportCard({
    required this.title,
    required this.ref,
    required this.location,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.statusIcon,
    required this.date,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.progress,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEEF5EE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: _primaryGreen.withOpacity(0.03),
            blurRadius: 40,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ══════════════════════════════════════════════
          // SECTION HAUT — icône + titre + badge statut
          // ══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 12.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Icône catégorie avec fond coloré doux
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22.r),
                  ),
                ),

                SizedBox(width: 12.w),

                // Titre + ref
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 11.r, color: _textHint),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(fontFamily: 'OpenSans', fontSize: 11.sp, color: _textHint),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 10.w),

                // Badge statut pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10.sp,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ══════════════════════════════════════════════
          // DIVIDER fin
          // ══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(height: 1, color: const Color(0xFFF0F7F0)),
          ),

          // ══════════════════════════════════════════════
          // SECTION BAS — description + progression + date
          // ══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(16.r, 12.r, 16.r, 14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Description (si présente)
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 12.sp,
                      color: _textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12.h),
                ],

                // ─ Étape de progression (pills) ─────────
                _buildProgressSteps(),

                SizedBox(height: 12.h),

                // ─ Footer : ref + date ──────────────────
                Row(
                  children: [
                    // Badge "NOUVEAU" si urgent
                    if (isUrgent) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _lightBlue,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'NOUVEAU',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 8.sp,
                            color: _secondaryBlue,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],

                    // Réf token
                    if (ref.isNotEmpty) ...[
                      Icon(Icons.tag_rounded, size: 11.r, color: _textHint),
                      SizedBox(width: 3.w),
                      Text(
                        ref.length > 12 ? ref.substring(0, 12) + '…' : ref,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10.sp,
                          color: _textHint,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Date / timeAgo
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 11.r, color: _textHint),
                        SizedBox(width: 4.w),
                        Text(
                          timeAgo.isNotEmpty ? timeAgo : date,
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 10.sp,
                            color: _textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pills de progression (3 étapes) ─────────────────────
  Widget _buildProgressSteps() {
    final steps = [
      {'label': 'Soumis',   'done': true},
      {'label': 'En cours', 'done': progress >= 0.5},
      {'label': 'Résolu',   'done': progress >= 1.0},
    ];

    return Row(
      children: steps.asMap().entries.map((e) {
        final i    = e.key;
        final step = e.value;
        final done = step['done'] as bool;
        final isActive = (progress < 0.5 && i == 0) ||
            (progress >= 0.5 && progress < 1.0 && i == 1) ||
            (progress >= 1.0 && i == 2);

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Cercle étape
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? (isActive ? statusColor : statusColor.withOpacity(0.15))
                            : const Color(0xFFF0F7F0),
                        border: isActive
                            ? Border.all(color: statusColor, width: 2)
                            : Border.all(color: Colors.transparent, width: 0),
                      ),
                      child: Center(
                        child: done
                            ? Icon(
                          isActive ? statusIcon : Icons.check_rounded,
                          size: 12.r,
                          color: isActive ? Colors.white : statusColor,
                        )
                            : Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCE4CC),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 9.sp,
                        color: done ? statusColor : _textHint,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Ligne de connexion entre étapes
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.r),
                      gradient: LinearGradient(
                        colors: steps[i + 1]['done'] as bool
                            ? [statusColor.withOpacity(0.4), statusColor.withOpacity(0.4)]
                            : [statusColor.withOpacity(0.3), const Color(0xFFE0EEE0)],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}