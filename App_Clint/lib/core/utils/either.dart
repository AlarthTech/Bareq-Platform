import 'package:equatable/equatable.dart';

/// Functional [Either] used across the app for success/failure flows.
abstract class Either<L, R> extends Equatable {
  const Either();

  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight);

  @override
  List<Object?> get props => [];
}

class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);

  @override
  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight) => onLeft(value);

  @override
  List<Object?> get props => [value];
}

class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);

  @override
  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight) => onRight(value);

  @override
  List<Object?> get props => [value];
}
