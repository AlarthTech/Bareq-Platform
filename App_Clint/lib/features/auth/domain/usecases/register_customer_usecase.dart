import '../../../../core/error/failures.dart';
import '../../../../core/utils/phone_input_constraints.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

/// Use case for registering a new customer
/// Encapsulates business logic for customer registration
class RegisterCustomerUseCase {
  final AuthRepository repository;

  RegisterCustomerUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int cityId,
  }) async {
    // Business logic validation
    if (fullName.trim().isEmpty) {
      return const Left(ValidationFailure('Full name is required'));
    }

    if (fullName.trim().length < 2) {
      return const Left(ValidationFailure('Full name must be at least 2 characters'));
    }

    if (email.trim().isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }

    if (!email.contains('@') || !email.contains('.')) {
      return const Left(ValidationFailure('Invalid email format'));
    }

    if (phone.trim().isEmpty) {
      return const Left(ValidationFailure('Phone number is required'));
    }

    if (!PhoneInputConstraints.isValid(phone.trim())) {
      return const Left(
        ValidationFailure('Phone number must be 8 to 10 digits'),
      );
    }

    if (password.isEmpty) {
      return const Left(ValidationFailure('Password is required'));
    }

    if (password.length < 6) {
      return const Left(ValidationFailure('Password must be at least 6 characters'));
    }

    if (cityId <= 0) {
      return const Left(ValidationFailure('City is required'));
    }

    // Call repository
    return await repository.registerCustomer(
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      password: password,
      cityId: cityId,
    );
  }
}

