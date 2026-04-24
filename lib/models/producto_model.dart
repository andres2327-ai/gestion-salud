// lib/models/producto_model.dart

enum TipoProducto { pastillas, liquido, polvo }

class ProductoModel {
  final String codigoBarras;
  final String nombre;
  final TipoProducto tipo;
  final double precioUnitario;
  final int cantidadStock;
  final DateTime fechaVencimiento;
  final bool activo;

  ProductoModel({
    required this.codigoBarras,
    required this.nombre,
    required this.tipo,
    required this.precioUnitario,
    required this.cantidadStock,
    required this.fechaVencimiento,
    required this.activo,
  });

  factory ProductoModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductoModel(
      codigoBarras: id,
      nombre: map['nombre'] ?? '',
      tipo: TipoProducto.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoProducto.pastillas,
      ),
      precioUnitario: (map['precio_unitario'] ?? 0).toDouble(),
      cantidadStock: map['cantidad_stock'] ?? 0,
      fechaVencimiento: map['fecha_vencimiento'] != null
          ? (map['fecha_vencimiento'] as dynamic).toDate()
          : DateTime.now(),
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tipo': tipo.name,
      'precio_unitario': precioUnitario,
      'cantidad_stock': cantidadStock,
      'fecha_vencimiento': fechaVencimiento,
      'activo': activo,
    };
  }

  bool get estaVencido => fechaVencimiento.isBefore(DateTime.now());

  bool get venceProximamente =>
      fechaVencimiento.isBefore(DateTime.now().add(const Duration(days: 30)));
}
