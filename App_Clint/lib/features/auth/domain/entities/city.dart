import 'package:equatable/equatable.dart';

/// City entity representing a city in the domain layer
class City extends Equatable {
  final int id;
  final String name;
  final String? code;
  final bool isActive;

  const City({
    required this.id,
    required this.name,
    this.code,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, code, isActive];
}

