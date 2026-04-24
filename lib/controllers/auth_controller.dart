import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';

// Estado del auth
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

  AuthController(this._authService) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user == null) {
        state = const AuthState();
        return;
      }

      state = state.copyWith(cargando: true, firebaseUser: user, error: null);
      try {
        final perfil = await _authService.obtenerPerfil(user.uid);
        if (perfil != null && perfil.activo) {
          state = AuthState(firebaseUser: user, perfil: perfil);
        } else {
          // Usuario inactivo o sin perfil → cerrar sesión
          await _authService.signOut();
          state = const AuthState(error: 'Usuario no autorizado o inactivo.');
        }
      } catch (e) {
        state = AuthState(error: 'Error al cargar perfil: ${e.toString()}');
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _authService.signIn(email, password);
      // El listener de authStateChanges completará el resto
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        cargando: false,
        error: _mensajeError(e.code),
      );
    } on FirebaseException catch (e) {
      state = AuthState(
        cargando: false,
        error: _mensajeError(e.code ?? 'unknown'),
      );
    } catch (e) {
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
        return 'Usuario no encontrado.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'user-disabled':
        return 'Tu cuenta ha sido desactivada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Error al iniciar sesión. Intenta nuevamente.';
    }
  }
}
