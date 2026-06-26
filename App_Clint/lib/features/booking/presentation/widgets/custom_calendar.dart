import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common/bareq_nav_chevron.dart';
import '../../../../core/utils/western_numerals.dart';

/// Custom Calendar Widget with Modern Soft Feminine styling
/// Features:
/// - Selected date: Dusty Rose filled circle with white text and subtle shadow
/// - Today (not selected): Thin rose outline
/// - Disabled dates: Low opacity gray
class CustomCalendar extends StatelessWidget {
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onDateSelected;
  final DateTime focusedDay;

  /// When set, days strictly before this calendar date are not selectable.
  final DateTime? minimumSelectableDate;
  /// Additional custom availability predicate (true => selectable).
  final bool Function(DateTime day)? isDateEnabled;
  final void Function(DateTime focusedDay)? onPageChanged;

  /// When false, hides [TableCalendar]'s built‑in header (month title + chevrons).
  final bool headerVisible;

  const CustomCalendar({
    super.key,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    required this.focusedDay,
    this.minimumSelectableDate,
    this.isDateEnabled,
    this.onPageChanged,
    this.headerVisible = true,
  });

  static bool _isOnOrAfterCalendarDay(DateTime day, DateTime min) {
    final d = DateTime(day.year, day.month, day.day);
    final m = DateTime(min.year, min.month, min.day);
    return !d.isBefore(m);
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: firstDate,
      lastDay: lastDate,
      focusedDay: focusedDay,
      headerVisible: headerVisible,
      enabledDayPredicate:
          (day) {
            if (minimumSelectableDate != null &&
                !_isOnOrAfterCalendarDay(day, minimumSelectableDate!)) {
              return false;
            }
            if (isDateEnabled != null && !isDateEnabled!(day)) {
              return false;
            }
            return true;
          },
      selectedDayPredicate: (day) {
        return selectedDate != null && isSameDay(selectedDate, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        onDateSelected(selectedDay);
      },
      onPageChanged: onPageChanged,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      calendarStyle: CalendarStyle(
        // Selected date styling - Dusty Rose filled circle with white text
        selectedDecoration: BoxDecoration(
          color: AppColors.primary, // Dusty Rose
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),

        // Today (not selected) - Thin rose outline
        todayDecoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        todayTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),

        // Default date styling
        defaultTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),

        // Weekend styling (subtle difference)
        weekendTextStyle: TextStyle(
          color: AppColors.textPrimary.withOpacity(0.7),
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),

        // Disabled dates - Low opacity gray
        disabledTextStyle: TextStyle(
          color: AppColors.textDisabled,
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),

        // Outside days (from previous/next month)
        outsideTextStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.4),
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),

        // Outside days decoration
        outsideDecoration: const BoxDecoration(shape: BoxShape.circle),

        // Default day decoration
        defaultDecoration: const BoxDecoration(shape: BoxShape.circle),

        // Weekend decoration
        weekendDecoration: const BoxDecoration(shape: BoxShape.circle),

        // Disabled decoration
        disabledDecoration: const BoxDecoration(shape: BoxShape.circle),

        // Marker for today (small dot below date)
        markerDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),

      // Header styling
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, locale) {
          // English month names regardless of app locale.
          return WesternNumerals.normalize(DateFormat.yMMMM('en').format(date));
        },
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        leftChevronIcon: const BareqStepChevron(
          direction: BareqStepDirection.back,
          color: AppColors.textPrimary,
        ),
        rightChevronIcon: const BareqStepChevron(
          direction: BareqStepDirection.forward,
          color: AppColors.textPrimary,
        ),
        leftChevronMargin: const EdgeInsets.only(left: 8),
        rightChevronMargin: const EdgeInsets.only(right: 8),
      ),

      // Days of week styling
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        weekendStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),

      // Row height
      rowHeight: 48,

      // Calendar builders for additional customization
      calendarBuilders: CalendarBuilders(
        // Selected day builder - ensure it's clearly visible
        selectedBuilder: (context, date, events) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary, // Dusty Rose
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },

        // Today builder (when not selected)
        todayBuilder: (context, date, events) {
          final isSelected =
              selectedDate != null && isSameDay(selectedDate, date);

          if (isSelected) {
            // If today is selected, use selected styling
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          // Today but not selected - show outline
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },

        // Default day builder
        defaultBuilder: (context, date, events) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },

        // Disabled day builder
        disabledBuilder: (context, date, events) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },

        // Outside day builder (from previous/next month)
        outsideBuilder: (context, date, events) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
