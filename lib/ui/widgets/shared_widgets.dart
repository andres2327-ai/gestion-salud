import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── SectionLabel ─────────────────────────────────────────────────────────────
// Etiqueta de sección en mayúsculas, estilo neutro (onSurfaceVariant)
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.06,
      ),
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────
// Encabezado de sección con ícono, texto jade y línea divisora
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const SectionHeader({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    return Row(
      children: [
        Icon(icon, color: jadeColor, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: jadeColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),
        ),
      ],
    );
  }
}

// ─── CounterButton ────────────────────────────────────────────────────────────
// Botón + / − de cantidad con estado habilitado/deshabilitado
class CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final Color? accentBg;
  final VoidCallback? onTap;
  final double size;

  const CounterButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    this.accentBg,
    this.onTap,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = accentBg ?? accentColor.withAlpha(30);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled
              ? bg
              : (isDark ? AppColors.darkInk100 : AppColors.lightInk100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? accentColor
                : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
          ),
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: enabled ? accentColor : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── FreqOption ───────────────────────────────────────────────────────────────
// Opción de frecuencia de pago (Diaria / Semanal)
class FreqOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final Color accentBg;
  final VoidCallback onTap;

  const FreqOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.accentBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentBg
              : (isDark ? AppColors.darkInk100 : AppColors.lightInk100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? accentColor
                : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? accentColor : cs.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? accentColor : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
