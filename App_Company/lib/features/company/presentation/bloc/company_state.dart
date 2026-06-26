import 'package:equatable/equatable.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/entities/city_entity.dart';

abstract class CompanyState extends Equatable {
  const CompanyState();
  
  @override
  List<Object?> get props => [];
}

class CompanyInitial extends CompanyState {
  const CompanyInitial();
}

class CompanyLoading extends CompanyState {
  const CompanyLoading();
}

class CompanyLoaded extends CompanyState {
  const CompanyLoaded(this.companies, {this.selectedCompanyId});

  final List<CompanyEntity> companies;
  final int? selectedCompanyId;

  CompanyEntity? get activeCompany {
    if (companies.isEmpty) return null;
    if (selectedCompanyId != null) {
      for (final company in companies) {
        if (company.id == selectedCompanyId) return company;
      }
    }
    return companies.first;
  }

  int? get activeCompanyId => activeCompany?.id;

  CompanyLoaded copyWith({
    List<CompanyEntity>? companies,
    int? selectedCompanyId,
  }) {
    return CompanyLoaded(
      companies ?? this.companies,
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
    );
  }

  @override
  List<Object?> get props => [companies, selectedCompanyId];
}

class CompanyUpdated extends CompanyState {
  const CompanyUpdated(this.company);

  final CompanyEntity company;

  @override
  List<Object> get props => [company];
}

class CompanyCreated extends CompanyState {
  final CompanyEntity company;

  const CompanyCreated(this.company);

  @override
  List<Object> get props => [company];
}

class CommercialRegisterUploaded extends CompanyState {
  const CommercialRegisterUploaded(this.company);

  final CompanyEntity company;

  @override
  List<Object> get props => [company];
}

class CommercialRegisterUploading extends CompanyState {
  const CommercialRegisterUploading();
}

class CitiesLoaded extends CompanyState {
  final List<CityEntity> cities;
  
  const CitiesLoaded(this.cities);
  
  @override
  List<Object> get props => [cities];
}

class CompanyError extends CompanyState {
  final String message;
  
  const CompanyError(this.message);
  
  @override
  List<Object> get props => [message];
}
