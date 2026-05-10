import 'package:drift/drift.dart';
import 'connection/connection.dart';

part 'app_database.g.dart';

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get name => text().nullable()();
  TextColumn get profileImage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0: synced, 1: pending_insert, 2: pending_update, 3: pending_delete
}

@DataClassName('Income')
class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
}

@DataClassName('Budget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get category => text()();
  RealColumn get monthlyLimit => real()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
}

@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
}

@DataClassName('Contribution')
class Contributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get title => text()();
  RealColumn get percentage => real()();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get lastCalculationDate => dateTime().nullable()();
}

@DataClassName('Notification')
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get type => text()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Expenses, Incomes, Budgets, Goals, Users, Contributions, Notifications])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(users);
            await m.createTable(contributions);
            await m.createTable(notifications);

            await m.addColumn(expenses, expenses.userId);
            await m.addColumn(expenses, expenses.tags);
            await m.addColumn(incomes, incomes.userId);
            await m.addColumn(incomes, incomes.tags);
            await m.addColumn(budgets, budgets.userId);
            await m.addColumn(goals, goals.userId);
            await m.addColumn(goals, goals.currentAmount);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
