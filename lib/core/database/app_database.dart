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

  // Babylon features
  RealColumn get financialScore => real().withDefault(const Constant(0))();
  TextColumn get level => text().withDefault(const Constant('Débutant'))();
  IntColumn get points => integer().withDefault(const Constant(0))();
  RealColumn get savingPercentage => real().withDefault(const Constant(10))();
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
  RealColumn get targetAmount => real().withDefault(const Constant(1000000))();
  DateTimeColumn get lastCalculationDate => dateTime().nullable()();
  TextColumn get type => text().nullable()(); // savings, investment, emergency, project, business, formation
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

@DataClassName('Challenge')
class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get type => text()(); // saving, expense_reduction, etc.
  RealColumn get targetValue => real()();
  IntColumn get durationDays => integer()();
  IntColumn get rewardPoints => integer()();
}

@DataClassName('UserChallenge')
class UserChallenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get challengeId => integer().references(Challenges, #id)();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
}

@DriftDatabase(tables: [Expenses, Incomes, Budgets, Goals, Users, Contributions, Notifications, Challenges, UserChallenges])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(DatabaseConnection connection) : super(connection);

  @override
  int get schemaVersion => 3;

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
          if (from < 3) {
            await m.addColumn(users, users.financialScore);
            await m.addColumn(users, users.level);
            await m.addColumn(users, users.points);
            await m.addColumn(users, users.savingPercentage);

            await m.addColumn(incomes, incomes.userId);
            await m.addColumn(contributions, contributions.type);
            await m.addColumn(contributions, contributions.targetAmount);

            await m.createTable(challenges);
            await m.createTable(userChallenges);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
