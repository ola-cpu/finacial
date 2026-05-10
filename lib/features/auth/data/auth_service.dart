import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../babylon/data/vault_service.dart';

class AuthService {
  final AppDatabase database;
  final VaultService? vaultService;

  AuthService(this.database, [this.vaultService]);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final companion = UsersCompanion.insert(
      email: email,
      password: _hashPassword(password),
      name: Value(name),
      createdAt: DateTime.now(),
    );

    final id = await database.into(database.users).insert(companion);

    if (vaultService != null) {
      await vaultService!.createDefaultVaults(id);
    }

    return (database.select(database.users)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<User?> login(String email, String password) async {
    final hashedPassword = _hashPassword(password);
    return (database.select(database.users)
          ..where((t) => t.email.equals(email) & t.password.equals(hashedPassword)))
        .getSingleOrNull();
  }

  Future<void> updateProfile({
    required int id,
    String? name,
    String? profileImage,
  }) async {
    await (database.update(database.users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        profileImage: profileImage != null ? Value(profileImage) : const Value.absent(),
      ),
    );
  }

  Future<void> resetPassword(int id, String newPassword) async {
    await (database.update(database.users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(password: Value(_hashPassword(newPassword))),
    );
  }
}

final authServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  final vaultService = ref.watch(vaultServiceProvider);
  return AuthService(database, vaultService);
});

final currentUserProvider = StateProvider<User?>((ref) => null);
