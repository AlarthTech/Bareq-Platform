import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_input_types.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/language_entity.dart';
import '../../domain/entities/nationality_entity.dart';
import '../../domain/entities/worker_entity.dart';
import '../../domain/repositories/worker_repository.dart';
import '../../domain/usecases/get_languages_usecase.dart';
import '../../domain/usecases/get_nationalities_usecase.dart';
import '../../domain/usecases/update_worker_usecase.dart';
import '../utils/worker_form_validation.dart';
import 'health_certificate_picker.dart';

class EditWorkerSheet {
  EditWorkerSheet._();

  static Future<bool?> show(
    BuildContext context, {
    required WorkerEntity worker,
  }) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (ctx) => _EditWorkerSheetContent(worker: worker),
    );
  }
}

class _EditWorkerSheetContent extends StatefulWidget {
  const _EditWorkerSheetContent({required this.worker});

  final WorkerEntity worker;

  @override
  State<_EditWorkerSheetContent> createState() => _EditWorkerSheetContentState();
}

class _EditWorkerSheetContentState extends State<_EditWorkerSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _experienceController;

  List<NationalityEntity> _nationalities = [];
  List<LanguageEntity> _languages = [];
  bool _loading = true;
  bool _saving = false;
  int? _selectedNationalityId;
  final Set<int> _selectedLanguageIds = {};
  HealthCertificatePickResult? _healthCertificateFile;
  DateTime? _healthCertificateExpiryDate;

  @override
  void initState() {
    super.initState();
    final w = widget.worker;
    _nameController = TextEditingController(text: w.fullName);
    _ageController = TextEditingController(text: '${w.age}');
    _experienceController = TextEditingController(text: '${w.experienceYears}');
    _selectedNationalityId = w.nationalityId;
    _healthCertificateExpiryDate = w.healthCertificateExpiryDate;
    final raw = w.languagesIds;
    if (raw != null && raw.trim().isNotEmpty) {
      for (final part in raw.split(',')) {
        final id = int.tryParse(part.trim());
        if (id != null) _selectedLanguageIds.add(id);
      }
    }
    _loadLookups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final natResult = await getIt<GetNationalitiesUseCase>()();
    final langResult = await getIt<GetLanguagesUseCase>()();
    if (!mounted) return;
    setState(() {
      _nationalities = natResult.fold((_) => <NationalityEntity>[], (l) => l);
      _languages = langResult.fold((_) => <LanguageEntity>[], (l) => l);
      _loading = false;
    });
  }

  String? _nationalityLabel() {
    final id = _selectedNationalityId;
    if (id == null) return null;
    for (final n in _nationalities) {
      if (n.id == id) return n.name;
    }
    return widget.worker.nationalityName.isNotEmpty
        ? widget.worker.nationalityName
        : null;
  }

  Future<void> _pickNationality() async {
    if (_nationalities.isEmpty || _saving) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView.builder(
          controller: controller,
          itemCount: _nationalities.length,
          itemBuilder: (_, i) {
            final n = _nationalities[i];
            final selected = n.id == _selectedNationalityId;
            return ListTile(
              title: Text(n.name),
              trailing: selected
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal)
                  : null,
              onTap: () {
                setState(() => _selectedNationalityId = n.id);
                Navigator.of(ctx).pop();
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickHealthCertificate() async {
    if (_saving) return;
    try {
      final picked = await HealthCertificatePicker.pick();
      if (!mounted || picked == null) return;
      setState(() => _healthCertificateFile = picked);
    } on HealthCertificatePickerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.dangerRed),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    if (_saving) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _healthCertificateExpiryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _healthCertificateExpiryDate = picked);
    }
  }

  Future<void> _onSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNationalityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الجنسية')),
      );
      return;
    }
    if (_selectedLanguageIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار لغة واحدة على الأقل')),
      );
      return;
    }
    if (_healthCertificateFile != null && _healthCertificateExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ انتهاء الشهادة الصحية')),
      );
      return;
    }

    setState(() => _saving = true);

    final w = widget.worker;
    final languagesIds = _selectedLanguageIds.join(',');
    final updateResult = await getIt<UpdateWorkerUseCase>()(
      UpdateWorkerParams(
        workerId: w.id,
        fullName: _nameController.text.trim(),
        nationalityId: _selectedNationalityId!,
        age: int.parse(_ageController.text.trim()),
        experienceYears: int.parse(_experienceController.text.trim()),
        healthCertificateURL: w.healthCertificateURL,
        healthCertificateExpiryDate: _healthCertificateExpiryDate,
        languagesIds: languagesIds,
      ),
    );

    if (!mounted) return;

    await updateResult.fold(
      (failure) async {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      },
      (_) async {
        if (_healthCertificateFile != null) {
          final uploadResult =
              await getIt<WorkerRepository>().uploadHealthCertificate(
            workerId: w.id,
            fileName: _healthCertificateFile!.name,
            filePath: _healthCertificateFile!.path,
            bytes: _healthCertificateFile!.bytes,
          );
          if (!mounted) return;
          await uploadResult.fold(
            (failure) async {
              setState(() => _saving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حفظ البيانات لكن فشل رفع الشهادة: ${failure.message}',
                  ),
                  backgroundColor: AppTheme.dangerRed,
                ),
              );
              Navigator.of(context).pop(true);
            },
            (_) async {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث بيانات العاملة بنجاح')),
              );
              Navigator.of(context).pop(true);
            },
          );
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بيانات العاملة بنجاح')),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تعديل بيانات العاملة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.worker.fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _saving ? null : _pickNationality,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'الجنسية',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _nationalityLabel() ?? 'اختر الجنسية',
                      style: TextStyle(
                        color: _nationalityLabel() == null
                            ? AppTheme.gray500
                            : AppTheme.gray900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  enabled: !_saving,
                  textAlign: TextAlign.right,
                  keyboardType: AppInputTypes.numberType1,
                  inputFormatters: [
                    ...AppInputTypes.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(
                    labelText: 'العمر',
                    hintText:
                        'من ${AppConstants.workerMinAge} إلى ${AppConstants.workerMaxAge}',
                    border: const OutlineInputBorder(),
                  ),
                  validator: WorkerFormValidation.validateAge,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _experienceController,
                  enabled: !_saving,
                  textAlign: TextAlign.right,
                  keyboardType: AppInputTypes.numberType1,
                  inputFormatters: [
                    ...AppInputTypes.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(
                    labelText: 'سنوات الخبرة',
                    hintText: WorkerFormValidation.parseAge(_ageController.text) !=
                            null
                        ? 'أقل من ${WorkerFormValidation.parseAge(_ageController.text)}'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => WorkerFormValidation.validateExperienceYears(
                    v,
                    age: WorkerFormValidation.parseAge(_ageController.text),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'اللغات',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _languages.map((lang) {
                    final selected = _selectedLanguageIds.contains(lang.id);
                    return FilterChip(
                      label: Text(lang.name),
                      selected: selected,
                      onSelected: _saving
                          ? null
                          : (_) {
                              setState(() {
                                if (selected) {
                                  _selectedLanguageIds.remove(lang.id);
                                } else {
                                  _selectedLanguageIds.add(lang.id);
                                }
                              });
                            },
                      selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                      checkmarkColor: AppTheme.primaryTeal,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'الشهادة الصحية',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickHealthCertificate,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _healthCertificateFile?.name ??
                        (widget.worker.healthCertificateURL != null
                            ? 'استبدال الشهادة الحالية'
                            : 'تحميل الشهادة الصحية'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_healthCertificateFile != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _healthCertificateFile = null),
                      child: const Text('إزالة الملف المختار'),
                    ),
                  ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _saving ? null : _pickExpiryDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ انتهاء الشهادة',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _healthCertificateExpiryDate != null
                          ? DateFormatter.formatDate(_healthCertificateExpiryDate!)
                          : 'اختر التاريخ',
                      style: TextStyle(
                        color: _healthCertificateExpiryDate == null
                            ? AppTheme.gray500
                            : AppTheme.gray900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _onSave,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حفظ التعديلات'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
