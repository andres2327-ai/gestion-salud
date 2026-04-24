import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import '../models/producto_model.dart';

class AdminAsignarProductosScreen extends ConsumerStatefulWidget {
  final UsuarioModel asesora;

  const AdminAsignarProductosScreen({super.key, required this.asesora});

  @override
  ConsumerState<AdminAsignarProductosScreen> createState() =>
      _AdminAsignarProductosScreenState();
}

class _AdminAsignarProductosScreenState
    extends ConsumerState<AdminAsignarProductosScreen> {
  ProductoModel? _productoSeleccionado;
  final _cantCtrl = TextEditingController(text: '1');
  bool _guardando = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Cargar inventario disponible
      ref.read(productoControllerProvider.notifier).cargar();
      // ✅ FIX: cargar asignaciones existentes de esta asesora
      ref
          .read(asignacionProductoControllerProvider.notifier)
          .escucharAsignaciones(widget.asesora.uid);
    });
  }

  @override
  void dispose() {
    _cantCtrl.dispose();
    super.dispose();
  }

  Future<void> _asignar() async {
    if (_productoSeleccionado == null) {
      _snack('Selecciona un producto', error: true);
      return;
    }
    final cant = int.tryParse(_cantCtrl.text) ?? 0;
    if (cant <= 0) {
      _snack('La cantidad debe ser mayor a 0', error: true);
      return;
    }
    if (cant > _productoSeleccionado!.cantidadStock) {
      _snack(
        'No hay suficiente stock (disponible: ${_productoSeleccionado!.cantidadStock})',
        error: true,
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = await ref
        .read(asignacionProductoControllerProvider.notifier)
        .asignarProducto(
          asesoraUid: widget.asesora.uid,
          codigoBarras: _productoSeleccionado!.codigoBarras,
          nombreProducto: _productoSeleccionado!.nombre,
          precioUnitario: _productoSeleccionado!.precioUnitario,
          cantidad: cant,
        );

    setState(() => _guardando = false);

    if (mounted) {
      _snack(
        ok
            ? '$cant unidades de "${_productoSeleccionado!.nombre}" asignadas a ${widget.asesora.nombre}'
            : (ref.read(asignacionProductoControllerProvider).error ??
                'Error al asignar'),
        error: !ok,
      );
      if (ok) {
        setState(() {
          _productoSeleccionado = null;
          _cantCtrl.text = '1';
        });
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productoState = ref.watch(productoControllerProvider);
    final asigState = ref.watch(asignacionProductoControllerProvider);

    final productosDisponibles = productoState.productos
        .where((p) => p.activo && p.cantidadStock > 0)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asignar Productos',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              widget.asesora.nombre,
              style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: productoState.cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Selector de producto
                const _Label('PRODUCTO DEL INVENTARIO'),
                const SizedBox(height: 10),
                productosDisponibles.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1C3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No hay productos con stock disponible',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1C3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ProductoModel>(
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1C3A),
                            value: _productoSeleccionado,
                            hint: const Text(
                              'Selecciona un producto...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            items: productosDisponibles.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p.nombre}  ·  Stock: ${p.cantidadStock}  ·  \$${fmt.format(p.precioUnitario)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (p) =>
                                setState(() => _productoSeleccionado = p),
                          ),
                        ),
                      ),

                if (_productoSeleccionado != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.tealAccent.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.tealAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stock disponible: ${_productoSeleccionado!.cantidadStock} unidades',
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Cantidad
                const _Label('CANTIDAD A ASIGNAR'),
                const SizedBox(height: 10),
                TextField(
                  controller: _cantCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1A1C3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.tealAccent),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Botón asignar
                GestureDetector(
                  onTap: _guardando ? null : _asignar,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: _guardando ? Colors.grey : Colors.tealAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _guardando
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Asignar Producto',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Productos ya asignados a esta asesora
                const _Label('PRODUCTOS YA ASIGNADOS'),
                const SizedBox(height: 10),
                if (asigState.cargando)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  )
                else if (asigState.asignaciones.isEmpty)
                  const Text(
                    'Ninguno aún',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...asigState.asignaciones.map((a) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C3A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              a.nombreProducto,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Asignados: ${a.cantidadAsignada}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Vendidos: ${a.cantidadVendida}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Disponibles: ${a.cantidadDisponible}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.tealAccent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
