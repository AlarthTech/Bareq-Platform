import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;

/// Main entry point of the Bareq application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use bundled Almarai (assets/fonts) — no runtime fetch from fonts.gstatic.com.
  GoogleFonts.config.allowRuntimeFetching = false;

  await di.init();

  runApp(const BareqApp());
}
