part of 'client_bloc.dart';

enum ClientStatus { initial, loading, success, failure }

class ClientState extends Equatable {
  final ClientStatus status;
  // Используем Map для хранения родителей и их детей
  final Map<Parent, List<Child>> parentsWithChildren;
  final String? errorMessage; // Сохраняем только сообщение об ошибке
  // Добавляем поле для сообщений (успех или ошибка)
  final String? message; 
  // Добавляем поле для поискового запроса
  final String searchQuery; 
  // Добавляем сет ID родителей, чьи карточки должны быть развернуты
  final Set<int> initiallyExpandedParentIds;

  const ClientState({
    this.status = ClientStatus.initial,
    this.parentsWithChildren = const {},
    this.errorMessage,
    this.message, // Инициализируем
    this.searchQuery = '', // Инициализируем пустой строкой
    this.initiallyExpandedParentIds = const {}, // Инициализируем пустым сетом
  });

  // Метод copyWith для удобного обновления состояния
  ClientState copyWith({
    ClientStatus? status,
    Map<Parent, List<Child>>? parentsWithChildren,
    String? errorMessage,
    // Очищаем сообщение об ошибке, если статус меняется на success/loading/initial
    bool clearErrorMessage = false,
    // Добавляем параметр для сообщения
    String? message,
    // Очищаем сообщение, если статус меняется на loading/initial
    bool clearMessage = false,
    // Добавляем searchQuery
    String? searchQuery,
    // Добавляем initiallyExpandedParentIds
    Set<int>? initiallyExpandedParentIds, 
  }) {
    return ClientState(
      status: status ?? this.status,
      parentsWithChildren: parentsWithChildren ?? this.parentsWithChildren,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      // Обновляем сообщение, если оно передано, или очищаем по флагу
      message: clearMessage ? null : message ?? this.message, 
      // Обновляем searchQuery
      searchQuery: searchQuery ?? this.searchQuery, 
      // Обновляем initiallyExpandedParentIds
      initiallyExpandedParentIds: initiallyExpandedParentIds ?? this.initiallyExpandedParentIds,
    );
  }

  @override
  // Добавляем message, searchQuery и initiallyExpandedParentIds в props
  List<Object?> get props => [status, parentsWithChildren, errorMessage, message, searchQuery, initiallyExpandedParentIds]; 
}
