import 'dart:async';

import 'package:ble_chat_flutter/src/core/auth/credential_store.dart';
import 'package:ble_chat_flutter/src/core/auth/local_auth_service.dart';
import 'package:ble_chat_flutter/src/core/domain/models/local_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unauthenticated, loading, authenticated, failure }
enum AuthError { agreementRequired, invalidCredentials }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final LocalUser? user;
  final AuthError? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    LocalUser? user,
    AuthError? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  static const AuthState unauthenticated = AuthState(status: AuthStatus.unauthenticated);
}

class AuthController extends ChangeNotifier {
  AuthController(
    this._authService, {
    CredentialStore? credentialStore,
  }) : _credentialStore = credentialStore ?? CredentialStore() {
    unawaited(_refreshRecentUsers());
  }

  final LocalAuthService _authService;
  final CredentialStore _credentialStore;
  AuthState _state = AuthState.unauthenticated;
  List<StoredUserRecord> _recentUsers = const <StoredUserRecord>[];
  bool _disposed = false;

  AuthState get state => _state;
  List<StoredUserRecord> get recentUsers => List.unmodifiable(_recentUsers);

  Future<void> login({
    required String identifier,
    required String password,
    required bool acceptedAgreement,
  }) async {
    if (!acceptedAgreement) {
      _state = AuthState(status: AuthStatus.failure, error: AuthError.agreementRequired);
      _safeNotify();
      return;
    }

    _state = _state.copyWith(status: AuthStatus.loading, error: null);
    _safeNotify();

    await Future<void>.delayed(const Duration(milliseconds: 300));
    final user = _authService.authenticate(identifier: identifier, password: password);
    if (user == null) {
      _state = AuthState(status: AuthStatus.failure, error: AuthError.invalidCredentials);
      _safeNotify();
      return;
    }

    await _cacheCredential(user, password);

    _state = AuthState(status: AuthStatus.authenticated, user: user);
    _safeNotify();
  }

  void logout() {
    _state = AuthState.unauthenticated;
    _safeNotify();
  }

  Future<String?> loadPasswordForIdentifier(String identifier) async {
    final record = _findRecord(identifier);
    if (record != null) {
      return _credentialStore.loadPassword(record.username);
    }
    await _refreshRecentUsers(shouldNotify: false);
    final refreshed = _findRecord(identifier);
    if (refreshed == null) return null;
    return _credentialStore.loadPassword(refreshed.username);
  }

  Future<void> _cacheCredential(LocalUser user, String password) async {
    try {
      await _credentialStore.cacheUser(user: user, password: password);
      await _refreshRecentUsers(shouldNotify: false);
    } catch (_) {
      // Ignore persistence failures - authentication should still succeed.
    }
  }

  Future<void> _refreshRecentUsers({bool shouldNotify = true}) async {
    final users = await _credentialStore.loadRecentUsers();
    _recentUsers = users;
    if (shouldNotify) {
      _safeNotify();
    }
  }

  StoredUserRecord? _findRecord(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return null;
    for (final record in _recentUsers) {
      if (record.matchesIdentifier(trimmed)) {
        return record;
      }
    }
    return null;
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>(
  (ref) => AuthController(
    LocalAuthService(),
    credentialStore: CredentialStore(),
  ),
);
