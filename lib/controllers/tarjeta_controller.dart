// lib/controllers/tarjeta_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tarjeta_model.dart';
import '../models/producto_model.dart';
import '../models/asignacion_producto_model.dart';
import '../services/tarjeta_service.dart';
import '../services/storage_service.dart';

// ─── Ítem del carrito al crear una venta ─────────────────────────────────────
class ItemCarrito {
  final ProductoModel producto;
  int cantidad;
  // pendiente = true: manually added, not from assigned stock
  final bool pendiente;

  ItemCarrito({required this.producto, required this.cantidad, this.pendiente = false});

  double get subtotal => producto.precioUnitario * cantidad;
}

// ─── Estado ───────────────────────────────────────────────────────────────────
class TarjetaState {
  final List<TarjetaModel> tarjetas;
  final List<TarjetaModel> tarjetasCobrador;
  final List<ItemCarrito> carrito;
  final bool cargando;
  final String? error;
  final String? exito;

  const TarjetaState({
    this.tarjetas = const [],
    this.tarjetasCobrador = const [],
    this.carrito = const [],
    this.cargando = false,
    this.error,
    this.exito,
  });

  double get totalCarrito =>
      carrito.fold(0, (sum, item) => sum + item.subtotal);

  int get itemsEnCarrito => carrito.length;

  TarjetaState copyWith({
    List<TarjetaModel>? tarjetas,
    List<TarjetaModel>? tarjetasCobrador,
    List<ItemCarrito>? carrito,
    bool? cargando,
    String? error,
    String? exito,
  }) {
    return TarjetaState(
      tarjetas: tarjetas ?? this.tarjetas,
      tarjetasCobrador: tarjetasCobrador ?? this.tarjetasCobrador,
      carrito: carrito ?? this.carrito,
      cargando: cargando ?? this.cargando,
      error: error,
      exito: exito,
    );
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────
class TarjetaController extends StateNotifier<TarjetaState> {
  final TarjetaService _tarjetaService;
  final StorageService _storageService;
  final GpsService _gpsService;

  StreamSubscription<List<TarjetaModel>>? _asesorasSub;
  StreamSubscription<List<TarjetaModel>>? _cobradorSub;
  StreamSubscription<List<TarjetaModel>>? _todasSub;

  TarjetaController(
    this._tarjetaService,
    this._storageService,
    this._gpsService,
  ) : super(const TarjetaState());

  // Cargar tarjetas de una asesora
  void cargarTarjetasAsesora(String asesoraUid) {
    _asesorasSub?.cancel();
    _asesorasSub =
        _tarjetaService.streamTarjetasAsesora(asesoraUid).listen((lista) {
      state = state.copyWith(tarjetas: lista);
    });
  }

  // Cargar tarjetas asignadas al cobrador (por lista de IDs)
  void cargarTarjetasCobrador(List<String> tarjetaIds) {
    _cobradorSub?.cancel();
    if (tarjetaIds.isEmpty) {
      state = state.copyWith(tarjetasCobrador: []);
      return;
    }
    _cobradorSub =
        _tarjetaService.streamTarjetasPorIds(tarjetaIds).listen((lista) {
      state = state.copyWith(tarjetasCobrador: lista);
    });
  }

  // Cargar todas (admin)
  void cargarTodas() {
    _todasSub?.cancel();
    _todasSub = _tarjetaService.streamTodasLasTarjetas().listen((lista) {
      state = state.copyWith(tarjetas: lista);
    });
  }

  @override
  void dispose() {
    _asesorasSub?.cancel();
    _cobradorSub?.cancel();
    _todasSub?.cancel();
    super.dispose();
  }

  // ─── Carrito ──────────────────────────────────────────────────────────────

  // Agrega un producto al carrito desde una asignación de asesora
  void agregarProductoDesdeAsignacion(
    AsignacionProductoModel asignacion,
    int cantidad,
  ) {
    final producto = ProductoModel(
      codigoBarras: asignacion.codigoBarras,
      nombre: asignacion.nombreProducto,
      tipo: TipoProducto.pastillas,
      precioUnitario: asignacion.precioUnitario,
      cantidadStock: asignacion.cantidadDisponible,
      fechaVencimiento: DateTime(2099),
      activo: true,
    );
    agregarAlCarrito(producto, cantidad);
  }

  void agregarAlCarrito(ProductoModel producto, int cantidad, {bool pendiente = false}) {
    final carritoActual = List<ItemCarrito>.from(state.carrito);
    final idx = carritoActual.indexWhere(
      (i) => i.producto.codigoBarras == producto.codigoBarras,
    );

    if (idx >= 0) {
      carritoActual[idx] = ItemCarrito(
        producto: producto,
        cantidad: carritoActual[idx].cantidad + cantidad,
        pendiente: carritoActual[idx].pendiente,
      );
    } else {
      carritoActual.add(ItemCarrito(producto: producto, cantidad: cantidad, pendiente: pendiente));
    }
    state = state.copyWith(carrito: carritoActual);
  }

  // Agrega un producto pendiente (no asignado) al carrito
  void agregarProductoPendiente({
    required String nombre,
    required double precioUnitario,
    required int cantidad,
  }) {
    final producto = ProductoModel(
      codigoBarras: 'PENDIENTE_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      tipo: TipoProducto.pastillas,
      precioUnitario: precioUnitario,
      cantidadStock: 9999,
      fechaVencimiento: DateTime(2099),
      activo: true,
    );
    agregarAlCarrito(producto, cantidad, pendiente: true);
  }

  void quitarDelCarrito(String codigoBarras) {
    state = state.copyWith(
      carrito: state.carrito
          .where((i) => i.producto.codigoBarras != codigoBarras)
          .toList(),
    );
  }

  void actualizarCantidad(String codigoBarras, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      quitarDelCarrito(codigoBarras);
      return;
    }
    final carritoActual = List<ItemCarrito>.from(state.carrito);
    final idx = carritoActual.indexWhere(
      (i) => i.producto.codigoBarras == codigoBarras,
    );
    if (idx >= 0) {
      carritoActual[idx] = ItemCarrito(
        producto: carritoActual[idx].producto,
        cantidad: nuevaCantidad,
      );
      state = state.copyWith(carrito: carritoActual);
    }
  }

  void limpiarCarrito() {
    state = state.copyWith(carrito: []);
  }

  // ─── Crear venta ──────────────────────────────────────────────────────────

  Future<String?> crearVenta({
    required String asesoraUid,
    required String nombreAsesora,
    required String nombreCliente,
    required String telefonoCliente,
    required String direccionCliente,
    required TipoPago tipoPago,
    required FrecuenciaPago frecuenciaPago,
    required int numCuotas,
    required String zona,
    double pagoInicial = 0,
    String? descripcion,
    XFile? foto,
  }) async {
    if (state.carrito.isEmpty) {
      state = state.copyWith(error: 'Agrega al menos un producto.');
      return null;
    }

    state = state.copyWith(cargando: true, error: null);

    try {
      // Obtener GPS
      final posicion = await _gpsService.obtenerUbicacion();
      final lat = posicion?.latitude ?? 0;
      final lng = posicion?.longitude ?? 0;

      final totalVenta = state.totalCarrito;
      final saldoAFinanciar = totalVenta - pagoInicial;
      final montoCuota = tipoPago == TipoPago.cuotas && numCuotas > 0
          ? saldoAFinanciar / numCuotas
          : saldoAFinanciar;

      // Construir tarjeta
      final tarjeta = TarjetaModel(
        tarjetaId: '',
        asesoraUid: asesoraUid,
        nombreAsesora: nombreAsesora,
        nombreCliente: nombreCliente,
        telefonoCliente: telefonoCliente,
        direccionCliente: direccionCliente,
        latitud: lat,
        longitud: lng,
        tipoPago: tipoPago,
        frecuenciaPago: frecuenciaPago,
        numCuotas: tipoPago == TipoPago.contado ? 1 : numCuotas,
        montoCuota: montoCuota,
        totalVenta: totalVenta,
        pagoInicial: pagoInicial,
        totalDevuelto: 0,
        saldoPendiente: saldoAFinanciar,
        estado: EstadoTarjeta.activa,
        fechaVenta: DateTime.now(),
        zona: zona,
        descripcion: descripcion,
      );

      // Construir items de tarjeta
      final productos = state.carrito.map((item) {
        return TarjetaProductoModel(
          id: '',
          tarjetaId: '',
          codigoBarras: item.producto.codigoBarras,
          nombreProducto: item.producto.nombre,
          cantidad: item.cantidad,
          precioVenta: item.producto.precioUnitario,
          subtotal: item.subtotal,
          pendiente: item.pendiente,
        );
      }).toList();

      // Construir cuotas (basadas en saldo a financiar, no en total bruto)
      final cuotas = _generarCuotas(
        numCuotas: tipoPago == TipoPago.contado ? 1 : numCuotas,
        montoCuota: montoCuota,
        frecuenciaPago: frecuenciaPago,
      );

      // Guardar en Firestore (funciona offline gracias a persistencia local)
      final tarjetaId = await _tarjetaService.crearTarjeta(
        tarjeta: tarjeta,
        productos: productos,
        cuotas: cuotas,
      );

      // Subir foto — no falla la venta si no hay internet;
      // Storage no tiene cache offline, la foto se sube cuando haya conexión.
      if (foto != null) {
        try {
          final fotoUrl = await _storageService
              .subirFotoTarjeta(foto: foto, tarjetaId: tarjetaId)
              .timeout(const Duration(seconds: 30));
          await _tarjetaService.actualizarFoto(tarjetaId, fotoUrl);
        } catch (_) {
          // La venta quedó guardada; la foto se podrá adjuntar después.
        }
      }

      limpiarCarrito();
      state = state.copyWith(
        cargando: false,
        exito: 'Venta registrada exitosamente.',
      );
      return tarjetaId;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return null;
    }
  }

  List<CuotaModel> _generarCuotas({
    required int numCuotas,
    required double montoCuota,
    FrecuenciaPago frecuenciaPago = FrecuenciaPago.semanal,
  }) {
    final diasIntervalo = frecuenciaPago == FrecuenciaPago.diaria ? 1 : 7;
    return List.generate(numCuotas, (i) {
      return CuotaModel(
        cuotaId: '',
        tarjetaId: '',
        numeroCuota: i + 1,
        monto: montoCuota,
        estado: EstadoCuota.pendiente,
        fechaVencimiento: DateTime.now().add(
          Duration(days: diasIntervalo * (i + 1)),
        ),
      );
    });
  }

  // Actualizar tarjeta (admin)
  Future<bool> actualizarTarjeta(
    String tarjetaId,
    Map<String, dynamic> datos,
  ) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _tarjetaService.actualizarTarjeta(tarjetaId, datos);
      state = state.copyWith(cargando: false, exito: 'Venta actualizada.');
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // Eliminar tarjeta (admin)
  Future<bool> eliminarTarjeta(String tarjetaId) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _tarjetaService.eliminarTarjeta(tarjetaId);
      state = state.copyWith(cargando: false, exito: 'Venta eliminada.');
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // Obtener productos de una tarjeta
  Future<List<TarjetaProductoModel>> obtenerProductosDeTarjeta(
    String tarjetaId,
  ) async {
    return await _tarjetaService.obtenerProductosDeTarjeta(tarjetaId);
  }

  void limpiarMensajes() {
    state = state.copyWith(error: null, exito: null);
  }
}
