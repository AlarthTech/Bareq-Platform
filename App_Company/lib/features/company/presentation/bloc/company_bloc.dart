import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/usecases/get_my_company_usecase.dart';
import '../../domain/usecases/create_company_usecase.dart';
import '../../domain/usecases/update_company_usecase.dart';
import '../../domain/usecases/get_all_cities_usecase.dart';
import '../../domain/usecases/upload_commercial_register_usecase.dart';
import '../../../../core/storage/company_session_storage.dart';
import 'company_event.dart';
import 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc({
    required GetMyCompanyUseCase getMyCompanyUseCase,
    required CreateCompanyUseCase createCompanyUseCase,
    required UpdateCompanyUseCase updateCompanyUseCase,
    required GetAllCitiesUseCase getAllCitiesUseCase,
    required UploadCommercialRegisterUseCase uploadCommercialRegisterUseCase,
  })  : _getMyCompanyUseCase = getMyCompanyUseCase,
        _createCompanyUseCase = createCompanyUseCase,
        _updateCompanyUseCase = updateCompanyUseCase,
        _getAllCitiesUseCase = getAllCitiesUseCase,
        _uploadCommercialRegisterUseCase = uploadCommercialRegisterUseCase,
        super(const CompanyInitial()) {
    on<GetMyCompanyEvent>(_onGetMyCompany);
    on<SelectActiveCompanyEvent>(_onSelectActiveCompany);
    on<CreateCompanyEvent>(_onCreateCompany);
    on<UpdateCompanyEvent>(_onUpdateCompany);
    on<GetAllCitiesEvent>(_onGetAllCities);
    on<UploadCommercialRegisterEvent>(_onUploadCommercialRegister);
  }

  final GetMyCompanyUseCase _getMyCompanyUseCase;
  final CreateCompanyUseCase _createCompanyUseCase;
  final UpdateCompanyUseCase _updateCompanyUseCase;
  final GetAllCitiesUseCase _getAllCitiesUseCase;
  final UploadCommercialRegisterUseCase _uploadCommercialRegisterUseCase;

  Future<int?> _resolveSelectedCompanyId(List<CompanyEntity> companies) async {
    if (companies.isEmpty) return null;
    final savedId = await CompanySessionStorage.readPrimaryCompanyId();
    if (savedId != null && companies.any((c) => c.id == savedId)) {
      return savedId;
    }
    return companies.first.id;
  }

  CompanyEntity _mergeCompanyUpdate(CompanyEntity existing, CompanyEntity updated) {
    return CompanyEntity(
      id: existing.id,
      name: updated.name,
      address: updated.address,
      commercialRegNo: updated.commercialRegNo,
      phone: updated.phone.isNotEmpty ? updated.phone : existing.phone,
      email: updated.email ?? existing.email,
      ownerUserId: updated.ownerUserId != 0 ? updated.ownerUserId : existing.ownerUserId,
      cityId: updated.cityId,
      cityName: existing.cityName,
      experienceYears: updated.experienceYears,
      description: updated.description,
      isVerified: existing.isVerified,
      commercialRegisterUrl:
          updated.commercialRegisterUrl ?? existing.commercialRegisterUrl,
      createdAt: existing.createdAt,
    );
  }

  Future<void> _onGetMyCompany(
    GetMyCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    if (!event.silent) {
      emit(const CompanyLoading());
    }

    final result = await _getMyCompanyUseCase(event.userId);

    await result.fold<Future<void>>(
      (failure) async => emit(CompanyError(failure.message)),
      (companies) async {
        final selectedId = await _resolveSelectedCompanyId(companies);
        if (selectedId != null) {
          await CompanySessionStorage.savePrimaryCompanyId(selectedId);
        }
        if (emit.isDone) return;
        emit(CompanyLoaded(companies, selectedCompanyId: selectedId));
      },
    );
  }

  Future<void> _onSelectActiveCompany(
    SelectActiveCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    final current = state;
    if (current is! CompanyLoaded) return;
    if (!current.companies.any((c) => c.id == event.companyId)) return;

    await CompanySessionStorage.savePrimaryCompanyId(event.companyId);
    emit(current.copyWith(selectedCompanyId: event.companyId));
  }

  Future<void> _onCreateCompany(
    CreateCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _createCompanyUseCase(
      CreateCompanyParams(
        name: event.name,
        address: event.address,
        commercialRegNo: event.commercialRegNo,
        phone: event.phone,
        email: event.email,
        ownerUserId: event.ownerUserId,
        cityId: event.cityId,
        experienceYears: event.experienceYears,
        description: event.description,
      ),
    );

    await result.fold<Future<void>>(
      (failure) async => emit(CompanyError(failure.message)),
      (company) async {
        await CompanySessionStorage.savePrimaryCompanyId(company.id);
        if (emit.isDone) return;
        emit(CompanyCreated(company));
      },
    );
  }

  Future<void> _onUpdateCompany(
    UpdateCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    final previousState = state;
    emit(const CompanyLoading());

    final result = await _updateCompanyUseCase(
      UpdateCompanyParams(
        companyId: event.companyId,
        name: event.name,
        address: event.address,
        commercialRegNo: event.commercialRegNo,
        commercialRegisterURL: event.commercialRegisterURL,
        email: event.email,
        cityId: event.cityId,
        experienceYears: event.experienceYears,
        description: event.description,
      ),
    );

    await result.fold<Future<void>>(
      (failure) async => emit(CompanyError(failure.message)),
      (company) async {
        if (emit.isDone) return;

        CompanyEntity resolved = company;
        if (previousState is CompanyLoaded) {
          for (final existing in previousState.companies) {
            if (existing.id == company.id) {
              resolved = _mergeCompanyUpdate(existing, company);
              break;
            }
          }
          final companies = previousState.companies
              .map((c) => c.id == company.id ? resolved : c)
              .toList();
          emit(CompanyUpdated(resolved));
          emit(
            CompanyLoaded(
              companies,
              selectedCompanyId: previousState.selectedCompanyId,
            ),
          );
        } else {
          emit(CompanyUpdated(resolved));
        }

        add(GetMyCompanyEvent(event.userId, silent: true));
      },
    );
  }

  Future<void> _onUploadCommercialRegister(
    UploadCommercialRegisterEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CommercialRegisterUploading());

    final result = await _uploadCommercialRegisterUseCase(
      companyId: event.companyId,
      fileName: event.fileName,
      filePath: event.filePath,
      bytes: event.bytes,
    );

    result.fold(
      (failure) => emit(CompanyError(failure.message)),
      (company) => emit(CommercialRegisterUploaded(company)),
    );
  }

  Future<void> _onGetAllCities(
    GetAllCitiesEvent event,
    Emitter<CompanyState> emit,
  ) async {
    final result = await _getAllCitiesUseCase();

    result.fold(
      (failure) => emit(CompanyError(failure.message)),
      (cities) => emit(CitiesLoaded(cities)),
    );
  }
}
