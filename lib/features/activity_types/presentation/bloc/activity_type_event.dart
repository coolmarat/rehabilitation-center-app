part of 'activity_type_bloc.dart';

abstract class ActivityTypeEvent extends Equatable {
  const ActivityTypeEvent();

  @override
  List<Object> get props => [];
}

// Событие для загрузки списка видов услуг
class LoadActivityTypes extends ActivityTypeEvent {}

// Событие для добавления нового вида услуги
class AddActivityTypeRequested extends ActivityTypeEvent {
  final ActivityType activityType;
  const AddActivityTypeRequested(this.activityType);

  @override
  List<Object> get props => [activityType];
}

// Событие для обновления существующего вида услуги
class UpdateActivityTypeRequested extends ActivityTypeEvent {
  final ActivityType activityType;
  const UpdateActivityTypeRequested(this.activityType);

  @override
  List<Object> get props => [activityType];
}

// Событие для удаления вида услуги
class DeleteActivityTypeRequested extends ActivityTypeEvent {
  final int id;
  const DeleteActivityTypeRequested(this.id);

  @override
  List<Object> get props => [id];
}

// Событие для очистки сообщений (например, после SnackBar)
class ClearActivityTypeMessage extends ActivityTypeEvent {
   const ClearActivityTypeMessage();
   @override
  List<Object> get props => [];
}
