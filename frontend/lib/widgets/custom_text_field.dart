import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputAction? textInputAction;
  final bool readOnly;
  
  const CustomTextField({
    Key? key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.contentPadding,
    this.textInputAction,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      autofocus: autofocus,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textInputAction: textInputAction,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.textPrimaryColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }
}

class CustomSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const CustomSearchField({
    Key? key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textLightColor),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondaryColor, size: 20),
                  onPressed: () {
                    controller!.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class OtpTextField extends StatelessWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool autofocus;
  
  const OtpTextField({
    Key? key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<FocusNode> focusNodes = List.generate(length, (_) => FocusNode());
    final List<TextEditingController> controllers = List.generate(length, (_) => TextEditingController());
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        length,
        (index) => SizedBox(
          width: 50,
          height: 60,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            autofocus: autofocus && index == 0,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.isNotEmpty) {
                // Move to next field
                if (index < length - 1) {
                  focusNodes[index + 1].requestFocus();
                } else {
                  // Last field, unfocus
                  focusNodes[index].unfocus();
                }
              }
              
              // Collect all values
              final otp = controllers.map((controller) => controller.text).join();
              onChanged?.call(otp);
              
              // Check if all fields are filled
              if (otp.length == length) {
                onCompleted(otp);
              }
            },
          ),
        ),
      ),
    );
  }
}

class PinTextField extends StatelessWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool autofocus;
  
  const PinTextField({
    Key? key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<FocusNode> focusNodes = List.generate(length, (_) => FocusNode());
    final List<TextEditingController> controllers = List.generate(length, (_) => TextEditingController());
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            autofocus: autofocus && index == 0,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: true,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.isNotEmpty) {
                // Move to next field
                if (index < length - 1) {
                  focusNodes[index + 1].requestFocus();
                } else {
                  // Last field, unfocus
                  focusNodes[index].unfocus();
                }
              }
              
              // Collect all values
              final pin = controllers.map((controller) => controller.text).join();
              onChanged?.call(pin);
              
              // Check if all fields are filled
              if (pin.length == length) {
                onCompleted(pin);
              }
            },
          ),
        ),
      ),
    );
  }
}