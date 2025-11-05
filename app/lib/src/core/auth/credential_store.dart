import 'dart:convert';
import 'dart:io';

import 'package:ble_chat_flutter/src/core/domain/models/local_user.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata describing a previously authenticated local user.
class StoredUserRecord {
  const StoredUserRecord({
    required this.username,
    required this.phoneNumber,
    required this.lastLoginMillis,
  });

  final String username;
  final String phoneNumber;
  final int lastLoginMillis;

  String get _normalizedUsername => username.toLowerCase();

  String get storageKey => base64UrlEncode(utf8.encode(_normalizedUsername));

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'phoneNumber': phoneNumber,
      'lastLoginMillis': lastLoginMillis,
    };
  }

  factory StoredUserRecord.fromJson(Map<String, dynamic> json) {
    return StoredUserRecord(
      username: json['username'] as String,
      phoneNumber: json['phoneNumber'] as String,
      lastLoginMillis: json['lastLoginMillis'] as int,
    );
  }

  bool matchesIdentifier(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return false;
    final normalized = trimmed.toLowerCase();
    return _normalizedUsername == normalized || phoneNumber == trimmed || phoneNumber == normalized;
  }
}

/// Persists previously authenticated users along with encrypted passwords.
class CredentialStore {
  CredentialStore({
    SharedPreferences? preferences,
    Future<Directory> Function()? supportDirectoryProvider,
  })  : _preferencesFuture = preferences != null ? Future<SharedPreferences>.value(preferences) : SharedPreferences.getInstance(),
        _supportDirectoryProvider = supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const _prefsKey = 'auth.recent_users';
  static const _maxEntries = 5;
  static const _credentialSubDir = 'credentials';

  final Future<SharedPreferences> _preferencesFuture;
  final Future<Directory> Function() _supportDirectoryProvider;

  Future<List<StoredUserRecord>> loadRecentUsers() async {
    final prefs = await _preferencesFuture;
    final stored = prefs.getStringList(_prefsKey);
    if (stored == null || stored.isEmpty) {
      return const <StoredUserRecord>[];
    }

    final records = <StoredUserRecord>[];
    for (final item in stored) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        records.add(StoredUserRecord.fromJson(decoded));
      } catch (_) {
        // Skip malformed entries.
      }
    }

    records.sort((a, b) => b.lastLoginMillis.compareTo(a.lastLoginMillis));

    if (records.length > _maxEntries) {
      final trimmed = records.take(_maxEntries).toList();
      await prefs.setStringList(_prefsKey, trimmed.map((record) => jsonEncode(record.toJson())).toList());
      return trimmed;
    }

    return records;
  }

  Future<void> cacheUser({
    required LocalUser user,
    required String password,
  }) async {
    final trimmedPassword = password.trim();
    if (trimmedPassword.isEmpty) return;

    final prefs = await _preferencesFuture;
    final currentRecords = await loadRecentUsers();
    currentRecords.removeWhere((record) => record.username.toLowerCase() == user.username.toLowerCase());

    final now = DateTime.now().millisecondsSinceEpoch;
    currentRecords.insert(
      0,
      StoredUserRecord(
        username: user.username,
        phoneNumber: user.phoneNumber,
        lastLoginMillis: now,
      ),
    );

    if (currentRecords.length > _maxEntries) {
      final overflow = currentRecords.sublist(_maxEntries);
      for (final record in overflow) {
        await _deletePassword(record.username);
      }
      currentRecords.removeRange(_maxEntries, currentRecords.length);
    }

    final encoded = currentRecords.map((record) => jsonEncode(record.toJson())).toList();
    await prefs.setStringList(_prefsKey, encoded);
    await _persistPassword(user.username, trimmedPassword);
  }

  Future<String?> loadPassword(String username) async {
    final file = await _credentialFile(username);
    if (!await file.exists()) {
      return null;
    }

    try {
      final encrypted = await file.readAsString();
      if (encrypted.isEmpty) {
        return null;
      }
      return _CredentialCipher.decrypt(encrypted);
    } catch (_) {
      return null;
    }
  }

  Future<File> _credentialFile(String username) async {
    final key = base64UrlEncode(utf8.encode(username.toLowerCase()));
    final baseDir = await _credentialsDirectory();
    return File('${baseDir.path}/$key.cred');
  }

  Future<Directory> _credentialsDirectory() async {
    final supportDir = await _supportDirectoryProvider();
    final dir = Directory('${supportDir.path}/$_credentialSubDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _persistPassword(String username, String password) async {
    final file = await _credentialFile(username);
    final encrypted = _CredentialCipher.encrypt(password);
    await file.writeAsString(encrypted, flush: true);
  }

  Future<void> _deletePassword(String username) async {
    final file = await _credentialFile(username);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class _CredentialCipher {
  static const _secret = 'ble_chat_flutter::auth_secret_v1';

  static String encrypt(String value) {
    final plainBytes = utf8.encode(value);
    final keyBytes = utf8.encode(_secret);
    final encrypted = List<int>.generate(
      plainBytes.length,
      (index) => plainBytes[index] ^ keyBytes[index % keyBytes.length],
    );
    return base64UrlEncode(encrypted);
  }

  static String decrypt(String value) {
    final encryptedBytes = base64Url.decode(value);
    final keyBytes = utf8.encode(_secret);
    final decrypted = List<int>.generate(
      encryptedBytes.length,
      (index) => encryptedBytes[index] ^ keyBytes[index % keyBytes.length],
    );
    return utf8.decode(decrypted);
  }
}
