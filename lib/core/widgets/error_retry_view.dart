import 'package:flutter/material.dart';

import '../constants/app_text_styles.dart';
import '../utils/i18n/strings.g.dart';

class ErrorRetryView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorRetryView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.common.error, style: AppTextStyles.pageHeading),
            const SizedBox(height: 8),
            Text(error, style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(t.common.retry)),
          ],
        ),
      ),
    );
  }
}
