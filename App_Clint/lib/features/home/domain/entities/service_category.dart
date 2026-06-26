import 'package:equatable/equatable.dart';

/// Service category entity
class ServiceCategory extends Equatable {
  final String id;
  final String name;
  final String icon; // Icon identifier or path

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  @override
  List<Object?> get props => [id, name, icon];
}






