import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// The app's text input: a white field with the card border, leaf-500 when
/// focused, soil-900 when [hasError] (CM-04 username). [maxLength] stops
/// input at that many characters without showing a counter.
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
    this.keyboardType,
    this.inputFormatters = const [],
    this.autofillHints,
    this.hasError = false,
    this.prefixFilled = false,
    this.verticalPadding = AppSpacing.md,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;

  /// Applied before the [maxLength] limit.
  final List<TextInputFormatter> inputFormatters;
  final Iterable<String>? autofillHints;
  final bool hasError;

  /// Draws [prefixIcon] in its filled form.
  final bool prefixFilled;

  /// Space above and below the text; the CM-04 fields use 17.
  final double verticalPadding;

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
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      inputFormatters: [
        ...inputFormatters,
        if (max != null) LengthLimitingTextInputFormatter(max),
      ],
      style: AppText.body.copyWith(color: AppColors.soil900),
      cursorColor: AppColors.leaf700,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.body.copyWith(color: AppColors.soil600),
        filled: true,
        fillColor: AppColors.white,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: AppColors.soil600,
                fill: prefixFilled ? 1 : 0,
              ),
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: verticalPadding,
        ),
        enabledBorder: _border(
          hasError ? AppColors.soil900 : AppColors.stone200,
        ),
        focusedBorder: _border(
          hasError ? AppColors.soil900 : AppColors.leaf500,
        ),
        border: _border(hasError ? AppColors.soil900 : AppColors.stone200),
      ),
    );
  }
}
