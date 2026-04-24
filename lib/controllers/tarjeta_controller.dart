// lib/controllers/tarjeta_controller.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tarjeta_model.dart';
import '../models/producto_model.dart';
import '../models/asignacion_producto_model.dart';
import '../services/tarjeta_service.dart';
import '../services/storage_service.dart';

// ─── Ítem del carrito al crear una venta ─────────────────────────────────────
class ItemCarrito {
  final ProductoModel producto;
  int cantidad;

  ItemCarrito({required this.producto, required this.cantidad});

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

  TarjetaController(
    this._tarjetaService,
    this._storageService,
    this._gpsService,
  ) : super(const TarjetaState());

  // Cargar tarjetas de una asesora
  void cargarTarjetasAsesora(String asesoraUid) {
    _tarjetaService.streamTarjetasAsesora(asesoraUid).listen((lista) {
      state = state.copyWith(tarjetas: lista);
    });
  }

  // Cargar tarjetas asignadas al cobrador (por lista de IDs)
  void cargarTarjetasCobrador(List<String> tarjetaIds) {
    if (tarjetaIds.isEmpty) {
      state = state.copyWith(tarjetasCobrador: []);
      return;
    }
    _tarjetaService.streamTarjetasPorIds(tarjetaIds).listen((lista) {
      state = state.copyWith(tarjetasCobrador: lista);
    });
  }

  // Cargar todas (admin)
  void cargarTodas() {
    _tarjetaService.streamTodasLasTarjetas().listen((lista) {
      state = state.copyWith(tarjetas: lista);
    });
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

  void agregarAlCarrito(ProductoModel producto, int cantidad) {
    final carritoActual = List<ItemCarrito>.from(state.carrito);
    final idx = carritoActual.indexWhere(
      (i) => i.producto.codigoBarras == producto.codigoBarras,
    );

    if (idx >= 0) {
      carritoActual[idx] = ItemCarrito(
        producto: producto,
        cantidad: carritoActual[idx].cantidad + cantidad,
      );
    } else {
      carritoActual.add(ItemCarrito(producto: producto, cantidad: cantidad));
    }
    state = state.copyWith(carrito: carritoActual);
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
    File? foto,
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
      final montoCuota = tipoPago == TipoPago.cuotas && numCuotas > 0
          ? totalVenta / numCuotas
          : totalVenta;

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
        totalDevuelto: 0,
        saldoPendiente: totalVenta,
        estado: EstadoTarjeta.activa,
        fechaVenta: DateTime.now(),
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
        );
      }).toList();

      // Construir cuotas
      final cuotas = _generarCuotas(
        numCuotas: tipoPago == TipoPago.contado ? 1 : numCuotas,
        montoCuota: montoCuota,
        frecuenciaPago: frecuenciaPago,
      );

      // Guardar en Firestore
      final tarjetaId = await _tarjetaService.crearTarjeta(
        tarjeta: tarjeta,
        productos: productos,
        cuotas: cuotas,
      );

      // Subir foto si existe
      if (foto != null) {
        final fotoUrl = await _storageService.subirFotoTarjeta(
          foto: foto,
          tarjetaId: tarjetaId,
        );
        await _tarjetaService.actualizarFoto(tarjetaId, fotoUrl);
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
