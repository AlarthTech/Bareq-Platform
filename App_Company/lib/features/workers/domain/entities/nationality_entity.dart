import 'package:equatable/equatable.dart';

class NationalityEntity extends Equatable {
  final int id;
  final String name;
  final bool isActive;
  
  const NationalityEntity({
    required this.id,
    required this.name,
    required this.isActive,
  });
  
  @override
  List<Object> get props => [id, name, isActive];
}
