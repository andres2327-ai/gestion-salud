import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final User? firebaseUser;
  final UsuarioModel? perfil;
  final bool cargando;
  final String? error;

  const AuthState({
    this.firebaseUser,
    this.perfil,
    this.cargando = false,
    this.error,
  });

  bool get autenticado => firebaseUser != null && perfil != null;
  RolUsuario? get rol => perfil?.rol;

  AuthState copyWith({
    User? firebaseUser,
    UsuarioModel? perfil,
    bool? cargando,
    String? error,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      perfil: perfil ?? this.perfil,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  // Prevents the null authStateChanges event (from signOut during sign-in)
  // from resetting the loading state mid-flow.
  bool _signingIn = false;

  AuthController(this._authService) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user == null) {
        if (!_signingIn) state = const AuthState();
        return;
      }

      _signingIn = false;
      state = state.copyWith(cargando: true, firebaseUser: user, error: null);
      try {
        final perfil = await _authService.obtenerPerfil(user.uid);
        if (perfil != null && perfil.activo) {
          state = AuthState(firebaseUser: user, perfil: perfil);
        } else {
          state = const AuthState(error: 'Usuario no autorizado o inactivo.');
          await _authService.signOut();
        }
      } catch (e) {
        state = const AuthState(error: 'Error al cargar perfil. Intenta de nuevo.');
        await _authService.signOut();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    _signingIn = true;
    state = state.copyWith(cargando: true, error: null);
    try {
      // Si ya hay una sesión abierta (de un intento fallido), la cerramos
      // para garantizar que authStateChanges dispare con el nuevo usuario.
      if (_authService.currentUser != null) {
        await _authService.signOut();
      }
      await _authService.signIn(email, password);
      // El listener de authStateChanges completará el resto
    } on FirebaseAuthException catch (e) {
      _signingIn = false;
      state = AuthState(cargando: false, error: _mensajeError(e.code));
    } on FirebaseException catch (e) {
      _signingIn = false;
      state = AuthState(cargando: false, error: _mensajeError(e.code));
    } catch (e) {
      _signingIn = false;
      state = AuthState(
        cargando: false,
        error: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  void actualizarMetaMensual(double nuevaMeta) {
    if (state.perfil != null) {
      state = state.copyWith(perfil: state.perfil!.copyWith(metaMensual: nuevaMeta));
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _mensajeError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'user-disabled':
        return 'Tu cuenta ha sido desactivada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      case 'operation-not-allowed':
        return 'Inicio de sesión no habilitado. Contacta al administrador.';
      default:
        return 'Error al iniciar sesión ($code). Intenta de nuevo.';
    }
  }
}
