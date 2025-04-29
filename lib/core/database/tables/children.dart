part of '../app_database.dart';

@DataClassName('ChildEntry')
class Children extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fullName => text().withLength(min: 1, max: 100)();
  DateTimeColumn get dateOfBirth => dateTime()();
  
  // Внешний ключ для связи с таблицей Parents
  IntColumn get parentId => integer().references(Parents, #id, 
      onDelete: KeyAction.cascade)(); // Удалять детей при удалении родителя

  // Добавляем diagnosis
  TextColumn get diagnosis => text().nullable()();
}
