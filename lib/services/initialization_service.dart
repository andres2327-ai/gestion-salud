import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';

class InitializationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Inicializar datos de ejemplo en Firestore
  Future<void> inicializarDatos() async {
    try {
      // Crear productos de ejemplo
      await _crearProductosEjemplo();

      // Crear tarjetas de ejemplo (ventas)
      await _crearTarjetasEjemplo();

      // Crear devoluciones de ejemplo
      await _crearDevolucionesEjemplo();

      print('✅ Datos inicializados correctamente');
    } catch (e) {
      print('❌ Error inicializando datos: $e');
      rethrow;
    }
  }

  Future<void> _crearProductosEjemplo() async {
    final productosRef = _db.collection('productos');

    final productos = [
      {
        'codigo_barras': 'COLAGENO001',
        'nombre': 'Colágeno Hidrolizado',
        'descripcion': 'Suplemento de colágeno premium',
        'tipo': 'Suplemento',
        'precio_unitario': 25000,
        'cantidad_stock': 45,
        'cantidad_minima': 10,
        'proveedor': 'NutriHealth',
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo_barras': 'OMEGA3001',
        'nombre': 'Omega 3 Plus',
        'descripcion': 'Ácidos grasos omega 3',
        'tipo': 'Vitaminas',
        'precio_unitario': 35000,
        'cantidad_stock': 12,
        'cantidad_minima': 5,
        'proveedor': 'Pharma+',
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo_barras': 'CREMA001',
        'nombre': 'Crema Regeneradora',
        'descripcion': 'Crema hidratante con vitamina E',
        'tipo': 'Cuidado',
        'precio_unitario': 45000,
        'cantidad_stock': 8,
        'cantidad_minima': 3,
        'proveedor': 'BellezaNatural',
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo_barras': 'ZINC001',
        'nombre': 'Zinc 30mg',
        'descripcion': 'Suplemento de zinc para inmunidad',
        'tipo': 'Vitaminas',
        'precio_unitario': 18000,
        'cantidad_stock': 28,
        'cantidad_minima': 8,
        'proveedor': 'NutriHealth',
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'codigo_barras': 'MULTIVIT001',
        'nombre': 'Multivitamínico Completo',
        'descripcion': 'Complejo vitamínico con minerales',
        'tipo': 'Vitaminas',
        'precio_unitario': 55000,
        'cantidad_stock': 15,
        'cantidad_minima': 5,
        'proveedor': 'Pharma+',
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
    ];

    for (final producto in productos) {
      final docRef = productosRef.doc(producto['codigo_barras'] as String);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set(producto);
      }
    }
  }

  Future<void> _crearTarjetasEjemplo() async {
    final tarjetasRef = _db.collection('tarjetas');

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final tarjetas = [
      {
        'nombre_cliente': 'Juan García',
        'nombre_asesora': 'María López',
        'total_venta': 150000.0,
        'saldo_pendiente': 75000.0,
        'estado': 'activa',
        'fecha_venta': Timestamp.fromDate(hoy),
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'nombre_cliente': 'Ana Rodríguez',
        'nombre_asesora': 'Carlos Mendez',
        'total_venta': 120000.0,
        'saldo_pendiente': 60000.0,
        'estado': 'activa',
        'fecha_venta': Timestamp.fromDate(
          hoy.subtract(const Duration(hours: 2)),
        ),
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'nombre_cliente': 'Pedro Martínez',
        'nombre_asesora': 'María López',
        'total_venta': 200000.0,
        'saldo_pendiente': 0.0,
        'estado': 'pagada',
        'fecha_venta': Timestamp.fromDate(
          hoy.subtract(const Duration(days: 1)),
        ),
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
    ];

    for (int i = 0; i < tarjetas.length; i++) {
      await tarjetasRef
          .doc('tarjeta_$i')
          .set(tarjetas[i], SetOptions(merge: true));
    }
  }

  Future<void> _crearDevolucionesEjemplo() async {
    final devolucionesRef = _db.collection('devoluciones');

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final devoluciones = [
      {
        'codigo_producto': 'COLAGENO001',
        'nombre_producto': 'Colágeno Hidrolizado',
        'cantidad': 2,
        'motivo': 'Producto defectuoso',
        'fecha_devolucion': Timestamp.fromDate(hoy),
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
    ];

    for (int i = 0; i < devoluciones.length; i++) {
      final doc = await devolucionesRef.doc('devolucion_$i').get();
      if (!doc.exists) {
        await devolucionesRef.doc('devolucion_$i').set(devoluciones[i]);
      }
    }
  }
}
