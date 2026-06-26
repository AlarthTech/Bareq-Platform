import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/theme/app_theme.dart';

class CommercialRegisterPickResult {
  const CommercialRegisterPickResult({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
  });

  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;
}

class CommercialRegisterPicker extends StatelessWidget {
  const CommercialRegisterPicker({
    super.key,
    required this.fileName,
    required this.onPick,
    required this.onClear,
    this.enabled = true,
  });

  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  static const _maxBytes = 10 * 1024 * 1024;
  static const _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  static Future<CommercialRegisterPickResult?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (file.size > _maxBytes) {
      throw CommercialRegisterPickerException(
        'حجم الملف يجب ألا يتجاوز 10 ميغابايت',
      );
    }

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw CommercialRegisterPickerException('لم يتم قراءة الملف المختار');
      }
      return CommercialRegisterPickResult(
        name: file.name,
        size: file.size,
        bytes: bytes,
      );
    }

    final path = file.path;
    if (path == null) {
      throw CommercialRegisterPickerException('تعذر الوصول إلى الملف المختار');
    }
    return CommercialRegisterPickResult(
      name: file.name,
      size: file.size,
      path: path,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: ForgotPasswordConstants.tealPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: ForgotPasswordConstants.tealPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.upload_file_outlined,
                color: ForgotPasswordConstants.tealPrimary,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  'ملف السجل التجاري (موصى به)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ForgotPasswordConstants.tealDark,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'PDF أو JPG أو PNG — حتى 10 ميغابايت',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          if (fileName != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: enabled ? onClear : null,
                  icon: const Icon(Icons.close),
                  tooltip: 'إزالة الملف',
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
          ],
          OutlinedButton.icon(
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.attach_file),
            label: Text(fileName == null ? 'اختيار ملف' : 'تغيير الملف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ForgotPasswordConstants.tealPrimary,
              side: BorderSide(color: ForgotPasswordConstants.tealPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class CommercialRegisterPickerException implements Exception {
  CommercialRegisterPickerException(this.message);
  final String message;
}
