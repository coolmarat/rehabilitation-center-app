part of 'activity_type_bloc.dart';

enum ActivityTypeStatus { initial, loading, success, failure }

class ActivityTypeState extends Equatable {
  final ActivityTypeStatus status;
  final List<ActivityType> activityTypes;
  final String? errorMessage;
  final String? message; // Для сообщений об успехе/ошибке

  const ActivityTypeState({
    this.status = ActivityTypeStatus.initial,
    this.activityTypes = const [],
    this.errorMessage,
    this.message,
  });

  ActivityTypeState copyWith({
    ActivityTypeStatus? status,
    List<ActivityType>? activityTypes,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? message,
    bool clearMessage = false,
  }) {
    return ActivityTypeState(
      status: status ?? this.status,
      activityTypes: activityTypes ?? this.activityTypes,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, activityTypes, errorMessage, message];
}
