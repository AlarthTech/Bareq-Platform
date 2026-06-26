import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/city.dart';
import '../entities/social_auth_provider.dart';
import '../entities/social_login_result.dart';
import '../entities/user.dart';

/// Auth repository interface
/// Defined in domain layer - framework agnostic
abstract class AuthRepository {
  /// Register a new customer
  /// Returns Either<Failure, void> - success means registration completed
  Future<Either<Failure, void>> registerCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int cityId,
  });

  /// Get all active cities
  /// Returns Either<Failure, List<City>>
  Future<Either<Failure, List<City>>> getAllCities();

  /// Login user
  /// Returns Either<Failure, User> - success contains user entity
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  });

  /// Social login (Google, Apple, Facebook).
  Future<Either<Failure, SocialLoginResult>> socialLoginCustomer({
    required SocialAuthProvider provider,
    String? idToken,
    String? accessToken,
    String? fullName,
    String? phone,
  });

  /// Persist profile-completion gate flag locally.
  Future<Either<Failure, void>> setRequiresProfileCompletion(bool value);

  /// Read profile-completion gate flag.
  Future<Either<Failure, bool>> getRequiresProfileCompletion();

  /// Save user to local storage
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> saveUser(User user);

  /// Get current user from local storage
  /// Returns Either<Failure, User?>
  Future<Either<Failure, User?>> getCurrentUser();

  /// Clear user data (logout)
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> clearUser();

  /// Check if user is authenticated (has valid token)
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> isAuthenticated();

  /// Get all app users (customers)
  /// Returns Either<Failure, List<User>>
  Future<Either<Failure, List<User>>> getAllAppUsers();

  /// PUT ChangePhoneNumber — JWT identifies user.
  Future<Either<Failure, User>> changePhone(String newPhone);

  /// Completes social-login profile with phone and city.
  Future<Either<Failure, User>> completeProfile({
    required String phone,
    required int cityId,
  });

  /// PUT ChangePassword — server validates current password.
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// PUT ChangePersonalInfo — updates name and email.
  Future<Either<Failure, User>> changePersonalInfo({
    required String fullName,
    required String email,
  });

  /// Deletes the signed-in user account and clears local session.
  Future<Either<Failure, void>> deleteAccount();
}

