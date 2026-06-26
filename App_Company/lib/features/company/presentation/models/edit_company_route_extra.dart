import '../../domain/entities/company_entity.dart';
import '../bloc/company_bloc.dart';

class EditCompanyRouteExtra {
  const EditCompanyRouteExtra({
    required this.company,
    required this.companyBloc,
  });

  final CompanyEntity company;
  final CompanyBloc companyBloc;
}
