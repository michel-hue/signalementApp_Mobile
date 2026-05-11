import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signalementapp/src/Theme/app_colors.dart';
import 'package:signalementapp/src/service/api_service.dart';

// ============================================================
// ACCUEIL PAGE — Charte Graphique RuePropre 2026
// Couleurs : Vert #2E7D32 (30%) | Bleu #1565C0 (10%) | Blanc (60%)
// Typo    : Montserrat (titres) | Open Sans (corps)
// ============================================================

class AcceuilPage extends StatefulWidget {
  const AcceuilPage({super.key});

  @override
  State<AcceuilPage> createState() => _AcceuilPageState();
}

class _AcceuilPageState extends State<AcceuilPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  // ─── Données ───
  Map<String, dynamic> _stats = {
    'total': 0,
    'en_attente': 0,
    'en_cours': 0,
    'traite': 0,
  };
  List<Map<String, dynamic>> _recentSignalements = [];
  Map<String, int> _statsByType = {};
  bool _loading = true;
  bool _isRefreshing = false;

  bool _statsError = false;
  bool _signalementsError = false;

  // ─── Palette — Charte RuePropre ───
  static const Color _bg          = Color(0xFFFFFFFF);   // Blanc 60%
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _primaryGreen = Color(0xFF2E7D32);  // Vert 30%
  static const Color _secondaryBlue = Color(0xFF1565C0); // Bleu 10%
  static const Color _lightGreen  = Color(0xFFE8F5E9);
  static const Color _lightBlue   = Color(0xFFE3F2FD);
  static const Color _textPrimary  = Color(0xFF1A2B1A);
  static const Color _textSecondary= Color(0xFF546E4F);
  static const Color _textTertiary = Color(0xFF90A890);
  static const Color _border      = Color(0xFFE0EEE0);

  // Couleurs KPI (accents)
  static const Color _green  = Color(0xFF2E7D32);
  static const Color _blue   = Color(0xFF1565C0);
  static const Color _amber  = Color(0xFFF59E0B);
  static const Color _red    = Color(0xFFEF4444);
  static const Color _purple = Color(0xFF6A1B9A);
  static const Color _slate  = Color(0xFF546E57);

  static const List<Color> _typeColors = [
    _green, _blue, _amber, _purple, _red, _slate
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    _statsError = false;
    _signalementsError = false;

    Map<String, dynamic> fetchedStats = {};
    List<Map<String, dynamic>> signalements = [];

    try {
      fetchedStats = await ApiService.getStats();
    } catch (e) {
      debugPrint('⚠️ getStats indisponible : $e');
      _statsError = true;
    }

    try {
      signalements = await ApiService.getSignalements();
    } catch (e) {
      debugPrint('⚠️ getSignalements indisponible : $e');
      _signalementsError = true;
    }

    final typeCount = <String, int>{};
    for (final s in signalements) {
      final libelle =
          (s['types_problemes'] as Map<String, dynamic>?)?['libelle'] as String?
              ?? s['type'] as String?
              ?? 'Autre';
      typeCount[libelle] = (typeCount[libelle] ?? 0) + 1;
    }

    final int total     = (fetchedStats['total'] as int?)     ?? signalements.length;
    final int enAttente = (fetchedStats['en_attente'] as int?) ?? signalements.where((s) => s['statut'] == 'en_attente').length;
    final int enCours   = (fetchedStats['en_cours'] as int?)   ?? signalements.where((s) => s['statut'] == 'en_cours').length;
    final int traite    = (fetchedStats['traite'] as int?)
        ?? (fetchedStats['traités'] as int?)
        ?? signalements.where((s) => s['statut'] == 'traite').length;

    if (mounted) {
      setState(() {
        _stats = {
          'total': total,
          'en_attente': enAttente,
          'en_cours': enCours,
          'traite': traite,
        };
        _recentSignalements = signalements.take(5).toList();
        _statsByType = typeCount;
        _loading = false;
        _isRefreshing = false;
      });
      _controller.forward(from: 0.0);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const _SkeletonLoader()
            : RefreshIndicator(
          onRefresh: _onRefresh,
          color: _primaryGreen,
          backgroundColor: _surface,
          strokeWidth: 2.5,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: SizedBox(height: 28.h)),

              if (_statsError || _signalementsError)
                SliverToBoxAdapter(child: _buildErrorBanner()),

              SliverToBoxAdapter(child: _buildMainKpiCard()),
              SliverToBoxAdapter(child: SizedBox(height: 28.h)),

              SliverToBoxAdapter(child: _buildDetailedStats()),
              SliverToBoxAdapter(child: SizedBox(height: 28.h)),

              if (_statsByType.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildCategorySection()),
                SliverToBoxAdapter(child: SizedBox(height: 28.h)),
              ],

              SliverToBoxAdapter(child: _buildRecentActivityHeader()),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),

              if (_recentSignalements.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final s = _recentSignalements[index];
                        return _buildActivityItem(s, index);
                      },
                      childCount: _recentSignalements.length,
                    ),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 40.h)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bannière erreur ───
  Widget _buildErrorBanner() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: _amber, size: 18.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _signalementsError && _statsError
                    ? 'Données hors ligne — les chiffres affichés sont les derniers disponibles'
                    : _statsError
                    ? 'Statistiques calculées depuis les signalements locaux'
                    : 'Signalements partiellement chargés',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 12.sp,
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: _onRefresh,
              child: Text(
                'Réessayer',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 12.sp,
                  color: _amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Avatar vert charte
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.energy_savings_leaf_rounded,
                color: Colors.white,
                size: 24.r,
              ),
            ),
          ),
          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour 👋',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 13.sp,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'RuePropre',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: _primaryGreen,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          _buildNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14.r),
        splashColor: _primaryGreen.withOpacity(0.08),
        child: Container(
          width: 46.r,
          height: 46.r,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: _border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_outlined, color: _textSecondary, size: 22.r),
              Positioned(
                top: 10.r,
                right: 10.r,
                child: Container(
                  width: 9.r,
                  height: 9.r,
                  decoration: BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                    border: Border.all(color: _surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CARTE PRINCIPALE KPI — Gradient vert charte
  // ═══════════════════════════════════════════════════════════
  Widget _buildMainKpiCard() {
    final total   = _stats['total'] ?? 0;
    final traite  = _stats['traite'] ?? 0;
    final pct     = total > 0 ? ((traite / total) * 100).round() : 0;
    final enCours = _stats['en_cours'] ?? 0;

    return _AnimatedSection(
      delay: 0.0,
      controller: _controller,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF1B5E20),
                Color(0xFF0D2D11),
              ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160.r,
                    height: 160.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge campagne
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Campagne 2026 · Abobo',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      Text(
                        'Ensemble pour\nune rue propre',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Signaler aujourd\'hui, vivre mieux demain',
                        style: TextStyle(
                          fontFamily: 'OpenSans',
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      Row(
                        children: [
                          _buildKpiBadge(value: '$total',   label: 'Signalements', icon: Icons.assignment_outlined),
                          SizedBox(width: 10.w),
                          _buildKpiBadge(value: '$pct%',    label: 'Résolus',      icon: Icons.check_circle_outlined),
                          SizedBox(width: 10.w),
                          _buildKpiBadge(value: '$enCours', label: 'En cours',     icon: Icons.timelapse_outlined),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Barre de progression
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progression globale',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$traite / $total traités',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  width: (pct / 100) *
                                      (MediaQuery.of(context).size.width - 88.w),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF69F0AE), Color(0xFF00E676)],
                                    ),
                                    borderRadius: BorderRadius.circular(3.r),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiBadge({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 18.r),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'OpenSans',
                color: Colors.white.withOpacity(0.75),
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATS DÉTAILLÉES
  // ═══════════════════════════════════════════════════════════
  Widget _buildDetailedStats() {
    final total     = _stats['total'] ?? 0;
    final traite    = _stats['traite'] ?? 0;
    final enAttente = _stats['en_attente'] ?? 0;
    final enCours   = _stats['en_cours'] ?? 0;

    return _AnimatedSection(
      delay: 0.15,
      controller: _controller,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_isRefreshing)
                  SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.flag_outlined,
                    value: '$total',
                    label: 'Total',
                    sublabel: 'signalements',
                    color: _primaryGreen,
                    trend: '+12%',
                    trendUp: true,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outlined,
                    value: '$traite',
                    label: 'Traités',
                    sublabel: 'résolus',
                    color: _green,
                    trend: '+8%',
                    trendUp: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.hourglass_empty_outlined,
                    value: '$enAttente',
                    label: 'En attente',
                    sublabel: 'à traiter',
                    color: _amber,
                    trend: '-3%',
                    trendUp: false,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _StatCard(
                    icon: Icons.play_circle_outline,
                    value: '$enCours',
                    label: 'En cours',
                    sublabel: 'en traitement',
                    color: _secondaryBlue,
                    trend: '+5%',
                    trendUp: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RÉPARTITION PAR CATÉGORIE
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategorySection() {
    final entries = _statsByType.entries.toList();
    final total   = entries.fold<int>(0, (sum, e) => sum + e.value);
    final maxVal  = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b);

    return _AnimatedSection(
      delay: 0.3,
      controller: _controller,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: _border, width: 1),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Répartition par type',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$total signalements au total',
                        style: TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: 12.sp,
                          color: _textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.r,
                          height: 5.r,
                          decoration: const BoxDecoration(
                            color: _primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'En direct',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            color: _primaryGreen,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              ...List.generate(entries.length, (i) {
                final entry    = entries[i];
                final color    = _typeColors[i % _typeColors.length];
                final pct      = total > 0 ? ((entry.value / total) * 100).toStringAsFixed(0) : '0';
                final barWidth = maxVal > 0 ? (entry.value / maxVal) : 0.0;

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${entry.value}',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '($pct%)',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 11.sp,
                                  color: _textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              width: barWidth *
                                  (MediaQuery.of(context).size.width - 80.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color.withOpacity(0.7), color],
                                ),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER ACTIVITÉ RÉCENTE
  // ═══════════════════════════════════════════════════════════
  Widget _buildRecentActivityHeader() {
    return _AnimatedSection(
      delay: 0.45,
      controller: _controller,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activité récente',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_recentSignalements.length} derniers signalements',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 12.sp,
                    color: _textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onRefresh,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: _primaryGreen, size: 16.r),
                      SizedBox(width: 4.w),
                      Text(
                        'Actualiser',
                        style: TextStyle(
                          fontFamily: 'OpenSans',
                          color: _primaryGreen,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── État vide ───
  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      child: Container(
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _border, width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(Icons.inbox_outlined, color: _primaryGreen, size: 28.r),
            ),
            SizedBox(height: 16.h),
            Text(
              _signalementsError ? 'Données indisponibles' : 'Aucun signalement',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _signalementsError
                  ? 'Vérifiez votre connexion et actualisez'
                  : 'Les nouveaux signalements apparaîtront ici',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 13.sp,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_signalementsError) ...[
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _onRefresh,
                icon: Icon(Icons.refresh_rounded, size: 16.r),
                label: Text(
                  'Réessayer',
                  style: TextStyle(fontFamily: 'OpenSans', fontSize: 13.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Item activité ───
  Widget _buildActivityItem(Map<String, dynamic> s, int index) {
    final typeLabel = (s['types_problemes'] as Map<String, dynamic>?)?['libelle'] as String?
        ?? s['type'] as String?
        ?? 'Signalement';
    final statut      = s['statut'] as String? ?? 'en_attente';
    final description = s['description'] as String? ?? 'Rue Koné Tiémoman, Abobo';
    final createdAt   = DateTime.tryParse(s['created_at'] as String? ?? '') ?? DateTime.now();
    final diff        = DateTime.now().difference(createdAt);
    final timeAgo     = diff.inDays > 0 ? '${diff.inDays}j' : diff.inHours > 0 ? '${diff.inHours}h' : '${diff.inMinutes}min';

    Color  statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (statut) {
      case 'en_cours':
        statusColor = _amber;
        statusLabel = 'En cours';
        statusIcon  = Icons.timelapse_rounded;
        break;
      case 'traite':
        statusColor = _primaryGreen;
        statusLabel = 'Résolu';
        statusIcon  = Icons.check_circle_rounded;
        break;
      default:
        statusColor = _secondaryBlue;
        statusLabel = 'Soumis';
        statusIcon  = Icons.schedule_rounded;
    }

    return _AnimatedSection(
      delay: 0.5 + (index * 0.05),
      controller: _controller,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16.r),
            splashColor: _primaryGreen.withOpacity(0.06),
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: _border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _primaryGreen,
                        size: 22.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          description,
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 13.sp,
                            color: _textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12.r, color: _textTertiary),
                            SizedBox(width: 4.w),
                            Text(
                              'Il y a $timeAgo',
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 11.sp,
                                color: _textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 12.r),
                        SizedBox(width: 4.w),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 11.sp,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS RÉUTILISABLES
// ============================================================

class _AnimatedSection extends StatelessWidget {
  final Widget child;
  final double delay;
  final AnimationController controller;

  const _AnimatedSection({
    required this.child,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              delay.clamp(0.0, 0.6),
              (delay + 0.35).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 24),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color color;
  final String trend;
  final bool trendUp;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE0EEE0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 18.r),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: trendUp ? const Color(0xFFE8F5E9) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: trendUp ? const Color(0xFF2E7D32) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2B1A),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF546E4F),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            sublabel,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 11.sp,
              color: const Color(0xFF90A890),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 100.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 28.h),
          Container(
            height: 220.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
          SizedBox(height: 28.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}