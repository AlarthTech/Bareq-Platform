import 'package:equatable/equatable.dart';

class CityEntity extends Equatable {
  final int id;
  final String name;
  final bool isActive;
  
  const CityEntity({
    required this.id,
    required this.name,
    required this.isActive,
  });
  
  @override
  List<Object> get props => [id, name, isActive];
}
