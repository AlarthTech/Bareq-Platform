import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/presentation/widgets/paged_list_footer.dart';
import '../../../../core/widgets/main_tab_scaffold.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/saas/saas_card.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_entity.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../cubit/booking_realtime_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';
import '../models/booking_detail_extra.dart';
import '../widgets/booking_status_display.dart';

// --- Tabs & list model ---

enum _BookingTab { all, today, upcoming, completed, cancelled }

enum _DateBucket { today, tomorrow, thisWeek, later, past }

class _ListEntry {
  const _ListEntry.header(this.title) : booking = null;
  const _ListEntry.card(this.booking) : title = null;

  final String? title;
  final BookingEntity? booking;
  bool get isHeader => title != null;
}

// --- Screen ---

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  _BookingTab _tab = _BookingTab.all;
  bool _searchOpen = false;
  String _searchQuery = '';
  bool _sortNewestFirst = true;
  /// Deep-link: dashboard «جارية» — approved + on the way only.
  bool _ongoingOnlyFilter = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onBookingsScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated) {
        context.read<CompanyBloc>().add(GetMyCompanyEvent(auth.user.id));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onBookingsScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onBookingsScroll() {
    if (!_scrollController.hasClients) return;
    final bookingState = context.read<BookingBloc>().state;
    if (bookingState is! BookingsLoaded ||
        bookingState.isLoadingMore ||
        !bookingState.hasNextPage) {
      return;
    }
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 240) {
      return;
    }
    final cs = context.read<CompanyBloc>().state;
    if (cs is CompanyLoaded && cs.companies.isNotEmpty) {
      context.read<BookingBloc>().add(
            LoadMoreBookingsEvent(cs.activeCompanyId!),
          );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final filter = uri.queryParameters['filter'];
    final q = uri.queryParameters['status'];
    final s = int.tryParse(q ?? '');
    _BookingTab? fromQuery;
    if (filter == 'ongoing') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _ongoingOnlyFilter = true;
            _tab = _BookingTab.all;
          });
        }
      });
    }
    if (s == AppConstants.statusCompleted) fromQuery = _BookingTab.completed;
    if (s == AppConstants.statusCanceled) fromQuery = _BookingTab.cancelled;
    if (fromQuery != null && fromQuery != _tab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _tab = fromQuery!;
            _ongoingOnlyFilter = false;
          });
        }
      });
    }
    if (filter != 'ongoing' && q == null && _ongoingOnlyFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _ongoingOnlyFilter = false);
      });
    }
  }

  void _loadBookings() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(auth.user.id));
    }
    final cs = context.read<CompanyBloc>().state;
    if (cs is CompanyLoaded && cs.companies.isNotEmpty) {
      context.read<BookingBloc>().add(GetBookingsEvent(cs.activeCompanyId!));
    }
  }

  Map<_BookingTab, int> _computeTabCounts(List<BookingEntity> all) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    int countToday() =>
        all.where((b) => b.bookingDate != null && _sameDay(_dateOnly(b.bookingDate!), todayStart)).length;
    int countUpcoming() => all.where((b) {
          if (b.bookingDate == null) return false;
          if (AppConstants.isBookingTerminal(b.status)) return false;
          final d = _dateOnly(b.bookingDate!);
          return !d.isBefore(todayStart);
        }).length;

    return {
      _BookingTab.all: all.length,
      _BookingTab.today: countToday(),
      _BookingTab.upcoming: countUpcoming(),
      _BookingTab.completed: all.where((b) => b.status == AppConstants.statusCompleted).length,
      _BookingTab.cancelled:
          all.where((b) => AppConstants.isBookingCanceledOrRejected(b.status)).length,
    };
  }

  List<BookingEntity> _applyTab(List<BookingEntity> all) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (_tab) {
      case _BookingTab.all:
        return List.of(all);
      case _BookingTab.today:
        return all.where((b) => b.bookingDate != null && _sameDay(_dateOnly(b.bookingDate!), todayStart)).toList();
      case _BookingTab.upcoming:
        return all.where((b) {
          if (b.bookingDate == null) return false;
          if (AppConstants.isBookingTerminal(b.status)) return false;
          final d = _dateOnly(b.bookingDate!);
          return !d.isBefore(todayStart);
        }).toList();
      case _BookingTab.completed:
        return all.where((b) => b.status == AppConstants.statusCompleted).toList();
      case _BookingTab.cancelled:
        return all.where((b) => AppConstants.isBookingCanceledOrRejected(b.status)).toList();
    }
  }

  List<BookingEntity> _applySearch(List<BookingEntity> list) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    bool match(String? s) => s != null && s.toLowerCase().contains(q);
    return list.where((b) {
      return b.customerDisplayName.toLowerCase().contains(q) ||
          match(b.workerName) ||
          match(b.companyName) ||
          match(b.workTypeName) ||
          match(b.location);
    }).toList();
  }

  void _sortList(List<BookingEntity> list) {
    int cmp(BookingEntity a, BookingEntity b) {
      final da = a.bookingDate;
      final db = b.bookingDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      final c = da.compareTo(db);
      return _sortNewestFirst ? -c : c;
    }

    list.sort(cmp);
  }

  List<_ListEntry> _buildEntries(List<BookingEntity> filtered) {
    if (filtered.isEmpty) return [];

    final list = List<BookingEntity>.of(filtered);
    _sortList(list);

    if (_tab == _BookingTab.completed || _tab == _BookingTab.cancelled) {
      return list.map((b) => _ListEntry.card(b)).toList();
    }

    if (_tab == _BookingTab.today) {
      return [
        const _ListEntry.header('اليوم'),
        ...list.map((b) => _ListEntry.card(b)),
      ];
    }

    final buckets = <_DateBucket, List<BookingEntity>>{
      _DateBucket.today: [],
      _DateBucket.tomorrow: [],
      _DateBucket.thisWeek: [],
      _DateBucket.later: [],
      _DateBucket.past: [],
    };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekEnd = _endOfWeekSunday(todayStart);

    for (final b in list) {
      if (b.bookingDate == null) {
        buckets[_DateBucket.later]!.add(b);
        continue;
      }
      final d = _dateOnly(b.bookingDate!);
      if (d.isBefore(todayStart)) {
        buckets[_DateBucket.past]!.add(b);
      } else if (_sameDay(d, todayStart)) {
        buckets[_DateBucket.today]!.add(b);
      } else if (_sameDay(d, tomorrowStart)) {
        buckets[_DateBucket.tomorrow]!.add(b);
      } else if (d.isAfter(tomorrowStart) && !d.isAfter(weekEnd)) {
        buckets[_DateBucket.thisWeek]!.add(b);
      } else {
        buckets[_DateBucket.later]!.add(b);
      }
    }

    final entries = <_ListEntry>[];
    void addSection(String title, List<BookingEntity> items) {
      if (items.isEmpty) return;
      entries.add(_ListEntry.header(title));
      for (final b in items) {
        entries.add(_ListEntry.card(b));
      }
    }

    addSection('اليوم', buckets[_DateBucket.today]!);
    addSection('غداً', buckets[_DateBucket.tomorrow]!);
    addSection('هذا الأسبوع', buckets[_DateBucket.thisWeek]!);
    addSection('لاحقاً', buckets[_DateBucket.later]!);
    addSection('سابقة', buckets[_DateBucket.past]!);

    return entries;
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ترتيب التاريخ',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              RadioListTile<bool>(
                title: const Text('الأحدث أولاً'),
                value: true,
                groupValue: _sortNewestFirst,
                activeColor: AppTheme.primaryTeal,
                onChanged: (v) {
                  if (v != null) setState(() => _sortNewestFirst = v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<bool>(
                title: const Text('الأقدم أولاً'),
                value: false,
                groupValue: _sortNewestFirst,
                activeColor: AppTheme.primaryTeal,
                onChanged: (v) {
                  if (v != null) setState(() => _sortNewestFirst = v);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingRealtimeCubit, BookingRealtimeState>(
      listenWhen: (prev, curr) =>
          curr.lastEvent != null && prev.lastEvent != curr.lastEvent,
      listener: (context, state) {
        final event = state.lastEvent;
        if (event == null) return;
        context.read<BookingBloc>().add(
              BookingStatusChangedRealtimeEvent(
                bookingId: event.bookingId,
                status: event.status,
              ),
            );
      },
      child: BlocListener<CompanyBloc, CompanyState>(
      listenWhen: (prev, curr) =>
          curr is CompanyLoaded &&
          curr.companies.isNotEmpty &&
          (prev is! CompanyLoaded || prev.companies.isEmpty),
      listener: (context, state) {
        if (state is CompanyLoaded && state.companies.isNotEmpty) {
          context.read<BookingBloc>().add(GetBookingsEvent(state.activeCompanyId!));
        }
      },
      child: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.dangerRed),
            );
          }
        },
        child: MainTabScaffold(
          title: 'الحجوزات',
          subtitle: 'إدارة الحجوزات ومتابعتها',
          currentNavIndex: AppRoutes.navBookings,
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'بحث',
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                    icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded, size: 22),
                    onPressed: () => setState(() {
                      _searchOpen = !_searchOpen;
                      if (!_searchOpen) _searchQuery = '';
                    }),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'ترتيب',
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                    icon: const Icon(Icons.tune_rounded, size: 22),
                    onPressed: _showSortSheet,
                  ),
                ],
              ),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: AnimationConstants.microInteraction,
                curve: Curves.easeOutCubic,
                child: _searchOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacing16,
                          0,
                          AppTheme.spacing16,
                          AppTheme.spacing8,
                        ),
                        child: TextField(
                          autofocus: true,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'بحث (عميل، عاملة، شركة، نوع العمل، العنوان)…',
                            prefixIcon: const Icon(Icons.search, size: 22),
                            filled: true,
                            fillColor: AppTheme.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing16,
                              vertical: AppTheme.spacing12,
                            ),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              BlocBuilder<BookingBloc, BookingState>(
                buildWhen: (p, c) =>
                    c is BookingsLoaded || c is BookingLoading || c is BookingError,
                builder: (context, bookingState) {
                  final counts = bookingState is BookingsLoaded
                      ? _computeTabCounts(bookingState.bookings)
                      : null;
                  return _BookingTabStrip(
                    selected: _tab,
                    counts: counts,
                    onChanged: (t) => setState(() {
                      _tab = t;
                      _ongoingOnlyFilter = false;
                    }),
                  );
                },
              ),
              Expanded(
                child: BlocBuilder<BookingBloc, BookingState>(
                  buildWhen: (prev, curr) =>
                      curr is BookingLoading ||
                      curr is BookingsLoaded ||
                      curr is BookingError ||
                      curr is BookingInitial,
                  builder: (context, state) {
                    if (state is BookingLoading) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        itemCount: 6,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                          child: _BookingCardSkeleton(),
                        ),
                      );
                    }

                    if (state is BookingError) {
                      return ErrorStateWidget(message: state.message, onRetry: _loadBookings);
                    }

                    if (state is BookingsLoaded) {
                      var filtered = _applyTab(state.bookings);
                      if (_ongoingOnlyFilter) {
                        filtered = filtered
                            .where(
                              (b) =>
                                  b.status == AppConstants.statusApproved ||
                                  b.status == AppConstants.statusOnTheWay,
                            )
                            .toList();
                      }
                      filtered = _applySearch(filtered);

                      if (state.bookings.isEmpty) {
                        return _BookingsEmpty(onCreate: () => context.go(AppRoutes.dashboard));
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_alt_off_outlined, size: 48, color: AppTheme.gray400),
                                const SizedBox(height: AppTheme.spacing16),
                                Text(
                                  'لا توجد نتائج مطابقة',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.gray600),
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _tab = _BookingTab.all;
                                    _searchQuery = '';
                                    _searchOpen = false;
                                    _ongoingOnlyFilter = false;
                                  }),
                                  child: const Text('إعادة ضبط العرض'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final entries = _buildEntries(filtered);
                      var itemIndex = 0;
                      final showEndHint =
                          filtered.length <= 4 && filtered.isNotEmpty && !state.hasNextPage;
                      final footerCount =
                          (state.hasNextPage || state.isLoadingMore) ? 1 : (showEndHint ? 1 : 0);

                      return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.spacing16,
                            AppTheme.spacing8,
                            AppTheme.spacing16,
                            AppTheme.spacing24,
                          ),
                          itemCount: entries.length + footerCount,
                          itemBuilder: (context, index) {
                            if (index >= entries.length) {
                              if (state.hasNextPage || state.isLoadingMore) {
                                return PagedListFooter(
                                  isLoadingMore: state.isLoadingMore,
                                  hasNextPage: state.hasNextPage,
                                );
                              }
                              return _BookingsListEndHint(isTodayTab: _tab == _BookingTab.today);
                            }
                            final e = entries[index];
                            if (e.isHeader) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppTheme.spacing4,
                                  bottom: AppTheme.spacing12,
                                ),
                                child: _SectionHeader(title: e.title!),
                              );
                            }
                            final booking = e.booking!;
                            final anim = itemIndex++;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                              child: _BookingCardInteractive(
                                booking: booking,
                                index: anim,
                                onTap: () {
                                  context.push(
                                    AppRoutes.bookingDetail(booking.id),
                                    extra: BookingDetailExtra(
                                      booking: booking,
                                      bookingBloc: context.read<BookingBloc>(),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                    }

                    return _BookingsEmpty(onCreate: () => context.go(AppRoutes.dashboard));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// --- Tab strip ---

class _BookingTabStrip extends StatelessWidget {
  const _BookingTabStrip({
    required this.selected,
    required this.onChanged,
    this.counts,
  });

  final _BookingTab selected;
  final ValueChanged<_BookingTab> onChanged;
  final Map<_BookingTab, int>? counts;

  static const _tabs = <(_BookingTab, String)>[
    (_BookingTab.all, 'الكل'),
    (_BookingTab.today, 'اليوم'),
    (_BookingTab.upcoming, 'القادمة'),
    (_BookingTab.completed, 'المكتملة'),
    (_BookingTab.cancelled, 'ملغى / مرفوض'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing12, 0, AppTheme.spacing12, AppTheme.spacing8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: SingleChildScrollView(
          key: ValueKey<String>(counts?.values.join('-') ?? 'loading'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (tab, label) in _tabs)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppTheme.spacing12),
                  child: _BookingFilterChip(
                    label: label,
                    count: counts?[tab],
                    selected: selected == tab,
                    onTap: () => onChanged(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingFilterChip extends StatelessWidget {
  const _BookingFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final showCount = count != null && count! > 0;
    final text = showCount ? '$label ($count)' : label;

    return AnimatedScale(
      scale: selected ? 1.04 : 1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryTeal : AppTheme.gray50,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: selected ? AppTheme.primaryTeal : AppTheme.gray200,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            splashColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
            highlightColor: AppTheme.primaryTeal.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.gray700,
                      fontSize: 13,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing12, bottom: AppTheme.spacing12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              thickness: 1,
              height: 1,
              color: AppTheme.gray200.withValues(alpha: 0.95),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray500,
                    letterSpacing: 0.35,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              thickness: 1,
              height: 1,
              color: AppTheme.gray200.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Card (enterprise list tile) ---

class _BookingCardDateTimeLine extends StatelessWidget {
  const _BookingCardDateTimeLine({required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.gray800,
          fontWeight: FontWeight.w600,
        );
    final datePart = _fmtDateCompact(booking.bookingDate);
    final timePart = _timeRange(booking);
    if (booking.bookingDate == null) {
      return Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Text(
          timePart,
          textAlign: TextAlign.right,
          style: baseStyle?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: datePart),
          const TextSpan(text: ' • '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                timePart,
                style: baseStyle?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.right,
    );
  }
}

class _BookingCardInteractive extends StatefulWidget {
  const _BookingCardInteractive({
    required this.booking,
    required this.index,
    required this.onTap,
  });

  final BookingEntity booking;
  final int index;
  final VoidCallback onTap;

  @override
  State<_BookingCardInteractive> createState() => _BookingCardInteractiveState();
}

class _BookingCardInteractiveState extends State<_BookingCardInteractive> {
  Future<void> _callCustomer(String? phone) async {
    final raw = phone?.trim();
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم هاتف للعميلة')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: raw);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final visual = bookingDisplayVisual(b);
    final rejected = AppConstants.isBookingCanceledOrRejected(b.status);
    final todayHighlight = _isTodayBooking(b);
    final service = b.workTypeName?.trim().isNotEmpty == true ? b.workTypeName!.trim() : '—';
    final maid = (b.workerName != null && b.workerName!.trim().isNotEmpty) ? b.workerName!.trim() : '—';
    final loc = b.displayAddress?.trim();
    final maidInitial = maid != '—' && maid.isNotEmpty ? maid.substring(0, 1) : '?';

    final card = Opacity(
      opacity: rejected ? 0.85 : 1,
      child: SaasCard(
        color: todayHighlight ? AppTheme.gray50 : Colors.white,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: BookingStatusPill(visual: visual, large: true),
                        ),
                        const Spacer(),
                        _WorkerMiniAvatar(initial: maidInitial),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      b.customerDisplayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.gray900,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$service • $maid',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _BookingCardDateTimeLine(booking: b),
                    if (visual.showArrivalConfirmedHint) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: BookingArrivalConfirmedChip(),
                      ),
                    ],
                    if (loc != null && loc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        loc,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.gray500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callCustomer(b.customerPhone),
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: const Text('اتصال بالعميلة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('التفاصيل'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (widget.index * AnimationConstants.staggerMs).ms)
        .fadeIn(duration: AnimationConstants.fadeIn, curve: AnimationConstants.fadeInCurve);

    return card;
  }
}

class _WorkerMiniAvatar extends StatelessWidget {
  const _WorkerMiniAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryTeal.withValues(alpha: 0.12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppTheme.primaryTeal,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _BookingCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: LoadingShimmerWidget(height: 18, borderRadius: BorderRadius.circular(4))),
                      LoadingShimmerWidget(width: 64, height: 24, borderRadius: BorderRadius.circular(999)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LoadingShimmerWidget(height: 13, width: 220, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 10),
                  LoadingShimmerWidget(height: 12, width: 180, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  LoadingShimmerWidget(height: 11, width: 140, borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ),
          ),
          LoadingShimmerWidget(
            width: 3,
            height: double.infinity,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppTheme.radiusLarge)),
          ),
        ],
      ),
    );
  }
}

class _BookingsListEndHint extends StatelessWidget {
  const _BookingsListEndHint({required this.isTodayTab});

  final bool isTodayTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing16, bottom: AppTheme.spacing32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gray100,
              border: Border.all(color: AppTheme.gray200.withValues(alpha: 0.9)),
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 34,
              color: AppTheme.gray400.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            isTodayTab ? 'لا توجد حجوزات أخرى اليوم' : 'لقد وصلت إلى نهاية القائمة',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isTodayTab ? 'يمكنك مراجعة التبويبات الأخرى أو البحث عن حجز محدد.' : 'جرّب تغيير التصفية أو البحث لعرض المزيد.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _BookingsEmpty extends StatelessWidget {
  const _BookingsEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryTeal.withValues(alpha: 0.12),
                    AppTheme.secondaryBlue.withValues(alpha: 0.08),
                  ],
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Icon(
                Icons.event_available_outlined,
                size: 52,
                color: AppTheme.primaryTeal.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'لا توجد حجوزات حالياً',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gray800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'ستظهر الحجوزات الجديدة هنا فور إضافتها.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
              label: const Text('إنشاء حجز جديد'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helpers ---

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

DateTime _endOfWeekSunday(DateTime dayInWeek) {
  final monday = dayInWeek.subtract(Duration(days: dayInWeek.weekday - DateTime.monday));
  final monday0 = _dateOnly(monday);
  return monday0.add(const Duration(days: 6));
}

String _fmtDateCompact(DateTime? d) {
  if (d == null) return '—';
  return DateFormatter.formatDisplayWeekdayCompact(d);
}

String _timeRange(BookingEntity b) {
  final s = b.startTime;
  final e = b.endTime;
  if (s == null && e == null) return '—';
  if (s != null && e != null) return '$s → $e';
  return s ?? e ?? '—';
}

bool _isTodayBooking(BookingEntity b) {
  if (b.bookingDate == null) return false;
  final now = DateTime.now();
  return _sameDay(b.bookingDate!, now);
}

