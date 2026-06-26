import '../../domain/entities/company_entity.dart';
import '../widgets/commercial_register_picker.dart';

class OnboardingSuccessExtra {
  const OnboardingSuccessExtra({
    required this.company,
    this.uploadFailed = false,
    this.registerFile,
    this.fromAddCompany = false,
  });

  final CompanyEntity company;
  final bool uploadFailed;
  final CommercialRegisterPickResult? registerFile;
  final bool fromAddCompany;
}
