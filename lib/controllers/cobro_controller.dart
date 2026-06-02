// lib/controllers/cobro_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tarjeta_model.dart';
import '../services/cobro_service.dart';

// ─── Estado compartido para cobros, devoluciones y asignaciones ───────────────
class CobroState {
  final List<CuotaModel> cuotas;
  final List<DevolucionModel> devoluciones;
  final List<AsignacionModel> asignaciones;
  final bool cargando;
  final String? error;
  final String? exito;

  const CobroState({
    this.cuotas = const [],
    this.devoluciones = const [],
    this.asignaciones = const [],
    this.cargando = false,
    this.error,
    this.exito,
  });

  // Devoluciones pendientes
  List<DevolucionModel> get devolucionesPendientes => devoluciones
      .where((d) => d.estado == EstadoDevolucion.pendiente)
      .toList();

  // Devoluciones aprobadas
  List<DevolucionModel> get devolucionesAprobadas =>
      devoluciones.where((d) => d.estado == EstadoDevolucion.aprobada).toList();

  CobroState copyWith({
    List<CuotaModel>? cuotas,
    List<DevolucionModel>? devoluciones,
    List<AsignacionModel>? asignaciones,
    bool? cargando,
    String? error,
    String? exito,
  }) {
    return CobroState(
      cuotas: cuotas ?? this.cuotas,
      devoluciones: devoluciones ?? this.devoluciones,
      asignaciones: asignaciones ?? this.asignaciones,
      cargando: cargando ?? this.cargando,
      error: error,
      exito: exito,
    );
  }
}

class CobroController extends StateNotifier<CobroState> {
  final CobroService _service;

  StreamSubscription<List<CuotaModel>>? _cuotasSub;
  StreamSubscription<List<DevolucionModel>>? _devolucionesSub;
  StreamSubscription<List<AsignacionModel>>? _asignacionesSub;

  CobroController(this._service) : super(const CobroState());

  @override
  void dispose() {
    _cuotasSub?.cancel();
    _devolucionesSub?.cancel();
    _asignacionesSub?.cancel();
    super.dispose();
  }

  // ─── CUOTAS ───────────────────────────────────────────────────────────────

  void escucharCuotasDeTarjeta(String tarjetaId) {
    _cuotasSub?.cancel();
    _cuotasSub = _service.streamCuotasDeTarjeta(tarjetaId).listen((lista) {
      state = state.copyWith(cuotas: lista);
    });
  }

  Future<void> cobrarCuota({
    required String cuotaId,
    required String tarjetaId,
    required String cobradorUid,
    required String nombreCobrador,
    required String nombreCliente,
    required double monto,
    required double saldoActual,
    String? observacion,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.cobrarCuota(
        cuotaId: cuotaId,
        tarjetaId: tarjetaId,
        cobradorUid: cobradorUid,
        nombreCobrador: nombreCobrador,
        nombreCliente: nombreCliente,
        monto: monto,
        saldoActual: saldoActual,
        observacion: observacion,
      );
      state = state.copyWith(
        cargando: false,
        exito: 'Cuota cobrada exitosamente.',
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> registrarPago({
    required String tarjetaId,
    required String cobradorUid,
    required String nombreCobrador,
    required String nombreCliente,
    required double monto,
    required double saldoActual,
    String? observacion,
    String? fotoUrl,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.registrarPago(
        tarjetaId: tarjetaId,
        cobradorUid: cobradorUid,
        nombreCobrador: nombreCobrador,
        nombreCliente: nombreCliente,
        monto: monto,
        saldoActual: saldoActual,
        observacion: observacion,
        fotoUrl: fotoUrl,
      );
      state = state.copyWith(cargando: false, exito: 'Pago registrado.');
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  Future<void> cargarCuotasCobrador(String cobradorUid) async {
    state = state.copyWith(cargando: true);
    try {
      final cuotas = await _service.cuotasPendientesCobrador(cobradorUid);
      state = state.copyWith(cuotas: cuotas, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  // ─── DEVOLUCIONES ─────────────────────────────────────────────────────────

  // Admin: escuchar todas las devoluciones (con filtro opcional)
  void escucharDevoluciones({EstadoDevolucion? estado}) {
    _devolucionesSub?.cancel();
    _devolucionesSub =
        _service.streamDevoluciones(estado: estado).listen((lista) {
      state = state.copyWith(devoluciones: lista);
    });
  }

  // Asesora: escuchar sus devoluciones
  void escucharDevolucionesAsesora(String asesoraUid) {
    _devolucionesSub?.cancel();
    _devolucionesSub =
        _service.streamDevolucionesAsesora(asesoraUid).listen((lista) {
      state = state.copyWith(devoluciones: lista);
    });
  }

  // Solicitar devolución (asesora o cobrador; pasa esCobrador: true desde ruta)
  Future<bool> solicitarDevolucion({
    required String tarjetaId,
    required String tarjetaProductoId,
    required String codigoBarras,
    required String asesoraUid,
    required String nombreCliente,
    required String nombreProducto,
    required int cantidadDevuelta,
    required double montoReembolso,
    required String motivo,
    bool esCobrador = false,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final devolucion = DevolucionModel(
        devolucionId: '',
        tarjetaId: tarjetaId,
        tarjetaProductoId: tarjetaProductoId,
        codigoBarras: codigoBarras,
        asesoraUid: asesoraUid,
        nombreCliente: nombreCliente,
        nombreProducto: nombreProducto,
        cantidadDevuelta: cantidadDevuelta,
        montoReembolso: montoReembolso,
        motivo: motivo,
        estado: EstadoDevolucion.pendiente,
        fechaDevolucion: DateTime.now(),
      );
      await _service.solicitarDevolucion(
        devolucion,
        origen: esCobrador ? 'cobrador' : null,
      );
      state = state.copyWith(
        cargando: false,
        exito: esCobrador ? 'Devolución registrada.' : 'Devolución solicitada.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // Admin aprueba o rechaza devolución
  Future<bool> resolverDevolucion({
    required String devolucionId,
    required String tarjetaId,
    required String asesoraUid,
    required String adminUid,
    required bool aprobada,
    required double montoReembolso,
    required int cantidadDevuelta,
    required String codigoBarrasProducto,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.resolverDevolucion(
        devolucionId: devolucionId,
        tarjetaId: tarjetaId,
        asesoraUid: asesoraUid,
        adminUid: adminUid,
        nuevoEstado: aprobada
            ? EstadoDevolucion.aprobada
            : EstadoDevolucion.rechazada,
        montoReembolso: montoReembolso,
        cantidadDevuelta: cantidadDevuelta,
        codigoBarrasProducto: codigoBarrasProducto,
      );
      state = state.copyWith(
        cargando: false,
        exito: aprobada ? 'Devolución aprobada.' : 'Devolución rechazada.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // ─── ASIGNACIONES ─────────────────────────────────────────────────────────

  // Admin: escuchar todas las asignaciones
  void escucharAsignaciones() {
    _asignacionesSub?.cancel();
    _asignacionesSub = _service.streamTodasAsignaciones().listen((lista) {
      state = state.copyWith(asignaciones: lista);
    });
  }

  // Cobrador: escuchar sus asignaciones activas
  void escucharAsignacionesCobrador(String cobradorUid) {
    _asignacionesSub?.cancel();
    _asignacionesSub =
        _service.streamAsignacionesCobrador(cobradorUid).listen((lista) {
      state = state.copyWith(asignaciones: lista);
    });
  }

  // Admin: asignar todas las tarjetas de una zona a un cobrador
  Future<bool> asignarZona({
    required String cobradorUid,
    required String nombreCobrador,
    required List<TarjetaModel> tarjetas,
    required Set<String> yaAsignadasIds,
    required String adminUid,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final nuevas = tarjetas
          .where((t) => !yaAsignadasIds.contains(t.tarjetaId))
          .map(
            (t) => AsignacionModel(
              asignacionId: '',
              cobradorUid: cobradorUid,
              nombreCobrador: nombreCobrador,
              tarjetaId: t.tarjetaId,
              nombreCliente: t.nombreCliente,
              adminUid: adminUid,
              fechaAsignacion: DateTime.now(),
              activa: true,
            ),
          )
          .toList();
      await _service.asignarPorZona(
        cobradorUid: cobradorUid,
        nombreCobrador: nombreCobrador,
        asignaciones: nuevas,
      );
      state = state.copyWith(
        cargando: false,
        exito: '${nuevas.length} tarjetas asignadas.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // Admin: asignar tarjeta a cobrador
  Future<bool> asignarTarjeta({
    required String cobradorUid,
    required String nombreCobrador,
    required String tarjetaId,
    required String nombreCliente,
    required String adminUid,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final asignacion = AsignacionModel(
        asignacionId: '',
        cobradorUid: cobradorUid,
        nombreCobrador: nombreCobrador,
        tarjetaId: tarjetaId,
        nombreCliente: nombreCliente,
        adminUid: adminUid,
        fechaAsignacion: DateTime.now(),
        activa: true,
      );
      await _service.asignar(asignacion);
      state = state.copyWith(
        cargando: false,
        exito: 'Tarjeta asignada al cobrador.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // Desactivar asignación individual
  Future<void> desactivarAsignacion(String asignacionId) async {
    try {
      await _service.desactivarAsignacion(asignacionId);
      state = state.copyWith(exito: 'Asignación eliminada.');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Desactivar múltiples asignaciones en un solo batch (quitar zona)
  Future<bool> desactivarAsignacionesBatch(List<String> ids) async {
    if (ids.isEmpty) return true;
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.desactivarAsignacionesBatch(ids);
      state = state.copyWith(cargando: false, exito: 'Asignaciones quitadas.');
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  void limpiarMensajes() {
    state = state.copyWith(error: null, exito: null);
  }
}
