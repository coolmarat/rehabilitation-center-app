import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rehabilitation_center_app/core/usecases/usecase.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/get_parents_with_children.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_parent_balance.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final GetParentsWithChildren _getParentsWithChildren;
  final AddParent _addParent;
  final UpdateParent _updateParent;
  final DeleteParent _deleteParent;
  final AddChild _addChild;
  final UpdateChild _updateChild;
  final DeleteChild _deleteChild;
  final UpdateParentBalance _updateParentBalance;

  Map<Parent, List<Child>> _allParentsWithChildren = {};

  ClientBloc({
    required GetParentsWithChildren getParentsWithChildren,
    required AddParent addParent,
    required UpdateParent updateParent,
    required DeleteParent deleteParent,
    required AddChild addChild,
    required UpdateChild updateChild,
    required DeleteChild deleteChild,
    required UpdateParentBalance updateParentBalance,
  })  : _getParentsWithChildren = getParentsWithChildren,
        _addParent = addParent,
        _updateParent = updateParent,
        _deleteParent = deleteParent,
        _addChild = addChild,
        _updateChild = updateChild,
        _deleteChild = deleteChild,
        _updateParentBalance = updateParentBalance,
        super(const ClientState()) {
    on<LoadClients>(_onLoadClients);
    on<AddParentRequested>(_onAddParentRequested);
    on<UpdateParentRequested>(_onUpdateParentRequested);
    on<DeleteParentRequested>(_onDeleteParentRequested);
    on<AddChildRequested>(_onAddChildRequested);
    on<UpdateChildRequested>(_onUpdateChildRequested);
    on<DeleteChildRequested>(_onDeleteChildRequested);
    on<ClearClientMessage>(_onClearClientMessage);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<TopUpBalance>(_onTopUpBalance);

    add(LoadClients());
  }

  Future<void> _onTopUpBalance(
    TopUpBalance event,
    Emitter<ClientState> emit,
  ) async {
    emit(state.copyWith(status: ClientStatus.loading));
    final result = await _updateParentBalance(
      UpdateParentBalanceParams(parentId: event.parentId, amount: event.amount),
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: ClientStatus.failure,
        errorMessage: 'Не удалось пополнить баланс: ${failure.toString()}',
      )),
      (_) async {
        await _loadData(emit, successMessage: 'Баланс успешно пополнен!');
      },
    );
  }

  Future<void> _loadData(Emitter<ClientState> emit, {String? successMessage}) async {
    final result = await _getParentsWithChildren(NoParams());
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ClientStatus.failure,
          errorMessage: 'Ошибка загрузки данных: ${failure.toString()}',
        ));
      },
      (data) {
        _allParentsWithChildren = data;
        _emitFilteredState(emit, state.searchQuery, successMessage: successMessage);
      },
    );
  }

  void _emitFilteredState(Emitter<ClientState> emit, String query, {String? successMessage, ClientStatus? status}) {
    final normalizedQuery = query.toLowerCase();
    Map<Parent, List<Child>> filteredData;
    Set<int> expandedIds = {};

    if (normalizedQuery.isEmpty) {
      filteredData = Map.from(_allParentsWithChildren);
    } else {
      filteredData = {};
      _allParentsWithChildren.forEach((parent, children) {
        final parentMatches = parent.fullName.toLowerCase().contains(normalizedQuery);
        final childMatches = children.any((child) => child.fullName.toLowerCase().contains(normalizedQuery));

        if (parentMatches || childMatches) {
          filteredData[parent] = children;
          if (!parentMatches && childMatches) {
            expandedIds.add(parent.id);
          }
        }
      });
    }

    emit(state.copyWith(
      status: status ?? ClientStatus.success,
      parentsWithChildren: filteredData,
      message: successMessage,
      clearMessage: successMessage == null,
      clearErrorMessage: true,
      initiallyExpandedParentIds: expandedIds,
      searchQuery: query,
    ));
  }

  Future<void> _onLoadClients(LoadClients event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    await _loadData(emit);
  }

  Future<void> _onAddParentRequested(AddParentRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    final result = await _addParent(event.parent);
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ClientStatus.failure,
          errorMessage: 'Ошибка добавления родителя: ${failure.toString()}',
        ));
      },
      (_) async {
        await _loadData(emit, successMessage: 'Родитель "${event.parent.fullName}" успешно добавлен.');
      },
    );
  }

  Future<void> _onUpdateParentRequested(UpdateParentRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    final result = await _updateParent(event.parent);
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ClientStatus.failure,
          errorMessage: 'Ошибка обновления родителя: ${failure.toString()}',
        ));
      },
      (_) async {
        await _loadData(emit, successMessage: 'Данные родителя "${event.parent.fullName}" обновлены.');
      },
    );
  }

  Future<void> _onDeleteParentRequested(DeleteParentRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    final result = await _deleteParent(event.parentId);
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ClientStatus.failure,
          errorMessage: 'Ошибка удаления родителя: ${failure.toString()}',
        ));
      },
      (_) async {
        await _loadData(emit, successMessage: 'Родитель удален.');
      },
    );
  }

  Future<void> _onAddChildRequested(AddChildRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    final result = await _addChild(event.child);
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ClientStatus.failure,
          errorMessage: 'Ошибка добавления ребенка: ${failure.toString()}',
        ));
      },
      (_) async {
        await _loadData(emit, successMessage: 'Ребенок "${event.child.fullName}" добавлен.');
      },
    );
  }

  Future<void> _onUpdateChildRequested(UpdateChildRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    final result = await _updateChild(event.child);
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ClientStatus.failure,
          errorMessage: 'Ошибка обновления ребенка: ${failure.toString()}',
        ));
      },
      (_) async {
        await _loadData(emit, successMessage: 'Данные ребенка "${event.child.fullName}" обновлены.');
      },
    );
  }

  Future<void> _onDeleteChildRequested(DeleteChildRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    final result = await _deleteChild(event.childId);
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ClientStatus.failure,
          errorMessage: 'Ошибка удаления ребенка: ${failure.toString()}',
        ));
      },
      (_) async {
        await _loadData(emit, successMessage: 'Ребенок удален.');
      },
    );
  }

  void _onClearClientMessage(ClearClientMessage event, Emitter<ClientState> emit) {
    emit(state.copyWith(clearMessage: true, clearErrorMessage: true));
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<ClientState> emit) {
    _emitFilteredState(emit, event.query);
  }
}
