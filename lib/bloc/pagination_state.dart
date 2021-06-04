part of 'pagination_cubit.dart';

@immutable
abstract class PaginationState {}

class PaginationInitial extends PaginationState {}

class PaginationError extends PaginationState {
  final Exception error;
  PaginationError({@required this.error});

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is PaginationError && o.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

class PaginationLoaded extends PaginationState {
  PaginationLoaded({
    @required this.documentSnapshots,
    @required this.isLoading,
    @required this.hasReachedEnd,
  });

  final bool hasReachedEnd;
  final bool isLoading;
  final List<DocumentSnapshot> documentSnapshots;

  PaginationLoaded copyWith({
    bool hasReachedEnd,
    bool isLoading,
    List<DocumentSnapshot> documentSnapshots,
  }) {
    return PaginationLoaded(
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoading: isLoading ?? this.isLoading,
      documentSnapshots: documentSnapshots ?? this.documentSnapshots,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is PaginationLoaded &&
        o.hasReachedEnd == hasReachedEnd &&
        o.isLoading == isLoading &&
        listEquals(o.documentSnapshots, documentSnapshots);
  }

  @override
  int get hashCode =>
      hasReachedEnd.hashCode ^ documentSnapshots.hashCode ^ isLoading.hashCode;
}
