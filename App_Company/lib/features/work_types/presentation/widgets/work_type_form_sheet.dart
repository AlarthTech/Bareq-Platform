import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_input_types.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/work_type_entity.dart';

typedef WorkTypeFormSubmit = void Function({
  required String name,
  required bool isMonthly,
  required double price,
  String? startTime,
  String? endTime,
});

/// Shared add/edit form for daily and monthly work types.
class WorkTypeFormSheet extends StatefulWidget {
  const WorkTypeFormSheet({
    super.key,
    this.initial,
    required this.onSubmit,
    this.isSubmitting = false,
    this.submitLabel = 'حفظ',
  });

  final WorkTypeEntity? initial;
  final WorkTypeFormSubmit onSubmit;
  final bool isSubmitting;
  final String submitLabel;

  @override
  State<WorkTypeFormSheet> createState() => _WorkTypeFormSheetState();
}

class _WorkTypeFormSheetState extends State<WorkTypeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late bool _isMonthly;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _isMonthly = initial?.isMonthly ?? false;
    _nameController = TextEditingController(text: initial?.name ?? '');
    final price = initial?.displayPrice ?? 0;
    _priceController = TextEditingController(
      text: price > 0 ? price.toStringAsFixed(0) : '',
    );
    _startTime = _parseTime(initial?.startTime, const TimeOfDay(hour: 8, minute: 0));
    _endTime = _parseTime(initial?.endTime, const TimeOfDay(hour: 17, minute: 0));
  }

  TimeOfDay _parseTime(String? raw, TimeOfDay fallback) {
    if (raw == null || raw.isEmpty || raw == '00:00') return fallback;
    final parts = raw.split(':');
    if (parts.length < 2) return fallback;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? fallback.hour,
      minute: int.tryParse(parts[1]) ?? fallback.minute,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _hm(TimeOfDay t) => hourMinuteToHm(t.hour, t.minute);

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawPrice = _priceController.text.replaceAll(',', '.').trim();
    final price = double.tryParse(rawPrice);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال سعر أكبر من صفر'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    widget.onSubmit(
      name: _nameController.text.trim(),
      isMonthly: _isMonthly,
      price: price,
      startTime: _isMonthly ? null : _hm(_startTime),
      endTime: _isMonthly ? null : _hm(_endTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('دوام يومي')),
              ButtonSegment(value: true, label: Text('دوام شهري')),
            ],
            selected: {_isMonthly},
            onSelectionChanged: widget.isSubmitting
                ? null
                : (s) => setState(() => _isMonthly = s.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppTheme.gray700;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryTeal;
                }
                return AppTheme.inputFill;
              }),
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          TextFormField(
            controller: _nameController,
            textAlign: TextAlign.right,
            enabled: !widget.isSubmitting,
            decoration: const InputDecoration(
              labelText: 'اسم التصنيف',
              filled: true,
              fillColor: AppTheme.inputFill,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'يرجى إدخال اسم التصنيف' : null,
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _priceController,
            keyboardType: AppInputTypes.numberType1,
            inputFormatters: AppInputTypes.digitsOnly,
            textAlign: TextAlign.right,
            enabled: !widget.isSubmitting,
            decoration: InputDecoration(
              labelText: _isMonthly ? 'السعر الشهري (د.ل)' : 'السعر اليومي (د.ل)',
              filled: true,
              fillColor: AppTheme.inputFill,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return _isMonthly
                    ? 'في الدوام الشهري يجب إدخال السعر'
                    : 'يرجى إدخال السعر';
              }
              final p = double.tryParse(v.trim());
              if (p == null || p <= 0) return 'يرجى إدخال سعر صحيح';
              return null;
            },
          ),
          if (!_isMonthly) ...[
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isSubmitting ? null : () => _pickTime(isStart: true),
                    child: Text('البداية: ${formatTimeHm(_hm(_startTime))}'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isSubmitting ? null : () => _pickTime(isStart: false),
                    child: Text('النهاية: ${formatTimeHm(_hm(_endTime))}'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          FilledButton(
            onPressed: widget.isSubmitting ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            ),
            child: widget.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
