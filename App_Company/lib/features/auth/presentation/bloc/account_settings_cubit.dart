import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/change_personal_info_usecase.dart';
import '../../domain/usecases/change_phone_number_usecase.dart';

sealed class AccountSettingsState extends Equatable {
  const AccountSettingsState();

  @override
  List<Object?> get props => [];
}

class AccountSettingsIdle extends AccountSettingsState {
  const AccountSettingsIdle();
}

class AccountSettingsLoading extends AccountSettingsState {
  const AccountSettingsLoading();
}

class AccountSettingsSuccess extends AccountSettingsState {
  final String message;
  final UserEntity? updatedUser;

  const AccountSettingsSuccess(this.message, {this.updatedUser});

  @override
  List<Object?> get props => [message, updatedUser];
}

class AccountSettingsFailure extends AccountSettingsState {
  final String message;

  const AccountSettingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountSettingsCubit extends Cubit<AccountSettingsState> {
  AccountSettingsCubit({
    required ChangePasswordUseCase changePasswordUseCase,
    required ChangePersonalInfoUseCase changePersonalInfoUseCase,
    required ChangePhoneNumberUseCase changePhoneNumberUseCase,
  })  : _changePasswordUseCase = changePasswordUseCase,
        _changePersonalInfoUseCase = changePersonalInfoUseCase,
        _changePhoneNumberUseCase = changePhoneNumberUseCase,
        super(const AccountSettingsIdle());

  final ChangePasswordUseCase _changePasswordUseCase;
  final ChangePersonalInfoUseCase _changePersonalInfoUseCase;
  final ChangePhoneNumberUseCase _changePhoneNumberUseCase;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const AccountSettingsLoading());
    final result = await _changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    result.fold(
      (f) => emit(AccountSettingsFailure(f.message)),
      (_) => emit(const AccountSettingsSuccess('تم تغيير كلمة المرور بنجاح')),
    );
  }

  Future<void> changePersonalInfo({
    required String fullName,
    String? email,
    required UserEntity currentUser,
  }) async {
    emit(const AccountSettingsLoading());
    final result = await _changePersonalInfoUseCase(
      ChangePersonalInfoParams(fullName: fullName, email: email),
    );
    result.fold(
      (f) => emit(AccountSettingsFailure(f.message)),
      (user) {
        final merged = UserEntity(
          id: user.id != 0 ? user.id : currentUser.id,
          fullName: user.fullName.isNotEmpty ? user.fullName : fullName,
          phone: user.phone.isNotEmpty ? user.phone : currentUser.phone,
          email: user.email ?? email ?? currentUser.email,
          userTypeId: user.userTypeId != 0 ? user.userTypeId : currentUser.userTypeId,
          userTypeName: user.userTypeName ?? currentUser.userTypeName,
          createdAt: user.createdAt ?? currentUser.createdAt,
        );
        emit(AccountSettingsSuccess('تم تحديث البيانات الشخصية', updatedUser: merged));
      },
    );
  }

  Future<void> changePhone({
    required String phoneNumber,
    required UserEntity currentUser,
  }) async {
    emit(const AccountSettingsLoading());
    final result = await _changePhoneNumberUseCase(phoneNumber);
    result.fold(
      (f) => emit(AccountSettingsFailure(f.message)),
      (user) {
        final merged = UserEntity(
          id: user.id != 0 ? user.id : currentUser.id,
          fullName: user.fullName.isNotEmpty ? user.fullName : currentUser.fullName,
          phone: user.phone.isNotEmpty ? user.phone : phoneNumber,
          email: user.email ?? currentUser.email,
          userTypeId: user.userTypeId != 0 ? user.userTypeId : currentUser.userTypeId,
          userTypeName: user.userTypeName ?? currentUser.userTypeName,
          createdAt: user.createdAt ?? currentUser.createdAt,
        );
        emit(AccountSettingsSuccess('تم تحديث رقم الهاتف', updatedUser: merged));
      },
    );
  }

  void resetStatus() => emit(const AccountSettingsIdle());
}
