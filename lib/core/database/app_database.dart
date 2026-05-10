import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0: synced, 1: pending_insert, 2: pending_update, 3: pending_delete

}

@DataClassName('Income')
class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

}

@DataClassName('Budget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  TextColumn get category => text()();
  RealColumn get monthlyLimit => real()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

}

@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  DateTimeColumn get deadline => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

}

@DriftDatabase(tables: [Expenses, Incomes, Budgets, Goals])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Enable foreign keys if needed
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
