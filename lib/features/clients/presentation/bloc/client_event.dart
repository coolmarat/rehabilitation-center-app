part of 'client_bloc.dart';

abstract class ClientEvent extends Equatable {
  const ClientEvent();

  @override
  List<Object?> get props => [];
}

// Событие для первоначальной загрузки данных
class LoadClients extends ClientEvent {}

// События для Родителей
class AddParentRequested extends ClientEvent {
  final Parent parent;
  const AddParentRequested(this.parent);
  @override
  List<Object?> get props => [parent];
}

class UpdateParentRequested extends ClientEvent {
  final Parent parent;
  const UpdateParentRequested(this.parent);
  @override
  List<Object?> get props => [parent];
}

class DeleteParentRequested extends ClientEvent {
  final int parentId;
  const DeleteParentRequested(this.parentId);
  @override
  List<Object?> get props => [parentId];
}

// События для Детей
class AddChildRequested extends ClientEvent {
  final Child child;
  const AddChildRequested(this.child);
  @override
  List<Object?> get props => [child];
}

class UpdateChildRequested extends ClientEvent {
  final Child child;
  const UpdateChildRequested(this.child);
  @override
  List<Object?> get props => [child];
}

class DeleteChildRequested extends ClientEvent {
  final int childId;
  const DeleteChildRequested(this.childId);
  @override
  List<Object> get props => [childId];
}

// Новое событие для очистки сообщения
class ClearClientMessage extends ClientEvent {
  const ClearClientMessage();
  @override
  List<Object> get props => [];
}

// Событие изменения поискового запроса
class SearchQueryChanged extends ClientEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}
