import 'dart:typed_data';

import '../../domain/repositories/company_repository.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/entities/city_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../datasources/company_remote_datasource.dart';
import 'package:dartz/dartz.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl(this.remoteDataSource);

  final CompanyRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<CompanyEntity>>> getMyCompany(int userId) async {
    try {
      final companies = await remoteDataSource.getMyCompany(userId);
      return Right(companies.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, CompanyEntity>> createCompany({
    required String name,
    String? address,
    String? commercialRegNo,
    required String phone,
    required String email,
    required int ownerUserId,
    required int cityId,
    int experienceYears = 0,
    String? description,
  }) async {
    try {
      final company = await remoteDataSource.createCompany(
        name: name,
        address: address,
        commercialRegNo: commercialRegNo,
        phone: phone,
        email: email,
        ownerUserId: ownerUserId,
        cityId: cityId,
        experienceYears: experienceYears,
        description: description,
      );
      return Right(company.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, CompanyEntity>> uploadCommercialRegister({
    required int companyId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    try {
      final company = await remoteDataSource.uploadCommercialRegister(
        companyId: companyId,
        fileName: fileName,
        filePath: filePath,
        bytes: bytes,
      );
      return Right(company.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, CompanyEntity>> updateCompany({
    required int companyId,
    required String name,
    String? address,
    String? commercialRegNo,
    String? commercialRegisterURL,
    required String email,
    required int cityId,
    int experienceYears = 0,
    String? description,
  }) async {
    try {
      final company = await remoteDataSource.updateCompany(
        companyId: companyId,
        name: name,
        address: address,
        commercialRegNo: commercialRegNo,
        commercialRegisterURL: commercialRegisterURL,
        email: email,
        cityId: cityId,
        experienceYears: experienceYears,
        description: description,
      );
      return Right(company.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, List<CityEntity>>> getAllCities() async {
    try {
      final cities = await remoteDataSource.getAllCities();
      return Right(cities.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}
