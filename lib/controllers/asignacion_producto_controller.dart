import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asignacion_producto_model.dart';
import '../services/asignacion_producto_service.dart';

class AsignacionProductoState {
  final List<AsignacionProductoModel> asignaciones;
  final bool cargando;
  final String? error;
  final String? exito;

  const AsignacionProductoState({
    this.asignaciones = const [],
    this.cargando = false,
    this.error,
    this.exito,
  });

  int get totalAsignados =>
      asignaciones.fold(0, (s, a) => s + a.cantidadAsignada);
  int get totalVendidos =>
      asignaciones.fold(0, (s, a) => s + a.cantidadVendida);

  AsignacionProductoState copyWith({
    List<AsignacionProductoModel>? asignaciones,
    bool? cargando,
    String? error,
    String? exito,
  }) {
    return AsignacionProductoState(
      asignaciones: asignaciones ?? this.asignaciones,
      cargando: cargando ?? this.cargando,
      error: error,
      exito: exito,
    );
  }
}

class AsignacionProductoController
    extends StateNotifier<AsignacionProductoState> {
  final AsignacionProductoService _service;

  AsignacionProductoController(this._service)
    : super(const AsignacionProductoState());

  void escucharAsignaciones(String asesoraUid) {
    _service.streamAsignacionesAsesora(asesoraUid).listen((lista) {
      state = state.copyWith(asignaciones: lista);
    });
  }

  Future<bool> asignarProducto({
    required String asesoraUid,
    required String codigoBarras,
    required String nombreProducto,
    required double precioUnitario,
    required int cantidad,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final asignacion = AsignacionProductoModel(
        id: '',
        asesoraUid: asesoraUid,
        codigoBarras: codigoBarras,
        nombreProducto: nombreProducto,
        precioUnitario: precioUnitario,
        cantidadAsignada: cantidad,
        cantidadVendida: 0,
        activa: true,
        fechaAsignacion: DateTime.now(),
      );
      await _service.asignarProducto(asignacion);
      state = state.copyWith(cargando: false, exito: 'Producto asignado.');
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
