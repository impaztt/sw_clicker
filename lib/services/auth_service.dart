import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStatus {
  final String? userId;
  final String? email;
  final bool isAnonymous;

  const AuthStatus({
    required this.userId,
    required this.email,
    required this.isAnonymous,
  });

  bool get isSignedIn => userId != null;
  bool get isLinkedAccount => isSignedIn && !isAnonymous;

  String get shortUserId {
    final id = userId;
    if (id == null || id.length <= 8) return id ?? '-';
    return '${id.substring(0, 8)}...';
  }

  factory AuthStatus.fromUser(User? user) => AuthStatus(
        userId: user?.id,
        email: user?.email,
        isAnonymous: user?.isAnonymous ?? false,
      );
}

class AuthActionResult {
  final bool ok;
  final String message;

  const AuthActionResult({required this.ok, required this.message});
}

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  AuthStatus get currentStatus => AuthStatus.fromUser(_client.auth.currentUser);

  Stream<AuthStatus> watchStatus() async* {
    yield currentStatus;
    await for (final _ in _client.auth.onAuthStateChange) {
      yield currentStatus;
    }
  }

  Future<AuthActionResult> registerGuestAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final validation = _validateCredentials(normalizedEmail, password);
    if (validation != null) return validation;

    try {
      var user = _client.auth.currentUser;
      if (user == null) {
        final res = await _client.auth.signInAnonymously();
        user = res.user;
      }

      if (user != null && !user.isAnonymous) {
        return const AuthActionResult(
          ok: false,
          message: '이미 계정으로 로그인되어 있어요',
        );
      }

      await _client.auth.updateUser(
        UserAttributes(email: normalizedEmail, password: password),
      );
      return const AuthActionResult(
        ok: true,
        message: '계정 연결을 요청했어요. 확인 메일이 오면 인증해 주세요',
      );
    } on AuthException catch (e) {
      return AuthActionResult(ok: false, message: _authErrorMessage(e));
    } catch (_) {
      return const AuthActionResult(
        ok: false,
        message: '계정 생성 중 오류가 발생했어요',
      );
    }
  }

  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final validation = _validateCredentials(normalizedEmail, password);
    if (validation != null) return validation;

    try {
      await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      return const AuthActionResult(ok: true, message: '로그인됐어요');
    } on AuthException catch (e) {
      return AuthActionResult(ok: false, message: _authErrorMessage(e));
    } catch (_) {
      return const AuthActionResult(
        ok: false,
        message: '로그인 중 오류가 발생했어요',
      );
    }
  }

  Future<AuthActionResult> signOutToGuest() async {
    try {
      await _client.auth.signOut();
      await _client.auth.signInAnonymously();
      return const AuthActionResult(
        ok: true,
        message: '게스트 상태로 전환됐어요',
      );
    } on AuthException catch (e) {
      return AuthActionResult(ok: false, message: _authErrorMessage(e));
    } catch (_) {
      return const AuthActionResult(
        ok: false,
        message: '로그아웃 중 오류가 발생했어요',
      );
    }
  }

  AuthActionResult? _validateCredentials(String email, String password) {
    if (email.isEmpty || !email.contains('@')) {
      return const AuthActionResult(
        ok: false,
        message: '이메일을 정확히 입력해 주세요',
      );
    }
    if (password.length < 6) {
      return const AuthActionResult(
        ok: false,
        message: '비밀번호는 6자 이상이어야 해요',
      );
    }
    return null;
  }

  String _authErrorMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return '이메일 또는 비밀번호가 맞지 않아요';
    }
    if (msg.contains('already') || msg.contains('registered')) {
      return '이미 사용 중인 이메일이에요';
    }
    if (msg.contains('confirm') || msg.contains('verified')) {
      return '이메일 인증 후 다시 로그인해 주세요';
    }
    if (msg.contains('weak')) {
      return '비밀번호가 너무 약해요';
    }
    return e.message;
  }
}
