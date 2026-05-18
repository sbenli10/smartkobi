import 'dart:ui';
import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_page.dart';
import '../features/transactions/transactions_page.dart';
import '../features/customers/customers_page.dart';
import '../features/inventory/inventory_page.dart';
import '../features/kpi/kpi_page.dart';
import '../features/ai/ai_page.dart';
import '../features/ai/cashflow_page.dart';
import '../features/ai/ai_chat_page.dart';


class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _index = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    TransactionsPage(),
    CustomersPage(),
    InventoryPage(),
    KpiPage(),
    AiPage(),
    CashflowPage(),
    AiChatPage(), // ✅ BURAYA EKLE
  ];





  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fadeCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Breakpoints: phone < 840, tablet/desktop >= 840
        final bool wide = w >= 840;

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              // ✅ Enterprise gradient background
              _EnterpriseBackground(wide: wide),

              SafeArea(
                child: Row(
                  children: [
                    if (wide) _EnterpriseRail(
                      selectedIndex: _index,
                      onSelect: (i) => setState(() => _index = i),
                    ),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 16 : 12,
                          12,
                          wide ? 20 : 12,
                          wide ? 12 : 96, // bottom bar için boşluk
                        ),
                        child: _EnterpriseCardShell(
                          child: FadeTransition(
                            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
                            child: IndexedStack(
                              index: _index,
                              children: _pages,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ✅ Phone/compact: glass bottom bar
          bottomNavigationBar: wide
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: _GlassBottomBar(
                    selectedIndex: _index,
                    onSelect: (i) => setState(() => _index = i),
                    accent: cs.primary,
                  ),
                ),
        );
      },
    );
  }
}

class _EnterpriseBackground extends StatelessWidget {
  const _EnterpriseBackground({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Kurumsal, “fintech” hissi veren soft gradient + vignette
    final top = isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F7FB);
    final mid = isDark ? const Color(0xFF0E1A33) : const Color(0xFFEFF3FF);
    final glow = isDark ? const Color(0xFF1D4ED8) : const Color(0xFF93C5FD);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [top, mid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // “glow blobs”
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(color: glow.withOpacity(isDark ? 0.22 : 0.28), size: wide ? 320 : 260),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _GlowBlob(color: glow.withOpacity(isDark ? 0.18 : 0.22), size: wide ? 360 : 280),
          ),
          // subtle vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.35 : 0.10),
                  ],
                  radius: 1.1,
                  center: const Alignment(0.0, -0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// ✅ Enterprise content shell: card + stroke + blur hint
class _EnterpriseCardShell extends StatelessWidget {
  const _EnterpriseCardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0F1A2E) : Colors.white).withOpacity(isDark ? 0.55 : 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ✅ Tablet/Desktop: NavigationRail (ERP tarzı)
class _EnterpriseRail extends StatelessWidget {
  const _EnterpriseRail({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 96,
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0F1A2E) : Colors.white).withOpacity(isDark ? 0.50 : 0.70),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.transparent,
              selectedIconTheme: IconThemeData(color: cs.primary),
              selectedLabelTextStyle: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
              unselectedIconTheme: IconThemeData(color: cs.onSurface.withOpacity(0.65)),
              unselectedLabelTextStyle: TextStyle(
                color: cs.onSurface.withOpacity(0.65),
                fontWeight: FontWeight.w600,
              ),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text("Dashboard"),
                ),
                NavigationRailDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet),
                    label: Text("Gelir-Gider"),
                ),
                NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text("Müşteriler"),
                ),
                NavigationRailDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory),
                    label: Text("Stok"),
                ),
                NavigationRailDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: Text("KPI"),
                ),
                NavigationRailDestination( // ✅ yeni
                    icon: Icon(Icons.smart_toy_outlined),
                    selectedIcon: Icon(Icons.smart_toy),
                    label: Text("AI"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.trending_up_outlined),
                  selectedIcon: Icon(Icons.trending_up),
                  label: Text("Nakit AI"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: Text("AI Chat"),
                ),
                ],

            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Phone: Glassmorphism BottomBar (ERP/Fintech premium)
class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.accent,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color accent;

 static const _items = <({IconData icon, String label})>[
  (icon: Icons.dashboard, label: "Dashboard"),
  (icon: Icons.account_balance_wallet, label: "Gelir-Gider"),
  (icon: Icons.people, label: "Müşteriler"),
  (icon: Icons.inventory, label: "Stok"),
  (icon: Icons.insights, label: "KPI"),
  (icon: Icons.smart_toy, label: "AI"),
  (icon: Icons.trending_up, label: "Nakit AI"),
  (icon: Icons.chat_bubble, label: "AI Chat"), // ✅ EKLE
];




  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0B1220) : Colors.white).withOpacity(isDark ? 0.55 : 0.70),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.12 : 0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                blurRadius: 26,
                offset: const Offset(0, 14),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = selectedIndex == i;
              final item = _items[i];

              return InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 14 : 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? accent.withOpacity(isDark ? 0.35 : 0.16) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected
                            ? accent
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.70),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
