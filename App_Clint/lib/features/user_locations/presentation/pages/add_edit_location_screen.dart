import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/create_user_location_usecase.dart';
import '../../domain/usecases/update_user_location_usecase.dart';
import '../widgets/location_map_picker.dart';

class AddEditLocationScreen extends StatefulWidget {
  const AddEditLocationScreen({super.key, this.existing});

  final UserLocation? existing;

  @override
  State<AddEditLocationScreen> createState() => _AddEditLocationScreenState();
}

class _AddEditLocationScreenState extends State<AddEditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  LatLng _pin = kDefaultMapCenter;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.locationName;
      _pin = LatLng(e.lat, e.lng);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = L10n.of(context);

    if (_isEdit) {
      final result = await sl<UpdateUserLocationUseCase>()(
        id: widget.existing!.id,
        locationName: _nameController.text.trim(),
        lat: _pin.latitude,
        lng: _pin.longitude,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      result.fold(
        (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.translate('locationUpdated') ?? 'Updated'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        },
      );
    } else {
      final result = await sl<CreateUserLocationUseCase>()(
        locationName: _nameController.text.trim(),
        lat: _pin.latitude,
        lng: _pin.longitude,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      result.fold(
        (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.translate('locationCreated') ?? 'Location saved'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title:
            _isEdit
                ? (l10n?.translate('editLocation') ?? 'Edit location')
                : (l10n?.translate('addLocation') ?? 'Add location'),
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n?.translate('tapMapToSetPin') ??
                    'Tap the map to set the pin location',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              LocationMapPicker(
                center: _pin,
                onPositionChanged: (p) => setState(() => _pin = p),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText:
                      l10n?.translate('locationName') ?? 'Location name',
                  hintText: l10n?.translate('locationNameHint') ?? 'e.g. Home',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n?.translate('fieldRequired') ?? 'Required'
                            : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child:
                    _saving
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(l10n?.translate('save') ?? 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
