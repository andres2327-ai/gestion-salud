// lib/models/tarjeta_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoPago { cuotas, contado }

enum FrecuenciaPago { diaria, semanal }

enum EstadoTarjeta { activa, pagada, vencida }

// ─── Ítem de producto dentro de una tarjeta ──────────────────────────────────
class TarjetaProductoModel {
  final String id;
  final String tarjetaId;
  final String codigoBarras;
  final String nombreProducto;
  final int cantidad;
  final double precioVenta;
  final double subtotal;

  TarjetaProductoModel({
    required this.id,
    required this.tarjetaId,
    required this.codigoBarras,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioVenta,
    required this.subtotal,
  });

  factory TarjetaProductoModel.fromMap(Map<String, dynamic> map, String id) {
    return TarjetaProductoModel(
      id: id,
      tarjetaId: map['tarjeta_id'] ?? '',
      codigoBarras: map['codigo_barras'] ?? '',
      nombreProducto: map['nombre_producto'] ?? '',
      cantidad: map['cantidad'] ?? 0,
      precioVenta: (map['precio_venta'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tarjeta_id': tarjetaId,
      'codigo_barras': codigoBarras,
      'nombre_producto': nombreProducto,
      'cantidad': cantidad,
      'precio_venta': precioVenta,
      'subtotal': subtotal,
    };
  }
}

// ─── Tarjeta (Venta) ──────────────────────────────────────────────────────────
class TarjetaModel {
  final String tarjetaId;
  final String asesoraUid;
  final String nombreAsesora;
  final String nombreCliente;
  final String telefonoCliente;
  final String direccionCliente;
  final double latitud;
  final double longitud;
  final TipoPago tipoPago;
  final FrecuenciaPago frecuenciaPago;
  final int numCuotas;
  final double montoCuota;
  final double totalVenta;
  final double totalDevuelto;
  final double saldoPendiente;
  final EstadoTarjeta estado;
  final DateTime fechaVenta;
  final String? fotoUrl;
  final List<TarjetaProductoModel> productos;

  TarjetaModel({
    required this.tarjetaId,
    required this.asesoraUid,
    required this.nombreAsesora,
    required this.nombreCliente,
    required this.telefonoCliente,
    required this.direccionCliente,
    required this.latitud,
    required this.longitud,
    required this.tipoPago,
    this.frecuenciaPago = FrecuenciaPago.semanal,
    required this.numCuotas,
    required this.montoCuota,
    required this.totalVenta,
    required this.totalDevuelto,
    required this.saldoPendiente,
    required this.estado,
    required this.fechaVenta,
    this.fotoUrl,
    this.productos = const [],
  });

  factory TarjetaModel.fromMap(Map<String, dynamic> map, String id) {
    final rawProductos = map['productos'];
    final List<TarjetaProductoModel> productos =
        rawProductos is List && rawProductos.isNotEmpty
            ? rawProductos
                .map(
                  (p) => TarjetaProductoModel.fromMap(
                    Map<String, dynamic>.from(p as Map),
                    '',
                  ),
                )
                .toList()
            : const [];

    return TarjetaModel(
      tarjetaId: id,
      asesoraUid: map['asesora_uid'] ?? '',
      nombreAsesora: map['nombre_asesora'] ?? '',
      nombreCliente: map['nombre_cliente'] ?? '',
      telefonoCliente: map['telefono_cliente'] ?? '',
      direccionCliente: map['direccion_cliente'] ?? '',
      latitud: (map['latitud'] ?? 0).toDouble(),
      longitud: (map['longitud'] ?? 0).toDouble(),
      tipoPago: TipoPago.values.firstWhere(
        (t) => t.name == map['tipo_pago'],
        orElse: () => TipoPago.cuotas,
      ),
      frecuenciaPago: FrecuenciaPago.values.firstWhere(
        (f) => f.name == map['frecuencia_pago'],
        orElse: () => FrecuenciaPago.semanal,
      ),
      numCuotas: map['num_cuotas'] ?? 0,
      montoCuota: (map['monto_cuota'] ?? 0).toDouble(),
      totalVenta: (map['total_venta'] ?? 0).toDouble(),
      totalDevuelto: (map['total_devuelto'] ?? 0).toDouble(),
      saldoPendiente: (map['saldo_pendiente'] ?? 0).toDouble(),
      estado: EstadoTarjeta.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoTarjeta.activa,
      ),
      fechaVenta: map['fecha_venta'] != null
          ? (map['fecha_venta'] as Timestamp).toDate()
          : DateTime.now(),
      fotoUrl: map['foto_url'],
      productos: productos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'asesora_uid': asesoraUid,
      'nombre_asesora': nombreAsesora,
      'nombre_cliente': nombreCliente,
      'telefono_cliente': telefonoCliente,
      'direccion_cliente': direccionCliente,
      'latitud': latitud,
      'longitud': longitud,
      'tipo_pago': tipoPago.name,
      'frecuencia_pago': frecuenciaPago.name,
      'num_cuotas': numCuotas,
      'monto_cuota': montoCuota,
      'total_venta': totalVenta,
      'total_devuelto': totalDevuelto,
      'saldo_pendiente': saldoPendiente,
      'estado': estado.name,
      'fecha_venta': FieldValue.serverTimestamp(),
      'foto_url': fotoUrl,
    };
  }
}

// ─── Cuota ────────────────────────────────────────────────────────────────────
enum EstadoCuota { pendiente, cobrada, vencida }

class CuotaModel {
  final String cuotaId;
  final String tarjetaId;
  final String? cobradorUid;
  final int numeroCuota;
  final double monto;
  final EstadoCuota estado;
  final DateTime fechaVencimiento;
  final DateTime? fechaCobro;
  final String? observacion;

  CuotaModel({
    required this.cuotaId,
    required this.tarjetaId,
    this.cobradorUid,
    required this.numeroCuota,
    required this.monto,
    required this.estado,
    required this.fechaVencimiento,
    this.fechaCobro,
    this.observacion,
  });

  factory CuotaModel.fromMap(Map<String, dynamic> map, String id) {
    return CuotaModel(
      cuotaId: id,
      tarjetaId: map['tarjeta_id'] ?? '',
      cobradorUid: map['cobrador_uid'],
      numeroCuota: map['numero_cuota'] ?? 0,
      monto: (map['monto'] ?? 0).toDouble(),
      estado: EstadoCuota.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoCuota.pendiente,
      ),
      fechaVencimiento: map['fecha_vencimiento'] != null
          ? (map['fecha_vencimiento'] as Timestamp).toDate()
          : DateTime.now(),
      fechaCobro: map['fecha_cobro'] != null
          ? (map['fecha_cobro'] as Timestamp).toDate()
          : null,
      observacion: map['observacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tarjeta_id': tarjetaId,
      'cobrador_uid': cobradorUid,
      'numero_cuota': numeroCuota,
      'monto': monto,
      'estado': estado.name,
      'fecha_vencimiento': fechaVencimiento,
      'fecha_cobro': fechaCobro,
      'observacion': observacion,
    };
  }
}

// ─── Devolución ───────────────────────────────────────────────────────────────
enum EstadoDevolucion { pendiente, aprobada, rechazada }

class DevolucionModel {
  final String devolucionId;
  final String tarjetaId;
  final String tarjetaProductoId;
  final String codigoBarras;
  final String asesoraUid;
  final String? adminUid;
  final String nombreCliente;
  final String nombreProducto;
  final int cantidadDevuelta;
  final double montoReembolso;
  final String motivo;
  final EstadoDevolucion estado;
  final DateTime fechaDevolucion;
  final DateTime? fechaResolucion;

  DevolucionModel({
    required this.devolucionId,
    required this.tarjetaId,
    required this.tarjetaProductoId,
    this.codigoBarras = '',
    required this.asesoraUid,
    this.adminUid,
    required this.nombreCliente,
    required this.nombreProducto,
    required this.cantidadDevuelta,
    required this.montoReembolso,
    required this.motivo,
    required this.estado,
    required this.fechaDevolucion,
    this.fechaResolucion,
  });

  factory DevolucionModel.fromMap(Map<String, dynamic> map, String id) {
    return DevolucionModel(
      devolucionId: id,
      tarjetaId: map['tarjeta_id'] ?? '',
      tarjetaProductoId: map['tarjeta_producto_id'] ?? '',
      codigoBarras: map['codigo_barras'] ?? '',
      asesoraUid: map['asesora_uid'] ?? '',
      adminUid: map['admin_uid'],
      nombreCliente: map['nombre_cliente'] ?? '',
      nombreProducto: map['nombre_producto'] ?? '',
      cantidadDevuelta: map['cantidad_devuelta'] ?? 0,
      montoReembolso: (map['monto_reembolso'] ?? 0).toDouble(),
      motivo: map['motivo'] ?? '',
      estado: EstadoDevolucion.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoDevolucion.pendiente,
      ),
      fechaDevolucion: map['fecha_devolucion'] != null
          ? (map['fecha_devolucion'] as Timestamp).toDate()
          : DateTime.now(),
      fechaResolucion: map['fecha_resolucion'] != null
          ? (map['fecha_resolucion'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tarjeta_id': tarjetaId,
      'tarjeta_producto_id': tarjetaProductoId,
      'codigo_barras': codigoBarras,
      'asesora_uid': asesoraUid,
      'admin_uid': adminUid,
      'nombre_cliente': nombreCliente,
      'nombre_producto': nombreProducto,
      'cantidad_devuelta': cantidadDevuelta,
      'monto_reembolso': montoReembolso,
      'motivo': motivo,
      'estado': estado.name,
      'fecha_devolucion': FieldValue.serverTimestamp(),
      'fecha_resolucion': fechaResolucion,
    };
  }
}

// ─── Asignación cobrador-tarjeta ──────────────────────────────────────────────
class AsignacionModel {
  final String asignacionId;
  final String cobradorUid;
  final String nombreCobrador;
  final String tarjetaId;
  final String nombreCliente;
  final String adminUid;
  final DateTime fechaAsignacion;
  final bool activa;

  AsignacionModel({
    required this.asignacionId,
    required this.cobradorUid,
    required this.nombreCobrador,
    required this.tarjetaId,
    required this.nombreCliente,
    required this.adminUid,
    required this.fechaAsignacion,
    required this.activa,
  });

  factory AsignacionModel.fromMap(Map<String, dynamic> map, String id) {
    return AsignacionModel(
      asignacionId: id,
      cobradorUid: map['cobrador_uid'] ?? '',
      nombreCobrador: map['nombre_cobrador'] ?? '',
      tarjetaId: map['tarjeta_id'] ?? '',
      nombreCliente: map['nombre_cliente'] ?? '',
      adminUid: map['admin_uid'] ?? '',
      fechaAsignacion: map['fecha_asignacion'] != null
          ? (map['fecha_asignacion'] as Timestamp).toDate()
          : DateTime.now(),
      activa: map['activa'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cobrador_uid': cobradorUid,
      'nombre_cobrador': nombreCobrador,
      'tarjeta_id': tarjetaId,
      'nombre_cliente': nombreCliente,
      'admin_uid': adminUid,
      'fecha_asignacion': FieldValue.serverTimestamp(),
      'activa': activa,
    };
  }
}
