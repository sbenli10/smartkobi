import 'package:flutter/material.dart';

import 'dashboard_summary_model.dart';

class DashboardDailyAction {
  const DashboardDailyAction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.module,
    required this.actionLabel,
    required this.icon,
    required this.riskLevel,
    required this.recommendation,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String module;
  final String actionLabel;
  final IconData icon;
  final String riskLevel;
  final String recommendation;
}

List<DashboardDailyAction> buildDailyActions(DashboardSummary summary) {
  if (summary.shouldShowOnboarding) {
    return const [
      DashboardDailyAction(
        id: 'onboarding-income',
        title: 'İlk gelir/gider kaydınızı ekleyin',
        description: 'Finans hareketleri girildikçe günlük iş planı daha net oluşur.',
        category: 'Başlangıç',
        priority: 'medium',
        module: 'finance',
        actionLabel: 'Finans’a Git',
        icon: Icons.add_chart,
        riskLevel: 'medium',
        recommendation: 'Önce temel gelir ve gider kayıtlarını ekleyin.',
      ),
      DashboardDailyAction(
        id: 'onboarding-customer',
        title: 'İlk müşterinizi ekleyin',
        description: 'Cari ve tahsilat görünümü için müşteri kartları önemlidir.',
        category: 'Başlangıç',
        priority: 'medium',
        module: 'customers',
        actionLabel: 'Cari’ye Git',
        icon: Icons.person_add_alt_1,
        riskLevel: 'medium',
        recommendation: 'Tahsilat takibi için müşteri listenizi oluşturmaya başlayın.',
      ),
      DashboardDailyAction(
        id: 'onboarding-product',
        title: 'İlk ürününüzü ekleyin',
        description: 'Stok uyarıları ürün kartları oluştukça anlam kazanır.',
        category: 'Başlangıç',
        priority: 'low',
        module: 'inventory',
        actionLabel: 'Stok’a Git',
        icon: Icons.add_box_outlined,
        riskLevel: 'low',
        recommendation: 'Satan ürünlerinizi ve minimum stok seviyelerini tanımlayın.',
      ),
    ];
  }

  final actions = <DashboardDailyAction>[];

  if (summary.overdueReceivables > 0) {
    actions.add(
      const DashboardDailyAction(
        id: 'overdue-receivables',
        title: 'Geciken tahsilatları kontrol edin',
        description: 'Vadesi geçmiş alacaklar nakit akışınızı etkileyebilir.',
        category: 'Tahsilat',
        priority: 'high',
        module: 'customers',
        actionLabel: 'Cari’ye Git',
        icon: Icons.request_quote_outlined,
        riskLevel: 'high',
        recommendation: 'Önce vadesi geçmiş ve bakiyesi yüksek müşterilerle başlayın.',
      ),
    );
  }

  if (summary.upcomingPayments7d > 0) {
    actions.add(
      const DashboardDailyAction(
        id: 'upcoming-payments',
        title: 'Yaklaşan ödemeleri planlayın',
        description: 'Önümüzdeki 7 gün içindeki ödemeler için nakit planı yapın.',
        category: 'Ödeme',
        priority: 'high',
        module: 'cashflow',
        actionLabel: 'Nakit AI’a Git',
        icon: Icons.calendar_month_outlined,
        riskLevel: 'high',
        recommendation: 'Tahsilat tarihleriyle ödeme takvimini birlikte gözden geçirin.',
      ),
    );
  }

  if (summary.cashScore < 60) {
    actions.add(
      const DashboardDailyAction(
        id: 'cash-risk',
        title: 'Nakit riskini kontrol edin',
        description: 'Kısa vadeli nakit görünümü dikkat gerektiriyor.',
        category: 'Nakit',
        priority: 'high',
        module: 'cashflow',
        actionLabel: 'Nakit AI’a Git',
        icon: Icons.waterfall_chart_outlined,
        riskLevel: 'high',
        recommendation: 'Yeni harcamaları net tahsilat görünümü olmadan ertelemek daha güvenli olabilir.',
      ),
    );
  }

  if (summary.criticalStockCount > 0 || summary.outOfStockCount > 0) {
    actions.add(
      const DashboardDailyAction(
        id: 'critical-stock',
        title: 'Kritik stoktaki ürünleri tamamlayın',
        description: 'Satış kaybı yaşamamak için kritik ürünleri kontrol edin.',
        category: 'Stok',
        priority: 'medium',
        module: 'inventory',
        actionLabel: 'Stok’a Git',
        icon: Icons.inventory_2_outlined,
        riskLevel: 'medium',
        recommendation: 'Önce kritik stokta veya tükenen ürünleri sipariş planına alın.',
      ),
    );
  }

  if (summary.highPriorityMissingDocuments > 0 || summary.missingDocumentsCount > 0) {
    actions.add(
      const DashboardDailyAction(
        id: 'missing-documents',
        title: 'Eksik belgeleri tamamlayın',
        description: 'Destek başvuruları için belge hazırlık durumunuzu kontrol edin.',
        category: 'Belge',
        priority: 'medium',
        module: 'documents',
        actionLabel: 'Belgeler’e Git',
        icon: Icons.folder_open_outlined,
        riskLevel: 'medium',
        recommendation: 'Önce yüksek öncelikli eksik belgeleri tamamlamanız önerilir.',
      ),
    );
  }

  if (summary.profileCompletion < 70) {
    actions.add(
      const DashboardDailyAction(
        id: 'profile-completion',
        title: 'İşletme profilinizi tamamlayın',
        description: 'AI ve destek analizleri için birkaç bilgi daha gerekiyor.',
        category: 'Profil',
        priority: 'medium',
        module: 'profile',
        actionLabel: 'Profili Tamamla',
        icon: Icons.business_center_outlined,
        riskLevel: 'medium',
        recommendation: 'Sektör, NACE ve ihtiyaç alanlarını doldurmanız önerilir.',
      ),
    );
  }

  return actions.take(5).toList();
}
