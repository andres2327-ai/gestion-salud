// widgets/custom_text_field.dart
// Versión unificada: combina el estilo dark del UI original
// con las funcionalidades extra del forms (obscureText toggle, minLines)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;           // alias compatible con forms
  final String? hint;               // alias compatible con ui original
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;       // acepta IconData (forms)
  final Widget? prefixIconWidget;   // acepta Widget (ui original)
  final Widget? suffixIcon;
  final int maxLines;
  final int minLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.prefixIconWidget,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  Widget? get _resolvedPrefixIcon {
    if (widget.prefixIconWidget != null) {
      return IconTheme(
        data: const IconThemeData(color: AppColors.textHint, size: 18),
        child: widget.prefixIconWidget!,
      );
    }
    if (widget.prefixIcon != null) {
      return Icon(widget.prefixIcon, color: AppColors.textHint, size: 18);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hintText = widget.hintText ?? widget.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: _obscure,
          maxLines: _obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: _resolvedPrefixIcon,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}

// ── Dropdown estilizado ──────────────────────────────────────────────────────
class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.hint,
    this.value,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: AppColors.cardElevated,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
