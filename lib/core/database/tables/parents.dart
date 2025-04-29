part of '../app_database.dart';

@DataClassName('ParentEntry')
class Parents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fullName => text().withLength(min: 1, max: 100)();
  // Делаем phoneNumber обязательным
  TextColumn get phoneNumber => text()(); 
  TextColumn get email => text().nullable()();
  // Добавляем address
  TextColumn get address => text().nullable()(); 
}
