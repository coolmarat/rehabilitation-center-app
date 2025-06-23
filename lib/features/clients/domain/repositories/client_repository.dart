import 'package:rehabilitation_center_app/features/clients/domain/parent.dart';
import 'package:rehabilitation_center_app/features/clients/domain/child.dart';

// Абстрактный репозиторий для клиентов
abstract class ClientRepository {
  Future<List<Parent>> getParents();
  Future<Parent> getParentById(int id);
  Future<List<Child>> getChildrenForParent(int parentId);
  Future<Parent> addParent(Parent parent);
  Future<void> updateParent(Parent parent);
  Future<void> deleteParent(int id);
  Future<Child> addChild(Child child);
  Future<void> updateChild(Child child);
  Future<void> deleteChild(int id);
  Future<void> updateParentBalance(int parentId, double amount);
  Future<int> getParentIdByChildId(int childId);

  // Пример комбинированного метода:
  Future<Map<Parent, List<Child>>> getAllParentsWithChildren(); 
}
