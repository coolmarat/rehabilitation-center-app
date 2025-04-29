import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/add_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/delete_parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/get_parents_with_children.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_child.dart';
import 'package:rehabilitation_center_app/features/clients/domain/usecases/update_parent.dart';

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

  // Внутреннее поле для хранения *всех* загруженных данных
  Map<Parent, List<Child>> _allParentsWithChildren = {};

  ClientBloc({
    required GetParentsWithChildren getParentsWithChildren,
    required AddParent addParent,
    required UpdateParent updateParent,
    required DeleteParent deleteParent,
    required AddChild addChild,
    required UpdateChild updateChild,
    required DeleteChild deleteChild,
  })  : _getParentsWithChildren = getParentsWithChildren,
        _addParent = addParent,
        _updateParent = updateParent,
        _deleteParent = deleteParent,
        _addChild = addChild,
        _updateChild = updateChild,
        _deleteChild = deleteChild,
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

    // Загружаем данные при инициализации BLoC
    add(LoadClients());
  }

  Future<void> _loadData(Emitter<ClientState> emit, {String? successMessage}) async {
    try {
      // Загружаем все данные
      _allParentsWithChildren = await _getParentsWithChildren();
      // Применяем текущую фильтрацию (из state) и обновляем состояние
      _emitFilteredState(emit, state.searchQuery, successMessage: successMessage);
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, errorMessage: e.toString(), message: 'Ошибка загрузки данных'));
    }
  }

  // Метод для применения фильтра и обновления состояния
  // Теперь принимает query как параметр
  void _emitFilteredState(Emitter<ClientState> emit, String query, {String? successMessage, ClientStatus? status}) {
    final normalizedQuery = query.toLowerCase();
    Map<Parent, List<Child>> filteredData;
    // Сет для ID родителей, которых нужно развернуть
    Set<int> expandedIds = {};

    if (normalizedQuery.isEmpty) {
      // Если запрос пуст, показываем все, разворачивать ничего не нужно
      filteredData = Map.from(_allParentsWithChildren);
    } else {
      // Иначе фильтруем
      filteredData = {};
      _allParentsWithChildren.forEach((parent, children) {
        // Проверяем ФИО родителя
        final parentMatches = parent.fullName.toLowerCase().contains(normalizedQuery);
        // Проверяем ФИО хотя бы одного ребенка
        final childMatches = children.any((child) => child.fullName.toLowerCase().contains(normalizedQuery));

        // Если совпадает родитель ИЛИ хотя бы один ребенок, добавляем родителя со ВСЕМИ его детьми
        if (parentMatches || childMatches) {
          filteredData[parent] = children;
          // Если совпадение НЕ в родителе, А ТОЛЬКО в ребенке, добавляем ID родителя для разворота
          if (!parentMatches && childMatches) {
            expandedIds.add(parent.id);
          }
        }
      });
    }

    // Обновляем состояние с отфильтрованными данными и ID для разворота
    emit(state.copyWith(
      // Используем переданный статус или текущий успешный статус
      status: status ?? ClientStatus.success,
      parentsWithChildren: filteredData,
      message: successMessage,
      clearMessage: successMessage == null, // Очищаем, если нет нового сообщения
      clearErrorMessage: true,
      // Передаем сет ID для разворота
      initiallyExpandedParentIds: expandedIds,
      // Устанавливаем актуальный поисковый запрос в состояние
      searchQuery: query,
    ));
  }

  Future<void> _onLoadClients(LoadClients event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    await _loadData(emit);
  }

  Future<void> _onAddParentRequested(AddParentRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _addParent(event.parent);
      // Передаем сообщение об успехе в _loadData
      await _loadData(emit, successMessage: 'Родитель "${event.parent.fullName}" успешно добавлен.');
    } catch (e) {
      // Устанавливаем сообщение об ошибке
      emit(state.copyWith(status: ClientStatus.failure, errorMessage: e.toString(), message: 'Ошибка добавления родителя'));
    }
  }

  Future<void> _onUpdateParentRequested(UpdateParentRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _updateParent(event.parent);
      await _loadData(emit, successMessage: 'Данные родителя "${event.parent.fullName}" обновлены.');
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, errorMessage: e.toString(), message: 'Ошибка обновления родителя'));
    }
  }

  Future<void> _onDeleteParentRequested(DeleteParentRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _deleteParent(event.parentId);
      await _loadData(emit, successMessage: 'Родитель удален.');
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, errorMessage: e.toString(), message: 'Ошибка удаления родителя'));
    }
  }

  Future<void> _onAddChildRequested(AddChildRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _addChild(event.child);
      await _loadData(emit, successMessage: 'Ребенок "${event.child.fullName}" добавлен.');
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, errorMessage: e.toString(), message: 'Ошибка добавления ребенка'));
    }
  }

  Future<void> _onUpdateChildRequested(UpdateChildRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _updateChild(event.child);
      await _loadData(emit, successMessage: 'Данные ребенка "${event.child.fullName}" обновлены.');
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, errorMessage: e.toString(), message: 'Ошибка обновления ребенка'));
    }
  }

  Future<void> _onDeleteChildRequested(DeleteChildRequested event, Emitter<ClientState> emit) async {
    emit(state.copyWith(status: ClientStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _deleteChild(event.childId);
      await _loadData(emit, successMessage: 'Ребенок удален.');
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, errorMessage: e.toString(), message: 'Ошибка удаления ребенка'));
    }
  }

  void _onClearClientMessage(ClearClientMessage event, Emitter<ClientState> emit) {
    emit(state.copyWith(clearMessage: true)); // Используем флаг clearMessage в copyWith
  }

  // Обработчик изменения поискового запроса
  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<ClientState> emit) {
    // Просто вызываем фильтрацию с новым запросом
    // _emitFilteredState сам обновит и searchQuery, и отфильтрованные данные в состоянии
    _emitFilteredState(emit, event.query);
  }
}
