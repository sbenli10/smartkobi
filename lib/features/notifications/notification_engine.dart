import '../../data/models/notification_preferences_model.dart';

class NotificationDraft {
  const NotificationDraft({
    required this.title,
    required this.message,
    required this.notificationType,
    required this.priority,
    required this.sourceModule,
    required this.actionRoute,
    required this.actionLabel,
    required this.metadata,
    this.scheduledFor,
    this.expiresAt,
    this.sourceId,
  });

  final String title;
  final String message;
  final String notificationType;
  final String priority;
  final String sourceModule;
  final String actionRoute;
  final String actionLabel;
  final String? sourceId;
  final Map<String, dynamic> metadata;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;
}

class NotificationDataSnapshot {
  const NotificationDataSnapshot({
    required this.overdueCollectionCount,
    required this.upcomingCollectionCount,
    required this.upcomingPaymentCount,
    required this.cashScore,
    required this.netCash30d,
    required this.criticalStockCount,
    required this.outOfStockCount,
    required this.expiringDocumentCount,
    required this.expiredDocumentCount,
    required this.highPriorityMissingDocumentCount,
    required this.hasSupportAnalysis,
    required this.supportAnalysisUpdatedAt,
    required this.profileCompletion,
    required this.hasRecentReport,
    required this.latestDailyPlanDate,
  });

  final int overdueCollectionCount;
  final int upcomingCollectionCount;
  final int upcomingPaymentCount;
  final int cashScore;
  final double netCash30d;
  final int criticalStockCount;
  final int outOfStockCount;
  final int expiringDocumentCount;
  final int expiredDocumentCount;
  final int highPriorityMissingDocumentCount;
  final bool hasSupportAnalysis;
  final DateTime? supportAnalysisUpdatedAt;
  final int profileCompletion;
  final bool hasRecentReport;
  final DateTime? latestDailyPlanDate;
}

Future<List<NotificationDraft>> buildSmartReminderDrafts({
  required String userId,
  required NotificationDataSnapshot snapshot,
  required NotificationPreferencesModel preferences,
}) async {
  final now = DateTime.now();
  final todayKey = _dateKey(now);
  final drafts = <NotificationDraft>[];

  if (preferences.collectionEnabled && snapshot.overdueCollectionCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Geciken tahsilat var',
        message: 'Vadesi geçmiş tahsilatlar nakit akışınızı etkileyebilir. Cari ekranından kontrol edebilirsiniz.',
        notificationType: 'collection',
        priority: 'high',
        sourceModule: 'customers',
        actionRoute: 'customers',
        actionLabel: 'Cari’ye Git',
        metadata: {
          'rule_key': 'overdue_collections',
          'generated_date': todayKey,
          'count': snapshot.overdueCollectionCount,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.collectionEnabled && snapshot.upcomingCollectionCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Yaklaşan tahsilatlarınızı kontrol edin',
        message: 'Önümüzdeki birkaç gün içinde beklenen tahsilatlarınız var. Tahsilat planınızı gözden geçirebilirsiniz.',
        notificationType: 'collection',
        priority: 'medium',
        sourceModule: 'customers',
        actionRoute: 'customers',
        actionLabel: 'Cari’ye Git',
        metadata: {
          'rule_key': 'upcoming_collections',
          'generated_date': todayKey,
          'count': snapshot.upcomingCollectionCount,
          'user_id': userId,
        },
      ),
    );
  }

  if ((preferences.paymentEnabled || preferences.cashflowEnabled) &&
      snapshot.upcomingPaymentCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Yaklaşan ödemeleri planlayın',
        message: 'Önümüzdeki 7 gün içinde ödeme planı yapmanız gerekebilir. Nakit akışı ekranından kontrol edebilirsiniz.',
        notificationType: 'payment',
        priority: snapshot.upcomingPaymentCount >= 3 ? 'high' : 'medium',
        sourceModule: 'cashflow',
        actionRoute: 'cashflow',
        actionLabel: 'Nakit AI’a Git',
        metadata: {
          'rule_key': 'upcoming_payments',
          'generated_date': todayKey,
          'count': snapshot.upcomingPaymentCount,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.cashflowEnabled &&
      (snapshot.cashScore < 60 || snapshot.netCash30d < 0)) {
    drafts.add(
      NotificationDraft(
        title: 'Nakit akışınız dikkat gerektiriyor',
        message: 'Kısa vadeli nakit görünümü riskli olabilir. Nakit AI ekranında 30 günlük tahmini inceleyin.',
        notificationType: 'cashflow',
        priority: snapshot.cashScore < 40 || snapshot.netCash30d < 0 ? 'high' : 'medium',
        sourceModule: 'cashflow',
        actionRoute: 'cashflow',
        actionLabel: 'Nakit AI’a Git',
        metadata: {
          'rule_key': 'cashflow_risk',
          'generated_date': todayKey,
          'cash_score': snapshot.cashScore,
          'net_cash_30d': snapshot.netCash30d,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.inventoryEnabled && snapshot.criticalStockCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Kritik stoktaki ürünleri kontrol edin',
        message: 'Minimum seviyeye inen ürünler satış ve teslimat akışını etkileyebilir.',
        notificationType: 'inventory',
        priority: snapshot.criticalStockCount >= 5 ? 'high' : 'medium',
        sourceModule: 'inventory',
        actionRoute: 'inventory',
        actionLabel: 'Stok’a Git',
        metadata: {
          'rule_key': 'critical_inventory',
          'generated_date': todayKey,
          'count': snapshot.criticalStockCount,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.inventoryEnabled && snapshot.outOfStockCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Stokta olmayan ürünler var',
        message: 'Stokta tükenen ürünler siparişlerinizi etkileyebilir. Stok ekranından kontrol edin.',
        notificationType: 'inventory',
        priority: 'high',
        sourceModule: 'inventory',
        actionRoute: 'inventory',
        actionLabel: 'Stok’a Git',
        metadata: {
          'rule_key': 'out_of_stock_inventory',
          'generated_date': todayKey,
          'count': snapshot.outOfStockCount,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.documentEnabled && snapshot.expiringDocumentCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Süresi yaklaşan belgeleriniz var',
        message: 'Belge sürelerini erkenden yenilemek destek ve başvuru süreçlerini kolaylaştırır.',
        notificationType: 'document',
        priority: 'medium',
        sourceModule: 'documents',
        actionRoute: 'documents',
        actionLabel: 'Belgeler’e Git',
        metadata: {
          'rule_key': 'expiring_documents',
          'generated_date': todayKey,
          'count': snapshot.expiringDocumentCount,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.documentEnabled && snapshot.expiredDocumentCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Süresi geçmiş belgeleriniz var',
        message: 'Süresi dolan belgeler başvuru ve operasyon süreçlerinizi aksatabilir.',
        notificationType: 'document',
        priority: 'high',
        sourceModule: 'documents',
        actionRoute: 'documents',
        actionLabel: 'Belgeler’e Git',
        metadata: {
          'rule_key': 'expired_documents',
          'generated_date': todayKey,
          'count': snapshot.expiredDocumentCount,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.documentEnabled &&
      snapshot.highPriorityMissingDocumentCount > 0) {
    drafts.add(
      NotificationDraft(
        title: 'Yüksek öncelikli eksik belgeleriniz var',
        message: 'Eksik belgeleri tamamlamak destek ve rapor çıktılarının kalitesini artırır.',
        notificationType: 'document',
        priority: 'high',
        sourceModule: 'documents',
        actionRoute: 'documents',
        actionLabel: 'Belgeler’e Git',
        metadata: {
          'rule_key': 'missing_high_priority_documents',
          'generated_date': todayKey,
          'count': snapshot.highPriorityMissingDocumentCount,
          'user_id': userId,
        },
      ),
    );
  }

  final supportAgeDays = snapshot.supportAnalysisUpdatedAt == null
      ? 999
      : now.difference(snapshot.supportAnalysisUpdatedAt!).inDays;
  if (preferences.supportEnabled &&
      (!snapshot.hasSupportAnalysis || supportAgeDays >= 14)) {
    drafts.add(
      NotificationDraft(
        title: 'Destek analizinizi güncelleyebilirsiniz',
        message: 'Güncel profil ve belge verileriyle destek fırsatlarını yeniden değerlendirmek faydalı olabilir.',
        notificationType: 'support',
        priority: snapshot.hasSupportAnalysis ? 'low' : 'medium',
        sourceModule: 'support',
        actionRoute: 'support',
        actionLabel: 'Destek Analizi’ne Git',
        metadata: {
          'rule_key': 'support_analysis_refresh',
          'generated_date': todayKey,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.profileEnabled && snapshot.profileCompletion < 70) {
    drafts.add(
      NotificationDraft(
        title: 'İşletme profilinizi tamamlayın',
        message: 'İşletme profiliniz güçlendikçe destek analizi ve akıllı öneriler daha isabetli olur.',
        notificationType: 'profile',
        priority: 'medium',
        sourceModule: 'business_profile',
        actionRoute: 'business_profile',
        actionLabel: 'İşletme Profili’ne Git',
        metadata: {
          'rule_key': 'profile_completion',
          'generated_date': todayKey,
          'profile_completion': snapshot.profileCompletion,
          'user_id': userId,
        },
      ),
    );
  }

  if (preferences.reportEnabled && !snapshot.hasRecentReport) {
    drafts.add(
      NotificationDraft(
        title: 'Bu hafta için KOBİ Sağlık Raporu oluşturabilirsiniz',
        message: 'İşletmenizin genel durumunu tek çıktıda görmek için haftalık rapor oluşturmanız önerilir.',
        notificationType: 'report',
        priority: 'low',
        sourceModule: 'reports',
        actionRoute: 'reports',
        actionLabel: 'Raporlar’a Git',
        metadata: {
          'rule_key': 'weekly_report_reminder',
          'generated_date': todayKey,
          'user_id': userId,
        },
      ),
    );
  }

  final needsDailyPlan = snapshot.latestDailyPlanDate == null ||
      _dateKey(snapshot.latestDailyPlanDate!) != todayKey;
  if (preferences.dailyPlanEnabled && needsDailyPlan) {
    drafts.add(
      NotificationDraft(
        title: 'Bugünkü iş planınız hazır',
        message: 'Tahsilat, ödeme, stok ve belge uyarılarınızı bugün için tek listede kontrol edin.',
        notificationType: 'daily_plan',
        priority: 'medium',
        sourceModule: 'dashboard',
        actionRoute: 'dashboard',
        actionLabel: 'Ana Sayfa’ya Git',
        metadata: {
          'rule_key': 'daily_plan',
          'generated_date': todayKey,
          'user_id': userId,
        },
        scheduledFor: DateTime(now.year, now.month, now.day, 9),
        expiresAt: DateTime(now.year, now.month, now.day, 23, 59),
      ),
    );
  }

  return drafts;
}

String _dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
