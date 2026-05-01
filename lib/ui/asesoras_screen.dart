import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import 'admin_asignar_productos_screen.dart';
import 'admin_asignar_tarjetas_screen.dart';

class AsesoresScreen extends ConsumerStatefulWidget {
  const AsesoresScreen({super.key});

  @override
  ConsumerState<AsesoresScreen> createState() => _AsesoresScreenState();
}

class _AsesoresScreenState extends ConsumerState<AsesoresScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(usuarioControllerProvider.notifier).cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuarioState = ref.watch(usuarioControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.error),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioUsuario(context),
        child: const Icon(Icons.person_add),
      ),
      body: usuarioState.cargando
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : usuarioState.error != null
          ? Center(
              child: Text(
                'Error: ${usuarioState.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(usuarioControllerProvider.notifier).cargar(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ResumenItem(
                            'Total',
                            usuarioState.todos.length.toString(),
                            Colors.blue,
                          ),
                          _ResumenItem(
                            'Activos',
                            usuarioState.todos
                                .where((u) => u.activo)
                                .length
                                .toString(),
                            Colors.green,
                          ),
                          _ResumenItem(
                            'Inactivos',
                            usuarioState.todos
                                .where((u) => !u.activo)
                                .length
                                .toString(),
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (usuarioState.asesoras.isNotEmpty) ...[
                      _SectionTitle(
                        'Asesoras (${usuarioState.asesoras.length})',
                      ),
                      const SizedBox(height: 12),
                      ...usuarioState.asesoras.map(
                        (u) => _UsuarioCard(
                          usuario: u,
                          onTap: () => _mostrarOpcionesUsuario(context, u),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (usuarioState.cobradores.isNotEmpty) ...[
                      _SectionTitle(
                        'Cobradores (${usuarioState.cobradores.length})',
                      ),
                      const SizedBox(height: 12),
                      ...usuarioState.cobradores.map(
                        (u) => _UsuarioCard(
                          usuario: u,
                          onTap: () => _mostrarOpcionesUsuario(context, u),
                        ),
                      ),
                    ],

                    if (usuarioState.todos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No hay usuarios registrados',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _mostrarOpcionesUsuario(BuildContext context, UsuarioModel usuario) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    usuario.nombre.isNotEmpty
                        ? usuario.nombre[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        usuario.rol == RolUsuario.asesora
                            ? 'Asesora'
                            : 'Cobrador',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // Toggle activo/inactivo
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                usuario.activo
                    ? Icons.person_off_outlined
                    : Icons.person_outlined,
                color: usuario.activo ? Colors.orange : Colors.green,
              ),
              title: Text(
                usuario.activo ? 'Desactivar usuario' : 'Activar usuario',
                style: TextStyle(
                  color: usuario.activo ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(usuarioControllerProvider.notifier)
                    .toggleActivo(usuario);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        usuario.activo
                            ? 'Usuario desactivado'
                            : 'Usuario activado',
                      ),
                    ),
                  );
                }
              },
            ),

            // Asignar productos (solo asesoras)
            if (usuario.rol == RolUsuario.asesora)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.primary,
                ),
                title: Text(
                  'Asignar productos',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarAsignarProductos(context, usuario);
                },
              ),

            // Asignar tarjetas de cobro (solo cobradores)
            if (usuario.rol == RolUsuario.cobrador)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.credit_card_outlined,
                  color: colorScheme.tertiary,
                ),
                title: Text(
                  'Asignar tarjetas',
                  style: TextStyle(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminAsignarTarjetasScreen(cobrador: usuario),
                    ),
                  );
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarAsignarProductos(BuildContext context, UsuarioModel asesora) {
    ref
        .read(asignacionProductoControllerProvider.notifier)
        .escucharAsignaciones(asesora.uid);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAsignarProductosScreen(asesora: asesora),
      ),
    );
  }

  void _mostrarFormularioUsuario(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    RolUsuario rolSeleccionado = RolUsuario.asesora;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: nombreCtrl, hint: 'Nombre'),
                const SizedBox(height: 10),
                _DialogField(
                  controller: emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: passwordCtrl,
                  hint: 'Contraseña',
                  obscure: true,
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: telefonoCtrl,
                  hint: 'Teléfono',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _DialogField(controller: direccionCtrl, hint: 'Dirección'),
                const SizedBox(height: 10),
                DropdownButtonFormField<RolUsuario>(
                  initialValue: rolSeleccionado,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(
                      value: RolUsuario.asesora,
                      child: Text('Asesora'),
                    ),
                    DropdownMenuItem(
                      value: RolUsuario.cobrador,
                      child: Text('Cobrador'),
                    ),
                    DropdownMenuItem(
                      value: RolUsuario.admin,
                      child: Text('Administrador'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => rolSeleccionado = v);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty ||
                    emailCtrl.text.isEmpty ||
                    passwordCtrl.text.isEmpty ||
                    telefonoCtrl.text.isEmpty ||
                    direccionCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Completa todos los campos'),
                    ),
                  );
                  return;
                }
                final ok = await ref
                    .read(usuarioControllerProvider.notifier)
                    .crearUsuario(
                      nombre: nombreCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passwordCtrl.text,
                      telefono: telefonoCtrl.text.trim(),
                      direccion: direccionCtrl.text.trim(),
                      rol: rolSeleccionado,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Usuario creado' : 'Error al crear usuario',
                      ),
                      backgroundColor: ok
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

// ─── Widgets locales ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _ResumenItem(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;
  final VoidCallback onTap;

  const _UsuarioCard({required this.usuario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor =
        Theme.of(context).cardTheme.color ?? colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: usuario.activo
                ? Colors.green.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                usuario.nombre.isNotEmpty
                    ? usuario.nombre[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        usuario.nombre,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: usuario.activo
                              ? Colors.green.withValues(alpha: 0.15)
                              : colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          usuario.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: usuario.activo
                                ? Colors.green
                                : colorScheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(usuario.email, style: textTheme.bodySmall),
                  Text(
                    usuario.telefono,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;

  const _DialogField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(hintText: hint),
    );
  }
}
