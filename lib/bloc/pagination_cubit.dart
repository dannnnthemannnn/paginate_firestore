import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'pagination_state.dart';

class PaginationCubit extends Cubit<PaginationState> {
  PaginationCubit(
    this._query,
    this._limit,
    this._startAfterDocument, {
    this.isLive = false,
  }) : super(PaginationInitial());

  DocumentSnapshot _lastDocument;
  StreamSubscription<QuerySnapshot> _lastListener;
  int _maxIndex = -1;
  bool _loadNewPage = true;
  final int _limit;
  final Query _query;
  final DocumentSnapshot _startAfterDocument;
  final bool isLive;

  final List<StreamSubscription<QuerySnapshot>> _streams =
      List<StreamSubscription<QuerySnapshot>>();

  void filterPaginatedList(String searchTerm) {
    if (state is PaginationLoaded) {
      final loadedState = state as PaginationLoaded;

      final filteredList = loadedState.documentSnapshots
          .where((document) => document
              .data()
              .toString()
              .toLowerCase()
              .contains(searchTerm.toLowerCase()))
          .toList();

      emit(loadedState.copyWith(
        documentSnapshots: filteredList,
        hasReachedEnd: loadedState.hasReachedEnd,
      ));
    }
  }

  void refreshPaginatedList() async {
    _lastDocument = null;
    final localQuery = _getQuery();
    if (isLive) {
      _lastListener?.cancel();
      _lastListener = localQuery
          .snapshots(includeMetadataChanges: true)
          .where((s) => s.metadata.isFromCache == false)
          .listen((querySnapshot) {
        _emitPaginatedState(querySnapshot.docs);
      });
    } else {
      final querySnapshot = await localQuery.get();
      _emitPaginatedState(querySnapshot.docs);
    }
  }

  void fetchPaginatedList(int maxIndex) {
    if (maxIndex <= _maxIndex || !_loadNewPage) return;
    _loadNewPage = false;
    _maxIndex = maxIndex;
    isLive ? _getLiveDocuments() : _getDocuments();
  }

  _getDocuments() async {
    final localQuery = _getQuery();
    try {
      if (state is PaginationInitial) {
        refreshPaginatedList();
      } else if (state is PaginationLoaded) {
        final loadedState = state as PaginationLoaded;
        emit(loadedState.copyWith(isLoading: true));
        if (loadedState.hasReachedEnd) return;
        final querySnapshot = await localQuery.get();
        _emitPaginatedState(
          querySnapshot.docs,
          previousList: loadedState.documentSnapshots,
        );
      }
    } on PlatformException catch (exception) {
      print(exception);
      rethrow;
    }
  }

  _getLiveDocuments() {
    final localQuery = _getQuery();
    if (state is PaginationInitial) {
      refreshPaginatedList();
    } else if (state is PaginationLoaded) {
      final loadedState = state as PaginationLoaded;
      emit(loadedState.copyWith(isLoading: true));
      _lastListener.cancel();
      _lastListener = localQuery
          .snapshots(includeMetadataChanges: true)
          .where((s) => s.metadata.isFromCache == false)
          .listen((querySnapshot) {
        _emitPaginatedState(
          querySnapshot.docs,
          previousList: loadedState.documentSnapshots,
        );
      });
    }
  }

  void _emitPaginatedState(
    List<QueryDocumentSnapshot> newList, {
    List<QueryDocumentSnapshot> previousList = const [],
  }) {
    if (newList.length > _limit / 2) {
      _loadNewPage = true;
    }
    _lastDocument = newList.isNotEmpty ? newList.last : null;
    emit(PaginationLoaded(
      documentSnapshots: previousList + newList,
      isLoading: false,
      hasReachedEnd: newList.isEmpty,
    ));
  }

  Query _getQuery() {
    var localQuery = (_lastDocument != null)
        ? _query.startAfterDocument(_lastDocument)
        : _startAfterDocument != null
            ? _query.startAfterDocument(_startAfterDocument)
            : _query;
    localQuery = localQuery.limit(_limit);
    return localQuery;
  }

  void dispose() {
    _lastListener.cancel();
  }
}
