import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/add_activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/delete_activity_type.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/get_activity_types.dart';
import 'package:rehabilitation_center_app/features/activity_types/domain/usecases/update_activity_type.dart';

part 'activity_type_event.dart';
part 'activity_type_state.dart';

class ActivityTypeBloc extends Bloc<ActivityTypeEvent, ActivityTypeState> {
  final GetActivityTypes _getActivityTypes;
  final AddActivityType _addActivityType;
  final UpdateActivityType _updateActivityType;
  final DeleteActivityType _deleteActivityType;

  ActivityTypeBloc({
    required GetActivityTypes getActivityTypes,
    required AddActivityType addActivityType,
    required UpdateActivityType updateActivityType,
    required DeleteActivityType deleteActivityType,
  })  : _getActivityTypes = getActivityTypes,
        _addActivityType = addActivityType,
        _updateActivityType = updateActivityType,
        _deleteActivityType = deleteActivityType,
        super(const ActivityTypeState()) {
    on<LoadActivityTypes>(_onLoadActivityTypes);
    on<AddActivityTypeRequested>(_onAddActivityTypeRequested);
    on<UpdateActivityTypeRequested>(_onUpdateActivityTypeRequested);
    on<DeleteActivityTypeRequested>(_onDeleteActivityTypeRequested);
    on<ClearActivityTypeMessage>(_onClearActivityTypeMessage);

    // Загружаем данные при инициализации
    add(LoadActivityTypes());
  }

  Future<void> _loadData(Emitter<ActivityTypeState> emit, {String? successMessage}) async {
    try {
      final activityTypes = await _getActivityTypes();
      emit(state.copyWith(
        status: ActivityTypeStatus.success,
        activityTypes: activityTypes,
        message: successMessage,
        clearMessage: successMessage == null,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivityTypeStatus.failure,
        errorMessage: e.toString(),
        message: 'Ошибка загрузки видов услуг',
      ));
    }
  }

  Future<void> _onLoadActivityTypes(
    LoadActivityTypes event,
    Emitter<ActivityTypeState> emit,
  ) async {
    emit(state.copyWith(status: ActivityTypeStatus.loading, clearMessage: true, clearErrorMessage: true));
    await _loadData(emit);
  }

  Future<void> _onAddActivityTypeRequested(
    AddActivityTypeRequested event,
    Emitter<ActivityTypeState> emit,
  ) async {
    emit(state.copyWith(status: ActivityTypeStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _addActivityType(event.activityType);
      await _loadData(emit, successMessage: 'Вид услуги "${event.activityType.name}" добавлен.');
    } catch (e) {
      emit(state.copyWith(
        status: ActivityTypeStatus.failure,
        errorMessage: e.toString(),
        message: 'Ошибка добавления вида услуги',
      ));
    }
  }

  Future<void> _onUpdateActivityTypeRequested(
    UpdateActivityTypeRequested event,
    Emitter<ActivityTypeState> emit,
  ) async {
    emit(state.copyWith(status: ActivityTypeStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _updateActivityType(event.activityType);
      await _loadData(emit, successMessage: 'Вид услуги "${event.activityType.name}" обновлен.');
    } catch (e) {
      emit(state.copyWith(
        status: ActivityTypeStatus.failure,
        errorMessage: e.toString(),
        message: 'Ошибка обновления вида услуги',
      ));
    }
  }

  Future<void> _onDeleteActivityTypeRequested(
    DeleteActivityTypeRequested event,
    Emitter<ActivityTypeState> emit,
  ) async {
    emit(state.copyWith(status: ActivityTypeStatus.loading, clearMessage: true, clearErrorMessage: true));
    try {
      await _deleteActivityType(event.id);
      await _loadData(emit, successMessage: 'Вид услуги удален.');
    } catch (e) {
      emit(state.copyWith(
        status: ActivityTypeStatus.failure,
        errorMessage: e.toString(),
        message: 'Ошибка удаления вида услуги',
      ));
    }
  }

   void _onClearActivityTypeMessage(
    ClearActivityTypeMessage event,
    Emitter<ActivityTypeState> emit,
  ) {
     emit(state.copyWith(clearMessage: true));
   }
}
