// lib/ui/widgets/foto_picker.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';

class FotoPickerTile extends StatefulWidget {
  final XFile? valor;
  final void Function(XFile? foto) onChanged;
  final bool requerida;
  final bool mostrarError;
  final Color accentColor;
  final Color accentBg;

  const FotoPickerTile({
    super.key,
    required this.onChanged,
    this.valor,
    this.requerida = true,
    this.mostrarError = false,
    required this.accentColor,
    required this.accentBg,
  });

  @override
  State<FotoPickerTile> createState() => _FotoPickerTileState();
}

class _FotoPickerTileState extends State<FotoPickerTile> {
  final _picker = ImagePicker();
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    if (widget.valor != null) _loadPreview(widget.valor!);
  }

  @override
  void didUpdateWidget(FotoPickerTile old) {
    super.didUpdateWidget(old);
    if (widget.valor != old.valor) {
      if (widget.valor == null) {
        setState(() => _previewBytes = null);
      } else {
        _loadPreview(widget.valor!);
      }
    }
  }

  Future<void> _loadPreview(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    if (mounted) setState(() => _previewBytes = bytes);
  }

  Future<void> _tomarFoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
      if (mounted) {
        setState(() => _previewBytes = bytes);
        widget.onChanged(xFile);
      }
    }
  }

  Future<void> _elegirGaleria() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
      if (mounted) {
        setState(() => _previewBytes = bytes);
        widget.onChanged(xFile);
      }
    }
  }

  void _mostrarOpciones() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // En web, la cámara y la galería son la misma acción (file picker)
    if (kIsWeb) {
      _elegirGaleria();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'Agregar foto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OpcionBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Cámara',
                    color: widget.accentColor,
                    bg: widget.accentBg,
                    onTap: () {
                      Navigator.pop(context);
                      _tomarFoto();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OpcionBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Galería',
                    color: widget.accentColor,
                    bg: widget.accentBg,
                    onTap: () {
                      Navigator.pop(context);
                      _elegirGaleria();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foto = widget.valor;
    final hayError = widget.mostrarError && widget.requerida && foto == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _mostrarOpciones,
          child: Container(
            width: double.infinity,
            height: foto != null ? null : 130,
            decoration: BoxDecoration(
              color: foto != null
                  ? Colors.transparent
                  : (isDark ? AppColors.darkInk100 : AppColors.lightInk100),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hayError
                    ? (isDark ? AppColors.darkCoral : AppColors.coral)
                    : foto != null
                        ? widget.accentColor.withAlpha(120)
                        : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
                width: hayError || foto != null ? 1.5 : 1,
              ),
            ),
            child: foto != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _previewBytes != null
                            ? Image.memory(
                                _previewBytes!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _previewBytes = null);
                            widget.onChanged(null);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _mostrarOpciones,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Cambiar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.accentBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: widget.accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Toca para agregar foto',
                        style: TextStyle(
                          fontSize: 13,
                          color: hayError
                              ? (isDark ? AppColors.darkCoral : AppColors.coral)
                              : cs.onSurfaceVariant,
                          fontWeight:
                              hayError ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (widget.requerida)
                        Text(
                          '(requerida)',
                          style: TextStyle(
                            fontSize: 11,
                            color: hayError
                                ? (isDark
                                    ? AppColors.darkCoral
                                    : AppColors.coral)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (hayError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'La foto es obligatoria',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkCoral : AppColors.coral,
              ),
            ),
          ),
      ],
    );
  }
}

class _OpcionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _OpcionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
