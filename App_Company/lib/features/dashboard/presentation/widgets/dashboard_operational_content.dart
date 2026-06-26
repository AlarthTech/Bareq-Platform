import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/saas/saas_card.dart';
import '../bloc/dashboard_state.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/presentation/widgets/booking_status_display.dart';

/// Operational-first dashboard body (corporate SaaS).
class DashboardOperationalContent extends StatelessWidget {
  const DashboardOperationalContent({
    super.key,
    required this.data,
    required this.onBookingReports,
  });

  final DashboardData data;
  final VoidCallback onBookingReports;

  String _dailySummary() {
    if (data.cleaningInProgressCount > 0) {
      return '${data.cleaningInProgressCount} حجزاً جاري التنفيذ الآن.';
    }
    if (data.pendingBookings > 0) {
      return '${data.pendingBookings} حجوزات بانتظار الموافقة.';
    }
    if (data.todayBookingsCount > 0) {
      return '${data.todayBookingsCount} حجوزات مجدولة لليوم.';
    }
    return 'لا توجد مهام عاجلة — يوم هادئ.';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        AppTheme.spacing32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SaasCard(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            color: AppTheme.primaryTeal.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: AppTheme.primaryTeal, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dailySummary(),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray800,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          Row(
            children: [
              Expanded(
                child: SaasKpiTile(
                  label: 'حجوزات اليوم',
                  value: '${data.todayBookingsCount}',
                  icon: Icons.event_available_rounded,
                  onTap: () => context.go(AppRoutes.bookings),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: SaasKpiTile(
                  label: 'عاملات نشطات',
                  value: '${data.activeWorkersCount}',
                  icon: Icons.groups_rounded,
                  accent: AppTheme.gray800,
                  onTap: () => context.go(AppRoutes.workers),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: SaasKpiTile(
                  label: 'متاحات الآن',
                  value: '${data.availableWorkersCount}',
                  icon: Icons.check_circle_outline_rounded,
                  subtitle: 'جاهزة للحجز',
                  onTap: () => context.go(AppRoutes.workers),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: SaasKpiTile(
                  label: 'إيراد الشهر',
                  value: '${data.monthlyCompletedBookings}',
                  icon: Icons.payments_outlined,
                  subtitle: 'حجوزات مكتملة',
                  accent: AppTheme.successGreen,
                  onTap: () => context.go(
                    AppRoutes.bookingsWithStatus(AppConstants.statusCompleted),
                  ),
                ),
              ),
            ],
          ),
          if (data.cleaningInProgressBookings.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing24),
            _SectionTitle(title: 'جاري التنفيذ'),
            const SizedBox(height: AppTheme.spacing12),
            ...data.cleaningInProgressBookings.take(4).map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                    child: _TodayBookingRow(booking: b),
                  ),
                ),
          ],
          if (data.todayBookings.isNotEmpty &&
              data.cleaningInProgressBookings.isEmpty) ...[
            const SizedBox(height: AppTheme.spacing24),
            _SectionTitle(title: 'جدول اليوم'),
            const SizedBox(height: AppTheme.spacing12),
            ...data.todayBookings.take(5).map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                    child: _TodayBookingRow(booking: b),
                  ),
                ),
          ],
          if (data.bookingsNeedingAttention.isNotEmpty ||
              data.workersWithExpiringHealthCertificates.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing24),
            _SectionTitle(title: 'يتطلب انتباهك'),
            const SizedBox(height: AppTheme.spacing12),
            SaasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (data.bookingsNeedingAttention.isNotEmpty)
                    _AlertLine(
                      icon: Icons.hourglass_top_rounded,
                      color: AppTheme.warningAmber,
                      text:
                          '${data.bookingsNeedingAttention.length} حجز متأخر في الانتظار',
                      onTap: () => context.go(
                        AppRoutes.bookingsWithStatus(AppConstants.statusPending),
                      ),
                    ),
                  if (data.workersWithExpiringHealthCertificates.isNotEmpty) ...[
                    if (data.bookingsNeedingAttention.isNotEmpty)
                      const SizedBox(height: 12),
                    _AlertLine(
                      icon: Icons.health_and_safety_outlined,
                      color: AppTheme.dangerRed,
                      text:
                          '${data.workersWithExpiringHealthCertificates.length} شهادة صحية تحتاج متابعة',
                      onTap: () => context.go(AppRoutes.workers),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          _SectionTitle(title: 'عمليات'),
          const SizedBox(height: AppTheme.spacing12),
          _OpsLink(
            icon: Icons.report_problem_outlined,
            title: 'بلاغات الحجوزات',
            onTap: onBookingReports,
          ),
          const SizedBox(height: AppTheme.spacing8),
          _OpsLink(
            icon: Icons.star_rate_rounded,
            title: 'التقييمات والمراجعات',
            onTap: () => context.push(AppRoutes.ratings),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.gray900,
          ),
    );
  }
}

class _TodayBookingRow extends StatelessWidget {
  const _TodayBookingRow({required this.booking});
  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final visual = bookingDisplayVisual(booking);
    return SaasCard(
      onTap: () => context.push(AppRoutes.bookingDetail(booking.id)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      child: Row(
        children: [
          BookingStatusPill(visual: visual),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  booking.customerDisplayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  booking.workTypeName ?? '—',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray500,
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

class _AlertLine extends StatelessWidget {
  const _AlertLine({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Row(
        children: [
          Icon(Icons.chevron_left, color: AppTheme.gray400, size: 20),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray800,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 20),
        ],
      ),
    );
  }
}

class _OpsLink extends StatelessWidget {
  const _OpsLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SaasCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      child: Row(
        children: [
          Icon(Icons.chevron_left, color: AppTheme.gray400),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: AppTheme.primaryTeal, size: 22),
        ],
      ),
    );
  }
}
