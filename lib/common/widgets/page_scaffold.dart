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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navy950, AppColors.navy900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 6),
                          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
