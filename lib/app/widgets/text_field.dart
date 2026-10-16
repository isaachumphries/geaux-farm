import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// The app's text input: a white field with the card border, leaf-500 when
/// focused. [maxLength] stops input at that many characters without
/// showing a counter.
class GeauxTextField extends StatelessWidget {
  const GeauxTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.maxLength,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.card),
    borderSide: BorderSide(color: color, width: AppBorders.width),
  );

  @override
  Widget build(BuildContext context) {
    final max = maxLength;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: textInputAction,
      inputFormatters: [if (max != null) LengthLimitingTextInputFormatter(max)],
      style: AppText.body.copyWith(color: AppColors.soil900),
      cursorColor: AppColors.leaf700,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.body.copyWith(color: AppColors.soil600),
        filled: true,
        fillColor: AppColors.white,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.soil600),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        enabledBorder: _border(AppColors.stone200),
        focusedBorder: _border(AppColors.leaf500),
        border: _border(AppColors.stone200),
      ),
    );
  }
}
