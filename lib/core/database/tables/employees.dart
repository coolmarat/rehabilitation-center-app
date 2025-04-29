part of '../app_database.dart'; // Связываем с основным файлом БД

@DataClassName('EmployeeEntry') // Используем суффикс Entry для классов данных drift
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fullName => text().withLength(min: 1, max: 100)();
  TextColumn get position => text().withLength(min: 1, max: 50)();
}
