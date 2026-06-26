import 'package:equatable/equatable.dart';

/// Language entity representing a language in the domain layer
class Language extends Equatable {
  final int id;
  final String name;
  final String? code;
  final bool isActive;

  const Language({
    required this.id,
    required this.name,
    this.code,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, code, isActive];
}

