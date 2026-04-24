// lib/controllers/producto_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto_model.dart';
import '../services/producto_service.dart';

class ProductoState {
  final List<ProductoModel> productos;
  final bool cargando;
  final String? error;
  final String? exito;

  const ProductoState({
    this.productos = const [],
    this.cargando = false,
    this.error,
    this.exito,
  });

  // Productos filtrados por tipo
  List<ProductoModel> porTipo(TipoProducto tipo) =>
      productos.where((p) => p.tipo == tipo).toList();

  // Productos con stock bajo
  List<ProductoModel> get stockBajo =>
      productos.where((p) => p.cantidadStock < 10).toList();

  // Productos próximos a vencer
  List<ProductoModel> get proximosVencer =>
      productos.where((p) => p.venceProximamente).toList();

  ProductoState copyWith({
    List<ProductoModel>? productos,
    bool? cargando,
    String? error,
    String? exito,
  }) {
    return ProductoState(
      productos: productos ?? this.productos,
      cargando: cargando ?? this.cargando,
      error: error,
      exito: exito,
    );
  }
}

class ProductoController extends StateNotifier<ProductoState> {
  final ProductoService _service;

  ProductoController(this._service) : super(const ProductoState()) {
    cargar();
  }

  // Suscribirse al stream de productos
  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      _service.streamProductos().listen(
        (lista) {
          state = state.copyWith(productos: lista, cargando: false);
        },
        onError: (e) {
          state = state.copyWith(cargando: false, error: e.toString());
        },
      );
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  // Agregar producto nuevo
  Future<bool> agregarProducto(ProductoModel producto) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.agregarProducto(producto);
      state = state.copyWith(exito: 'Producto agregado al inventario.');
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // Actualizar producto
  Future<bool> actualizarProducto(
    String codigoBarras,
    Map<String, dynamic> datos,
  ) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      await _service.actualizarProducto(codigoBarras, datos);
      state = state.copyWith(exito: 'Producto actualizado.');
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return false;
    }
  }

  // Ajustar stock (entrada de mercancía)
  Future<void> ajustarStock(String codigoBarras, int cantidad) async {
    try {
      await _service.ajustarStock(codigoBarras, cantidad);
      state = state.copyWith(
        exito: cantidad > 0 ? 'Stock actualizado.' : 'Stock ajustado.',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Desactivar producto
  Future<void> desactivarProducto(String codigoBarras) async {
    try {
      await _service.desactivarProducto(codigoBarras);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void limpiarMensajes() {
    state = state.copyWith(error: null, exito: null);
  }
}
