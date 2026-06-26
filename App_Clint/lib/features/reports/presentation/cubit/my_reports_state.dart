import 'package:equatable/equatable.dart';

import '../../domain/entities/report.dart';

abstract class MyReportsState extends Equatable {
  const MyReportsState();

  @override
  List<Object?> get props => [];
}

class MyReportsInitial extends MyReportsState {
  const MyReportsInitial();
}

class MyReportsLoading extends MyReportsState {
  const MyReportsLoading();
}

class MyReportsLoaded extends MyReportsState {
  const MyReportsLoaded({
    required this.reports,
    required this.hasNextPage,
    required this.page,
    this.isLoadingMore = false,
  });

  final List<Report> reports;
  final bool hasNextPage;
  final int page;
  final bool isLoadingMore;

  MyReportsLoaded copyWith({
    List<Report>? reports,
    bool? hasNextPage,
    int? page,
    bool? isLoadingMore,
  }) {
    return MyReportsLoaded(
      reports: reports ?? this.reports,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [reports, hasNextPage, page, isLoadingMore];
}

class MyReportsError extends MyReportsState {
  const MyReportsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
