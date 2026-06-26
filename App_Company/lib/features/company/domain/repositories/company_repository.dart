import 'dart:typed_data';

import '../entities/company_entity.dart';
import '../entities/city_entity.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class CompanyRepository {
  Future<Either<Failure, List<CompanyEntity>>> getMyCompany(int userId);
  Future<Either<Failure, CompanyEntity>> createCompany({
    required String name,
    String? address,
    String? commercialRegNo,
    required String phone,
    required String email,
    required int ownerUserId,
    required int cityId,
    int experienceYears,
    String? description,
  });
  Future<Either<Failure, CompanyEntity>> uploadCommercialRegister({
    required int companyId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  });
  Future<Either<Failure, CompanyEntity>> updateCompany({
    required int companyId,
    required String name,
    String? address,
    String? commercialRegNo,
    String? commercialRegisterURL,
    required String email,
    required int cityId,
    int experienceYears,
    String? description,
  });
  Future<Either<Failure, List<CityEntity>>> getAllCities();
}
