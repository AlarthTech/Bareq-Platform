import 'package:flutter/material.dart';

import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/phone_input_constraints.dart';

class PhoneFormField extends StatelessWidget {
  const PhoneFormField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isRTL = l10n?.isRTL ?? false;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      enabled: enabled,
      autofocus: autofocus,
      maxLength: PhoneInputConstraints.maxLength,
      inputFormatters: PhoneInputConstraints.formatters,
      decoration: InputDecoration(
        labelText: l10n?.translate('phoneNumber') ?? 'Phone number',
        hintText: l10n?.translate('phoneNumberHint') ?? 'e.g. 0912345678',
        prefixIcon: const Icon(Icons.phone_outlined),
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      validator: (value) => PhoneInputConstraints.validate(
        value,
        requiredMessage:
            l10n?.translate('phoneRequired') ?? 'Phone number is required',
        invalidMessage:
            l10n?.translate('phoneInvalid') ?? 'Please enter a valid phone number',
      ),
    );
  }
}
