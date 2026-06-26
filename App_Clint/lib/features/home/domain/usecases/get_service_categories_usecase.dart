import '../entities/service_category.dart';
import '../repositories/home_repository.dart';

/// Use case for getting service categories
class GetServiceCategoriesUseCase {
  final HomeRepository repository;

  GetServiceCategoriesUseCase(this.repository);

  Future<List<ServiceCategory>> call() async {
    return await repository.getServiceCategories();
  }
}






