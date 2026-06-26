import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class HealthCertificatePickResult {
  const HealthCertificatePickResult({
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

class HealthCertificatePickerException implements Exception {
  HealthCertificatePickerException(this.message);
  final String message;
}

class HealthCertificatePicker {
  HealthCertificatePicker._();

  static const _maxBytes = 10 * 1024 * 1024;
  static const _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  static Future<HealthCertificatePickResult?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (file.size > _maxBytes) {
      throw HealthCertificatePickerException(
        'حجم الملف يجب ألا يتجاوز 10 ميغابايت',
      );
    }

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw HealthCertificatePickerException('تعذر قراءة الملف المختار');
      }
      return HealthCertificatePickResult(
        name: file.name,
        size: file.size,
        bytes: bytes,
      );
    }

    final path = file.path;
    if (path == null) {
      throw HealthCertificatePickerException('تعذر الوصول إلى الملف المختار');
    }
    return HealthCertificatePickResult(
      name: file.name,
      size: file.size,
      path: path,
    );
  }
}
