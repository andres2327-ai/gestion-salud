import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import '../core/theme/app_theme.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout,
                color: isDark ? AppColors.darkCoral : AppColors.coral),
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
          ? const Center(child: CircularProgressIndicator())
          : usuarioState.error != null
          ? Center(
              child: Text(
                'Error: ${usuarioState.error}',
                style: TextStyle(color: cs.error),
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(usuarioControllerProvider.notifier).cargar(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkInk200
                              : AppColors.lightInk200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ResumenItem(
                            'Total',
                            usuarioState.todos.length.toString(),
                            isDark ? AppColors.darkJade : AppColors.brandJade,
                            isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                          ),
                          _ResumenItem(
                            'Activos',
                            usuarioState.todos
                                .where((u) => u.activo)
                                .length
                                .toString(),
                            isDark ? AppColors.darkViolet : AppColors.violet,
                            isDark ? AppColors.darkViolet50 : AppColors.violet50,
                          ),
                          _ResumenItem(
                            'Inactivos',
                            usuarioState.todos
                                .where((u) => !u.activo)
                                .length
                                .toString(),
                            isDark ? AppColors.darkAmber : AppColors.amber,
                            isDark ? AppColors.darkAmber50 : AppColors.amber50,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (usuarioState.asesoras.isNotEmpty) ...[
                      _SectionTitle(
                        'ASESORAS (${usuarioState.asesoras.length})',
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      ...usuarioState.asesoras.map(
                        (u) => _UsuarioCard(
                          usuario: u,
                          isDark: isDark,
                          cs: cs,
                          onTap: () => _mostrarOpcionesUsuario(context, u),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (usuarioState.cobradores.isNotEmpty) ...[
                      _SectionTitle(
                        'COBRADORES (${usuarioState.cobradores.length})',
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      ...usuarioState.cobradores.map(
                        (u) => _UsuarioCard(
                          usuario: u,
                          isDark: isDark,
                          cs: cs,
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
                            style: TextStyle(color: cs.onSurfaceVariant),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;
    final violetColor = isDark ? AppColors.darkViolet : AppColors.violet;
    final violetBg = isDark ? AppColors.darkViolet50 : AppColors.violet50;
    final initials = usuario.nombre.isNotEmpty
        ? usuario.nombre.split(' ').take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : '?';
    final isAsesora = usuario.rol == RolUsuario.asesora;
    final accentColor = isAsesora ? violetColor : jadeColor;
    final accentBg = isAsesora ? violetBg : jadeBg;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isAsesora ? 'Asesora' : 'Cobrador',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                usuario.activo
                    ? Icons.person_off_outlined
                    : Icons.person_outlined,
                color: usuario.activo
                    ? (isDark ? AppColors.darkAmber : AppColors.amber)
                    : jadeColor,
              ),
              title: Text(
                usuario.activo ? 'Desactivar usuario' : 'Activar usuario',
                style: TextStyle(
                  color: usuario.activo
                      ? (isDark ? AppColors.darkAmber : AppColors.amber)
                      : jadeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
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

            if (usuario.rol == RolUsuario.asesora)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.inventory_2_outlined, color: violetColor),
                title: Text(
                  'Asignar productos',
                  style: TextStyle(
                    color: violetColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _mostrarAsignarProductos(context, usuario);
                },
              ),

            if (usuario.rol == RolUsuario.cobrador)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.credit_card_outlined, color: jadeColor),
                title: Text(
                  'Asignar tarjetas',
                  style: TextStyle(
                    color: jadeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
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
                          ? AppColors.brandJade
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
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
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
  final ColorScheme cs;
  const _SectionTitle(this.text, {required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.06,
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final Color bg;

  const _ResumenItem(this.label, this.valor, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              valor,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;

  const _UsuarioCard({
    required this.usuario,
    required this.onTap,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isAsesora = usuario.rol == RolUsuario.asesora;
    final accentColor = isAsesora
        ? (isDark ? AppColors.darkViolet : AppColors.violet)
        : (isDark ? AppColors.darkJade : AppColors.brandJade);
    final accentBg = isAsesora
        ? (isDark ? AppColors.darkViolet50 : AppColors.violet50)
        : (isDark ? AppColors.darkJade50 : AppColors.lightJade50);
    final initials = usuario.nombre.isNotEmpty
        ? usuario.nombre
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 6),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: usuario.activo
                              ? (isDark
                                  ? AppColors.darkJade50
                                  : AppColors.lightJade50)
                              : (isDark
                                  ? AppColors.darkCoral50
                                  : AppColors.coral50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          usuario.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: usuario.activo
                                ? (isDark
                                    ? AppColors.darkJade
                                    : AppColors.brandJade)
                                : (isDark
                                    ? AppColors.darkCoral
                                    : AppColors.coral),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    usuario.telefono,
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_vert, color: cs.onSurfaceVariant, size: 20),
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
