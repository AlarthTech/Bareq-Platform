import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/localization/l10n_helper.dart';
import '../../../../../core/widgets/common/app_top_bar.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../../auth/domain/entities/user.dart';
import '../../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../../auth/domain/usecases/change_personal_info_usecase.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await sl<GetCurrentUserUseCase>()();
    result.fold(
      (_) {},
      (user) {
        if (user == null || !mounted) return;
        final model = user is UserModel
            ? user
            : UserModel(
                id: user.id,
                username: user.username,
                fullName: user.fullName,
                email: user.email,
                phone: user.phone,
                token: user.token,
                tokenExpiration: user.tokenExpiration,
                role: user.role,
              );
        _user = model;
        _nameController.text = model.fullName ?? '';
        _emailController.text = model.email ?? '';
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    setState(() => _saving = true);
    final result = await sl<ChangePersonalInfoUseCase>()(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (user) {
        _user = user is UserModel ? user : _user;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.translate(context, 'profileUpdated'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('editProfile') ?? 'Edit Profile',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n?.translate('fullName') ?? 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? l10n?.translate('fieldRequired') ??
                                        'Required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n?.translate('email') ?? 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
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
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
