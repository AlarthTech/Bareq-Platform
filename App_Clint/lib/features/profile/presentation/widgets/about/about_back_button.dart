import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/about_screen_constants.dart';
import '../../../../../core/widgets/common/app_back_button.dart';

class AboutBackButton extends StatelessWidget {
  const AboutBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: AppBackButton(
        onPressed: () => context.pop(),
        textColor: AboutScreenConstants.textMuted,
      ),
    );
  }
}
