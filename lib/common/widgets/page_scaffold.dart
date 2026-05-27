import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 1200 ? 32.0 : width >= 900 ? 24.0 : 20.0;
    final topPadding = width >= 900 ? 24.0 : 20.0;
    final contentTopPadding = width >= 900 ? 12.0 : 8.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                12,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compactHeader = constraints.maxWidth < 720;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compactHeader && actions != null && actions!.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            Wrap(spacing: 8, runSpacing: 8, children: actions!),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (actions != null && actions!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Wrap(spacing: 8, runSpacing: 8, children: actions!),
                            ],
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  contentTopPadding,
                  horizontalPadding,
                  20,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
