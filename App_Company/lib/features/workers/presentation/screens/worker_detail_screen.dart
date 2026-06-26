import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/saas/saas_card.dart';
import '../../../../core/widgets/saas/saas_section_group.dart';
import '../../../../core/widgets/saas/worker_operational_badge.dart';
import '../../../worker_reviews/domain/entities/worker_rating_summary.dart';
import '../../../worker_reviews/domain/usecases/get_worker_rating_summary.dart';
import '../../../work_types/domain/entities/worker_work_type_assignment_entity.dart';
import '../../../work_types/domain/usecases/get_worker_work_types_usecase.dart';
import '../../domain/entities/language_entity.dart';
import '../../domain/entities/nationality_entity.dart';
import '../../domain/entities/worker_entity.dart';
import '../../domain/usecases/get_languages_usecase.dart';
import '../../domain/usecases/get_nationalities_usecase.dart';

/// Shown when opening `/workers/:id` without `extra` (e.g. deep link).
class WorkerDetailMissingScreen extends StatelessWidget {
  const WorkerDetailMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'ملف العاملة',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Text(
            'تعذر تحميل بيانات العاملة. افتح التفاصيل من القائمة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class WorkerDetailScreen extends StatefulWidget {
  const WorkerDetailScreen({
    super.key,
    required this.worker,
    this.focusHealthCertificate = false,
  });

  final WorkerEntity worker;
  final bool focusHealthCertificate;

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerLookupData {
  const _WorkerLookupData({
    required this.nationalities,
    required this.languages,
  });

  final List<NationalityEntity> nationalities;
  final List<LanguageEntity> languages;
}

enum _HealthCertState { none, valid, expiring, expired }

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  late final Future<_WorkerLookupData> _lookupFuture;
  late Future<List<WorkerWorkTypeAssignmentEntity>> _assignmentsFuture;
  late Future<WorkerRatingSummary?> _ratingFuture;
  final _healthSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _lookupFuture = _fetchLookup();
    _assignmentsFuture = _fetchWorkerAssignments();
    _ratingFuture = _loadRatingSummary();
    if (widget.focusHealthCertificate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHealthSection());
    }
  }

  void _scrollToHealthSection() {
    final context = _healthSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  Future<List<WorkerWorkTypeAssignmentEntity>> _fetchWorkerAssignments() async {
    final r = await getIt<GetWorkerWorkTypesUseCase>()(widget.worker.id);
    return r.fold((_) => <WorkerWorkTypeAssignmentEntity>[], (list) => list);
  }

  Future<WorkerRatingSummary?> _loadRatingSummary() async {
    final r = await getIt<GetWorkerRatingSummaryUseCase>()(widget.worker.id);
    return r.fold((_) => null, (s) => s);
  }

  bool _isCertExpired(DateTime? expiry) {
    if (expiry == null) return false;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return expiry.isBefore(today);
  }

  Future<_WorkerLookupData> _fetchLookup() async {
    final natResult = await getIt<GetNationalitiesUseCase>()();
    final langResult = await getIt<GetLanguagesUseCase>()();
    return _WorkerLookupData(
      nationalities: natResult.fold((_) => <NationalityEntity>[], (l) => l),
      languages: langResult.fold((_) => <LanguageEntity>[], (l) => l),
    );
  }

  String _nationalityLabel(List<NationalityEntity> list, WorkerEntity w) {
    final id = w.nationalityId;
    if (id != null) {
      for (final n in list) {
        if (n.id == id) return n.name;
      }
    }
    if (w.nationalityName.isNotEmpty) return w.nationalityName;
    return '—';
  }

  List<String> _languageNames(List<LanguageEntity> languages, WorkerEntity w) {
    final raw = w.languagesIds;
    if (raw == null || raw.trim().isEmpty) return [];
    final names = <String>[];
    for (final p in raw.split(',')) {
      final id = int.tryParse(p.trim());
      if (id == null) continue;
      String? name;
      for (final lang in languages) {
        if (lang.id == id) {
          name = lang.name;
          break;
        }
      }
      names.add(name ?? '#$id');
    }
    return names;
  }

  _HealthCertState _healthState(DateTime? expiry) {
    if (expiry == null) return _HealthCertState.none;
    final now = DateTime.now();
    final e = DateTime(expiry.year, expiry.month, expiry.day);
    final t = DateTime(now.year, now.month, now.day);
    if (e.isBefore(t)) return _HealthCertState.expired;
    if (e.difference(t).inDays <= 30) return _HealthCertState.expiring;
    return _HealthCertState.valid;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'ملف العاملة',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: _WorkerDetailBookingsBar(),
      body: FutureBuilder<_WorkerLookupData>(
        future: _lookupFuture,
        builder: (context, snapshot) {
          final nationalities = snapshot.data?.nationalities ?? const [];
          final languages = snapshot.data?.languages ?? const [];
          final nationality = _nationalityLabel(nationalities, w);
          final langNames = _languageNames(languages, w);
          final health = _healthState(w.healthCertificateExpiryDate);

          final scroll = SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkerHeroProfile(
                  worker: w,
                  nationality: nationality,
                  certExpired: _isCertExpired(w.healthCertificateExpiryDate),
                  ratingFuture: _ratingFuture,
                ),
                const SizedBox(height: 20),
                SaasDetailSection(
                  title: 'المعلومات الشخصية',
                  child: _KeyInfoCard(
                    age: '${w.age}',
                    experienceYears: '${w.experienceYears}',
                    nationality: nationality,
                    company: w.companyName ?? '—',
                  ),
                ),
                if (langNames.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  SaasDetailSection(
                    title: 'اللغات',
                    child: _LanguagesSection(languageNames: langNames),
                  ),
                ],
                const SizedBox(height: 18),
                SaasDetailSection(
                  title: 'معلومات العمل',
                  child: FutureBuilder<List<WorkerWorkTypeAssignmentEntity>>(
                    future: _assignmentsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _WorkerAssignedWorkTypesSection(
                        assignments: snap.data ?? [],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (widget.focusHealthCertificate) ...[
                  _HealthCertificateActionBanner(workerName: w.fullName),
                  const SizedBox(height: 12),
                ],
                SaasDetailSection(
                  title: 'الشهادة الصحية',
                  trailing: _HealthStatusChip(state: health),
                  child: KeyedSubtree(
                    key: _healthSectionKey,
                    child: _HealthCertificateCard(
                      expiryDate: w.healthCertificateExpiryDate,
                      state: health,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SaasDetailSection(
                  title: 'إحصائيات الأداء',
                  child: FutureBuilder<WorkerRatingSummary?>(
                    future: _ratingFuture,
                    builder: (context, snap) {
                      return _PerformanceStatsCard(
                        experienceYears: w.experienceYears,
                        summary: snap.data,
                      );
                    },
                  ),
                ),
                if (w.createdAt != null) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'تاريخ التسجيل: ${DateFormatter.formatDateTime(w.createdAt!)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray400,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          );

          return scroll;
        },
      ),
    );
  }
}

class _WorkerHeroProfile extends StatelessWidget {
  const _WorkerHeroProfile({
    required this.worker,
    required this.nationality,
    required this.certExpired,
    required this.ratingFuture,
  });

  final WorkerEntity worker;
  final String nationality;
  final bool certExpired;
  final Future<WorkerRatingSummary?> ratingFuture;

  @override
  Widget build(BuildContext context) {
    final initial = worker.fullName.trim().isNotEmpty
        ? worker.fullName.trim().substring(0, 1)
        : '?';
    final imgUrl = resolveApiUrl(worker.profileImage);

    return SaasCard(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      color: AppTheme.primaryTeal.withValues(alpha: 0.04),
      child: Column(
        children: [
          _Avatar(initial: initial, imageUrl: imgUrl),
          const SizedBox(height: 14),
          Text(
            worker.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gray900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            nationality,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
          const SizedBox(height: 10),
          WorkerOperationalBadge(
            worker: worker,
            certificateExpired: certExpired,
          ),
          const SizedBox(height: 16),
          FutureBuilder<WorkerRatingSummary?>(
            future: ratingFuture,
            builder: (context, snap) {
              final summary = snap.data;
              return Row(
                children: [
                  Expanded(
                    child: _HeroStatTile(
                      label: 'التقييم',
                      value: summary != null && summary.hasReviews
                          ? summary.averageRating.toStringAsFixed(1)
                          : '—',
                      icon: Icons.star_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroStatTile(
                      label: 'حجوزات مكتملة',
                      value: summary != null && summary.hasReviews
                          ? '${summary.totalReviews}'
                          : '—',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroStatTile(
                      label: 'الخبرة',
                      value: '${worker.experienceYears} س',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryTeal),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthStatusChip extends StatelessWidget {
  const _HealthStatusChip({required this.state});

  final _HealthCertState state;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (state) {
      _HealthCertState.none => ('غير مسجّلة', AppTheme.gray500),
      _HealthCertState.valid => ('سارية', AppTheme.primaryTeal),
      _HealthCertState.expiring => ('تنتهي قريباً', AppTheme.warningAmber),
      _HealthCertState.expired => ('منتهية', AppTheme.dangerRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PerformanceStatsCard extends StatelessWidget {
  const _PerformanceStatsCard({
    required this.experienceYears,
    this.summary,
  });

  final int experienceYears;
  final WorkerRatingSummary? summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PerformanceRow(
          icon: Icons.star_rate_rounded,
          label: 'متوسط التقييم',
          value: summary != null && summary!.hasReviews
              ? '${summary!.averageRating.toStringAsFixed(1)} / 5'
              : 'لا توجد تقييمات',
        ),
        const SizedBox(height: 12),
        _PerformanceRow(
          icon: Icons.event_available_rounded,
          label: 'حجوزات مكتملة (تقييمات)',
          value: summary != null && summary!.hasReviews
              ? '${summary!.totalReviews}'
              : '0',
        ),
        const SizedBox(height: 12),
        _PerformanceRow(
          icon: Icons.timeline_rounded,
          label: 'سنوات الخبرة',
          value: '$experienceYears',
        ),
      ],
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
              ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: AppTheme.primaryTeal),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.worker,
    required this.nationality,
  });

  final WorkerEntity worker;
  final String nationality;

  @override
  Widget build(BuildContext context) {
    final initial = worker.fullName.trim().isNotEmpty
        ? worker.fullName.trim().substring(0, 1)
        : '?';
    final imgUrl = resolveApiUrl(worker.profileImage);

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.mediumShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(initial: initial, imageUrl: imgUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.fullName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppTheme.gray900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nationality,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.gray500,
                                  fontSize: 14,
                                ),
                          ),
                          if (worker.experienceYears > 0) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium_outlined,
                                    size: 16,
                                    color: AppTheme.primaryTeal,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${worker.experienceYears} سنوات خبرة',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.primaryTeal,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _HeaderAvailabilityBadge(available: worker.isAvailable)
                  .animate()
                  .fadeIn(
                    duration: 320.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 320.ms,
                    curve: Curves.easeOutBack,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.imageUrl});

  final String initial;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _AvatarPlaceholder(initial: initial),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryTeal.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _AvatarPlaceholder(initial: initial);
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
        border: Border.all(
          color: AppTheme.primaryTeal.withValues(alpha: 0.2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTeal,
        ),
      ),
    );
  }
}

class _HeaderAvailabilityBadge extends StatelessWidget {
  const _HeaderAvailabilityBadge({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final bg = available
        ? AppTheme.successGreen.withValues(alpha: 0.14)
        : AppTheme.gray200;
    final fg = available ? AppTheme.successGreen : AppTheme.gray500;
    final label = available ? 'متاحة' : 'غير متاحة';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
      ),
    );
  }
}

class _QuickStatusRow extends StatelessWidget {
  const _QuickStatusRow({required this.worker});

  final WorkerEntity worker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusPill(
            icon: Icons.work_outline_rounded,
            label: 'متاحة للعمل',
            foreground: worker.isAvailable ? AppTheme.successGreen : AppTheme.gray500,
            background: worker.isAvailable
                ? AppTheme.successGreen.withValues(alpha: 0.12)
                : AppTheme.gray100,
            border: worker.isAvailable
                ? AppTheme.successGreen.withValues(alpha: 0.25)
                : AppTheme.gray200,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusPill(
            icon: Icons.verified_user_outlined,
            label: 'نشطة',
            foreground: worker.isActive ? AppTheme.secondaryBlue : AppTheme.gray500,
            background: worker.isActive
                ? AppTheme.secondaryBlue.withValues(alpha: 0.1)
                : AppTheme.gray100,
            border: worker.isActive
                ? AppTheme.secondaryBlue.withValues(alpha: 0.28)
                : AppTheme.gray200,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyInfoCard extends StatelessWidget {
  const _KeyInfoCard({
    required this.age,
    required this.experienceYears,
    required this.nationality,
    required this.company,
  });

  final String age;
  final String experienceYears;
  final String nationality;
  final String company;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'معلومات أساسية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray800,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _KeyCell(label: 'العمر', value: age)),
                  const SizedBox(width: 20),
                  Expanded(child: _KeyCell(label: 'سنوات الخبرة', value: experienceYears)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _KeyCell(label: 'الجنسية', value: nationality)),
                  const SizedBox(width: 20),
                  Expanded(child: _KeyCell(label: 'الشركة', value: company)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
                height: 1.25,
              ),
        ),
      ],
    );
  }
}

class _LanguagesSection extends StatelessWidget {
  const _LanguagesSection({required this.languageNames});

  final List<String> languageNames;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اللغات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray800,
                    ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languageNames
                    .map(
                      (name) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.inputFill,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: AppTheme.gray200),
                        ),
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.gray800,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerAssignedWorkTypesSection extends StatelessWidget {
  const _WorkerAssignedWorkTypesSection({required this.assignments});

  final List<WorkerWorkTypeAssignmentEntity> assignments;

  static String _scheduleLabel(WorkerWorkTypeAssignmentEntity a) {
    final s = a.startTime.trim();
    final e = a.endTime.trim();
    if (s == '00:00' && e == '00:00') {
      return 'مرن / شهري';
    }
    return '$s – $e';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    size: 22,
                    color: AppTheme.primaryTeal.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'أنواع الخدمات المرتبطة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (assignments.isEmpty)
                Text(
                  'لا توجد خدمات مرتبطة بعد. استخدم «ربط خدمة» من قائمة العاملات.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray500,
                        height: 1.4,
                      ),
                )
              else
                ...assignments.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssignedWorkTypeRow(
                      name: a.workTypeName,
                      priceLabel:
                          '${a.displayPrice.toStringAsFixed(a.displayPrice == a.displayPrice.roundToDouble() ? 0 : 2)} ${AppConstants.currency}',
                      schedule: _scheduleLabel(a),
                      isOvernight: a.isOvernight,
                      linkedAt: a.createdAt,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignedWorkTypeRow extends StatelessWidget {
  const _AssignedWorkTypeRow({
    required this.name,
    required this.priceLabel,
    required this.schedule,
    required this.isOvernight,
    this.linkedAt,
  });

  final String name;
  final String priceLabel;
  final String schedule;
  final bool isOvernight;
  final DateTime? linkedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            priceLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            schedule,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray600,
                ),
          ),
          if (isOvernight) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppConstants.overnightText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.warningAmber,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
          if (linkedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'تاريخ الربط: ${DateFormatter.formatDisplayDate(linkedAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray400,
                    fontSize: 11,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthCertificateActionBanner extends StatelessWidget {
  const _HealthCertificateActionBanner({required this.workerName});

  final String workerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'انتهت صلاحية الشهادة الصحية لـ $workerName',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى تحديث الشهادة الصحية لاستمرار قبول الحجوزات لهذه العاملة.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray700,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تواصل مع الإدارة أو حدّث بيانات الشهادة عند توفر رفع الملف.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('تحديث الشهادة الصحية'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
          ),
        ],
      ),
    );
  }
}

class _HealthCertificateCard extends StatelessWidget {
  const _HealthCertificateCard({
    required this.expiryDate,
    required this.state,
  });

  final DateTime? expiryDate;
  final _HealthCertState state;

  @override
  Widget build(BuildContext context) {
    Color accent;
    String statusLabel;
    switch (state) {
      case _HealthCertState.none:
        accent = AppTheme.gray400;
        statusLabel = 'غير محدد';
        break;
      case _HealthCertState.valid:
        accent = AppTheme.successGreen;
        statusLabel = 'سارية';
        break;
      case _HealthCertState.expiring:
        accent = AppTheme.warningAmber;
        statusLabel = 'تنتهي قريباً';
        break;
      case _HealthCertState.expired:
        accent = AppTheme.dangerRed;
        statusLabel = 'منتهية';
        break;
    }

    final dateStr = expiryDate != null
        ? DateFormatter.formatDisplayDate(expiryDate!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.health_and_safety_outlined,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الشهادة الصحية',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تاريخ الانتهاء: $dateStr',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray600,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerDetailBookingsBar extends StatelessWidget {
  const _WorkerDetailBookingsBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: TextButton(
            onPressed: () => context.go(AppRoutes.bookings),
            child: Text(
              'عرض الحجوزات الخاصة بها',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
