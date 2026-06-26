import '../../../../core/error/failures.dart';
import '../../../../core/auth/jwt_claims_helper.dart';
import '../../../../core/utils/phone_input_constraints.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/token_validator.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/social_auth_provider.dart';
import '../../domain/entities/social_login_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/city_model.dart';
import '../models/app_user_mapper.dart';
import '../models/user_model.dart';

/// Auth repository implementation
/// Implements domain repository interface
/// Handles data source selection and error mapping
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final void Function()? onSessionCleared;

  AuthRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource, {
    this.onSessionCleared,
  });

  void _notifySessionCleared() {
    onSessionCleared?.call();
  }

  /// Validates JWT, merges claims, persists user — shared by password & social login.
  Future<Either<Failure, User>> _persistLoginResponse(
    Map<String, dynamic> response,
  ) async {
    final userData = response['user'] as Map<String, dynamic>?;
    final token = response['token'] as String?;

    if (userData == null) {
      return const Left(
        ServerFailure('Invalid login response: user data not found'),
      );
    }

    final responseUserIdRaw = userData['id'] ?? userData['userId'];
    final responseUserId = int.tryParse(responseUserIdRaw?.toString() ?? '');

    final userDataWithToken = {
      ...userData,
      'token': token,
    };

    final payload = JwtClaimsHelper.decodePayload(token);
    final nameId = JwtClaimsHelper.nameIdentifier(payload);
    final nameIdInt = int.tryParse(nameId ?? '');
    if (nameIdInt == null) {
      await localDataSource.clearUser();
      return const Left(AuthFailure('Session invalid. Please login again.'));
    }
    if (responseUserId != null && responseUserId != nameIdInt) {
      await localDataSource.clearUser();
      return const Left(AuthFailure('Session invalid. Please login again.'));
    }

    final merged = JwtClaimsHelper.applyJwtToUserMap(userDataWithToken, token);
    if (merged['username'] == null && merged['email'] != null) {
      merged['username'] = merged['email'];
    }

    final loginUser = UserModel.fromJson(merged);
    await localDataSource.saveUser(loginUser);
    return Right(loginUser);
  }

  @override
  Future<Either<Failure, void>> registerCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int cityId,
  }) async {
    try {
      await remoteDataSource.registerCustomer(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        cityId: cityId,
      );
      return const Right(null);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      // Map server errors to appropriate failures
      if (e.message.toLowerCase().contains('email')) {
        return const Left(AuthFailure('Email already exists'));
      }
      if (e.message.toLowerCase().contains('phone')) {
        return const Left(AuthFailure('Phone number already exists'));
      }
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<City>>> getAllCities() async {
    try {
      final citiesJson = await remoteDataSource.getAllCities();
      final cities = citiesJson
          .map((json) => CityModel.fromJson(json))
          .where((city) => city.isActive)
          .toList();
      return Right(cities);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        username: username,
        password: password,
      );

      final persisted = await _persistLoginResponse(response);
      return persisted;
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      if (e.statusCode == 403) {
        return Left(
          ForbiddenFailure(
            e.message.isNotEmpty
                ? e.message
                : 'You do not have permission to sign in here. Please contact support.',
          ),
        );
      }
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('incorrect') ||
          e.message.toLowerCase().contains('wrong')) {
        return const Left(AuthFailure('Invalid username or password'));
      }
      return Left(e);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SocialLoginResult>> socialLoginCustomer({
    required SocialAuthProvider provider,
    String? idToken,
    String? accessToken,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await remoteDataSource.socialLoginCustomer(
        provider: provider,
        idToken: idToken,
        accessToken: accessToken,
        fullName: fullName,
        phone: phone,
      );

      final persisted = await _persistLoginResponse(response);
      return await persisted.fold(
        (failure) async => Left<Failure, SocialLoginResult>(failure),
        (user) async {
          final isNewUser = response['isNewUser'] as bool? ?? false;
          final requiresProfileCompletion =
              response['requiresProfileCompletion'] as bool? ?? false;
          await localDataSource.setRequiresProfileCompletion(
            requiresProfileCompletion,
          );
          return Right(
            SocialLoginResult(
              user: user,
              isNewUser: isNewUser,
              requiresProfileCompletion: requiresProfileCompletion,
            ),
          );
        },
      );
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      if (e.statusCode == 401) {
        return Left(
          AuthFailure(
            e.message.isNotEmpty
                ? e.message
                : 'رمز المصادقة غير صالح. حاول مرة أخرى.',
          ),
        );
      }
      if (e.statusCode == 409) {
        return Left(
          AuthFailure(
            e.message.isNotEmpty
                ? e.message
                : 'هذا الحساب مسجل بكلمة مرور. سجّل الدخول بالبريد الإلكتروني.',
          ),
        );
      }
      if (e.statusCode == 400) {
        return Left(
          AuthFailure(
            e.message.isNotEmpty
                ? e.message
                : 'تعذّر تسجيل الدخول الاجتماعي. تحقق من بياناتك وحاول مرة أخرى.',
          ),
        );
      }
      return Left(e);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setRequiresProfileCompletion(bool value) async {
    try {
      await localDataSource.setRequiresProfileCompletion(value);
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> getRequiresProfileCompletion() async {
    try {
      final value = await localDataSource.getRequiresProfileCompletion();
      return Right(value);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUser(User user) async {
    try {
      final userModel = UserModel(
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        token: user.token,
        tokenExpiration: user.tokenExpiration,
        role: user.role,
      );
      await localDataSource.saveUser(userModel);
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearUser() async {
    try {
      await localDataSource.clearUser();
      _notifySessionCleared();
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final user = await localDataSource.getCurrentUser();
      
      if (user == null) {
        return const Right(false);
      }

      // Check if token exists and is valid
      if (user.token == null || user.token!.isEmpty) {
        return const Right(false);
      }

      // Check token expiration if available
      if (user.tokenExpiration != null) {
        final isValid = DateTime.now().isBefore(user.tokenExpiration!);
        if (!isValid) {
          await localDataSource.clearUser();
          _notifySessionCleared();
          return const Right(false);
        }
        return const Right(true);
      }

      // If no expiration date, check JWT expiration if it's a JWT
      final isTokenValid = TokenValidator.isTokenValid(user.token);
      if (!isTokenValid) {
        await localDataSource.clearUser();
        _notifySessionCleared();
        return const Right(false);
      }

      return const Right(true);
    } on CacheFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getAllAppUsers() async {
    try {
      final usersJson = await remoteDataSource.getAllAppUsers();
      
      // Convert JSON to UserModel list
      final users = usersJson
          .map((json) => UserModel.fromJson(json))
          .toList();
      
      return Right(users);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> changePhone(String newPhone) async {
    final trimmed = newPhone.trim();
    if (!PhoneInputConstraints.isValid(trimmed)) {
      return const Left(
        ValidationFailure('Phone number must be 8 to 10 digits'),
      );
    }

    final current = await getCurrentUser();
    return current.fold(Left.new, (user) async {
      if (user == null) {
        return const Left(AuthFailure('You must be signed in.'));
      }

      try {
        final dto = await remoteDataSource.changePhoneNumber(phone: trimmed);
        final updated = appUserDtoToUserModel(extractAppUserDto(dto), user);
        await localDataSource.saveUser(updated);
        return Right(updated);
      } on Failure catch (e) {
        return Left(e);
      } catch (e) {
        return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, User>> completeProfile({
    required String phone,
    required int cityId,
  }) async {
    final trimmed = phone.trim();
    if (!PhoneInputConstraints.isValid(trimmed)) {
      return const Left(
        ValidationFailure('Phone number must be 8 to 10 digits'),
      );
    }
    if (cityId <= 0) {
      return const Left(ValidationFailure('City is required'));
    }

    final current = await getCurrentUser();
    return current.fold(Left.new, (user) async {
      if (user == null) {
        return const Left(AuthFailure('You must be signed in.'));
      }

      try {
        final response = await remoteDataSource.changePhoneNumber(
          phone: trimmed,
          cityId: cityId,
        );
        final updated = appUserDtoToUserModel(
          extractAppUserDto(response),
          user,
        );
        if (!updated.hasCompleteProfile) {
          return const Left(
            ServerFailure(
              'لم يتم حفظ الهاتف أو المدينة. حاول مرة أخرى.',
            ),
          );
        }
        await localDataSource.saveUser(updated);
        await localDataSource.setRequiresProfileCompletion(false);
        return Right(updated);
      } on ServerFailure catch (e) {
        if (e.statusCode == 400) {
          return Left(
            ValidationFailure(
              e.message.isNotEmpty
                  ? e.message
                  : 'تعذّر حفظ الملف. تحقق من رقم الهاتف والمدينة.',
            ),
          );
        }
        return Left(e);
      } on Failure catch (e) {
        return Left(e);
      } catch (e) {
        return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      return const Left(
        ValidationFailure('Password must be at least 6 characters'),
      );
    }

    final current = await getCurrentUser();
    return current.fold(Left.new, (user) async {
      if (user == null) {
        return const Left(AuthFailure('You must be signed in.'));
      }

      try {
        await remoteDataSource.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        final relogin = await login(
          username: user.username,
          password: newPassword,
        );
        return relogin.fold((failure) => Left(failure), (_) => const Right(null));
      } on Failure catch (e) {
        return Left(e);
      } catch (e) {
        return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, User>> changePersonalInfo({
    required String fullName,
    required String email,
  }) async {
    final name = fullName.trim();
    final mail = email.trim();
    if (name.isEmpty) {
      return const Left(ValidationFailure('Full name is required'));
    }
    if (mail.isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }

    final current = await getCurrentUser();
    return current.fold(Left.new, (user) async {
      if (user == null) {
        return const Left(AuthFailure('You must be signed in.'));
      }

      try {
        final dto = await remoteDataSource.changePersonalInfo(
          fullName: name,
          email: mail,
        );
        final updated = appUserDtoToUserModel(extractAppUserDto(dto), user);
        await localDataSource.saveUser(updated);
        return Right(updated);
      } on Failure catch (e) {
        return Left(e);
      } catch (e) {
        return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    final current = await getCurrentUser();
    return current.fold(Left.new, (user) async {
      if (user == null) {
        return const Left(AuthFailure('You must be signed in.'));
      }
      final userId = int.tryParse(user.id);
      if (userId == null) {
        return const Left(AuthFailure('Invalid user session.'));
      }

      try {
        await remoteDataSource.deleteAppUser(userId);
        await localDataSource.clearUser();
        _notifySessionCleared();
        return const Right(null);
      } on Failure catch (e) {
        return Left(e);
      } catch (e) {
        return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
      }
    });
  }
}

