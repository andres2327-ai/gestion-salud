import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/usuario_model.dart';
import 'asesora_nueva_venta_screen.dart';
import 'asesora_devolucion_screen.dart';
import 'asesora_productos_screen.dart';

class AsesoraHomeScreen extends ConsumerStatefulWidget {
  const AsesoraHomeScreen({super.key});

  @override
  ConsumerState<AsesoraHomeScreen> createState() => _AsesoraHomeScreenState();
}

class _AsesoraHomeScreenState extends ConsumerState<AsesoraHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final perfil = ref.read(usuarioActualProvider);
      if (perfil != null) {
        ref
            .read(tarjetaControllerProvider.notifier)
            .cargarTarjetasAsesora(perfil.uid);
        ref
            .read(cobroControllerProvider.notifier)
            .escucharDevolucionesAsesora(perfil.uid);
      }
    });
  }

  Future<void> _mostrarEditarMeta(
    BuildContext context,
    UsuarioModel perfil,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final ctrl = TextEditingController(
      text: perfil.metaMensual.toInt().toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Meta mensual'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            hintText: '1500000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    ctrl.dispose();

    if (result != null && context.mounted) {
      await ref
          .read(usuarioServiceProvider)
          .actualizarUsuario(perfil.uid, {'meta_mensual': result});
      ref.read(authControllerProvider.notifier).actualizarMetaMensual(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(usuarioActualProvider);
    final tarjetaState = ref.watch(tarjetaControllerProvider);
    final cobroState = ref.watch(cobroControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (perfil == null) return const SizedBox();

    final initials = perfil.nombre
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final ahora = DateTime.now();

    final totalVentas = tarjetaState.tarjetas
        .where(
          (t) =>
              t.asesoraUid == perfil.uid &&
              t.fechaVenta.month == ahora.month &&
              t.fechaVenta.year == ahora.year,
        )
        .fold<double>(0, (s, t) => s + t.totalVenta);

    final totalDevoluciones = cobroState.devoluciones
        .where(
          (d) =>
              d.asesoraUid == perfil.uid &&
              d.estado == EstadoDevolucion.aprobada &&
              d.fechaDevolucion.month == ahora.month &&
              d.fechaDevolucion.year == ahora.year,
        )
        .fold<double>(0, (s, d) => s + d.montoReembolso);

    final totalMes =
        (totalVentas - totalDevoluciones).clamp(0.0, double.infinity);
    final metaMes = perfil.metaMensual;
    final progreso =
        metaMes > 0 ? (totalMes / metaMes).clamp(0.0, 1.0) : 0.0;

    final fmt = NumberFormat('#,###', 'es_CO');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hola,', style: textTheme.bodySmall),
                      Text(
                        perfil.nombre,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Meta del mes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mi Meta del Mes',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => _mostrarEditarMeta(context, perfil),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${fmt.format(totalMes)} / \$${fmt.format(metaMes)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progreso,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progreso * 100).toStringAsFixed(0)}% completado — ¡Sigue así!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Acciones rápidas
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _ActionCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Nueva Venta',
                    color: colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AsesoraNuevaVentaScreen(
                          asesoraUid: perfil.uid,
                          asesoraNombre: perfil.nombre,
                        ),
                      ),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Mis Productos',
                    color: const Color(0xFF7B5E2A),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AsesoraProductosScreen(),
                      ),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.replay_outlined,
                    label: 'Devolución',
                    color: colorScheme.error,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AsesoraDevolucionScreen(
                          asesoraUid: perfil.uid,
                        ),
                      ),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.bar_chart_outlined,
                    label: 'Mis Ventas',
                    color: Colors.blue,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
