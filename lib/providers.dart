import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/auth_service.dart';
import 'services/usuario_service.dart';
import 'services/producto_service.dart';
import 'services/tarjeta_service.dart';
import 'services/cobro_service.dart';
import 'services/storage_service.dart';
import 'services/dashboard_service.dart';
import 'services/asignacion_producto_service.dart';

import 'controllers/auth_controller.dart';
import 'controllers/usuario_controller.dart';
import 'controllers/producto_controller.dart';
import 'controllers/tarjeta_controller.dart';
import 'controllers/cobro_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/asignacion_producto_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SERVICES (singleton, sin estado)
// ══════════════════════════════════════════════════════════════════════════════

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final usuarioServiceProvider = Provider<UsuarioService>(
  (ref) => UsuarioService(),
);

final productoServiceProvider = Provider<ProductoService>(
  (ref) => ProductoService(),
);

final tarjetaServiceProvider = Provider<TarjetaService>(
  (ref) => TarjetaService(),
);

final cobroServiceProvider = Provider<CobroService>((ref) => CobroService());

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final gpsServiceProvider = Provider<GpsService>((ref) => GpsService());

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(),
);

// ══════════════════════════════════════════════════════════════════════════════
// CONTROLLERS (con estado)
// ══════════════════════════════════════════════════════════════════════════════

/// Auth — disponible en toda la app, persiste mientras la app vive
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authServiceProvider));
  },
);

/// Usuario actual (shortcut conveniente)
final usuarioActualProvider = Provider((ref) {
  return ref.watch(authControllerProvider).perfil;
});

/// Rol del usuario actual
final rolActualProvider = Provider((ref) {
  return ref.watch(authControllerProvider).rol;
});

/// Usuarios (asesoras, cobradores) — admin
final usuarioControllerProvider =
    StateNotifierProvider<UsuarioController, UsuarioState>((ref) {
      return UsuarioController(
        ref.watch(usuarioServiceProvider),
        ref.watch(authServiceProvider),
      );
    });

/// Productos / Inventario
final productoControllerProvider =
    StateNotifierProvider<ProductoController, ProductoState>((ref) {
      return ProductoController(ref.watch(productoServiceProvider));
    });

/// Tarjetas (ventas) — se auto-carga según el rol en los widgets
final tarjetaControllerProvider =
    StateNotifierProvider<TarjetaController, TarjetaState>((ref) {
      return TarjetaController(
        ref.watch(tarjetaServiceProvider),
        ref.watch(storageServiceProvider),
        ref.watch(gpsServiceProvider),
      );
    });

/// Cobros, devoluciones y asignaciones
final cobroControllerProvider =
    StateNotifierProvider<CobroController, CobroState>((ref) {
      return CobroController(ref.watch(cobroServiceProvider));
    });

/// Dashboard — stats en tiempo real
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
      return DashboardController(ref.watch(dashboardServiceProvider));
    });

/// Reportes — datos para reportes con rango de fechas
final reporteControllerProvider =
    StateNotifierProvider<ReporteController, ReporteState>((ref) {
      return ReporteController(ref.watch(dashboardServiceProvider));
    });

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDERS DERIVADOS (computed)
// ══════════════════════════════════════════════════════════════════════════════

/// Lista de asesoras activas (shortcut)
final asesorasProvider = Provider((ref) {
  return ref.watch(usuarioControllerProvider).asesoras;
});

/// Lista de cobradores activos (shortcut)
final cobradoresProvider = Provider((ref) {
  return ref.watch(usuarioControllerProvider).cobradores;
});

/// Productos activos en inventario (shortcut)
final productosProvider = Provider((ref) {
  return ref.watch(productoControllerProvider).productos;
});

/// Tarjetas en pantalla (shortcut)
final tarjetasProvider = Provider((ref) {
  return ref.watch(tarjetaControllerProvider).tarjetas;
});

/// Carrito de venta activo
final carritoProvider = Provider((ref) {
  return ref.watch(tarjetaControllerProvider).carrito;
});

/// Total del carrito
final totalCarritoProvider = Provider<double>((ref) {
  return ref.watch(tarjetaControllerProvider).totalCarrito;
});

/// Devoluciones pendientes (admin)
final devolucionesPendientesProvider = Provider((ref) {
  return ref.watch(cobroControllerProvider).devolucionesPendientes;
});

/// Asignaciones activas del cobrador actual
final asignacionesCobradorProvider = Provider((ref) {
  return ref.watch(cobroControllerProvider).asignaciones;
});

// ══════════════════════════════════════════════════════════════════════════════
// ASIGNACIONES DE PRODUCTOS A ASESORAS
// ══════════════════════════════════════════════════════════════════════════════

final asignacionProductoServiceProvider = Provider<AsignacionProductoService>(
  (ref) => AsignacionProductoService(),
);

final asignacionProductoControllerProvider = StateNotifierProvider<
  AsignacionProductoController,
  AsignacionProductoState
>((ref) {
  return AsignacionProductoController(
    ref.watch(asignacionProductoServiceProvider),
  );
});

/// Productos asignados a la asesora actual (shortcut)
final productosAsignadosProvider = Provider((ref) {
  return ref.watch(asignacionProductoControllerProvider).asignaciones;
});
