enum AdvisorScopeDecision {
  inScope,
  outOfScope,
  ambiguous,
}

enum AdvisorTopic {
  generalBusiness,
  finance,
  cashflow,
  customers,
  inventory,
  support,
  sales,
  pricing,
  tax,
  documents,
  reporting,
  outOfScope,
}

class AdvisorScopeResult {
  const AdvisorScopeResult({
    required this.decision,
    required this.topic,
    required this.confidence,
    required this.reason,
  });

  final AdvisorScopeDecision decision;
  final AdvisorTopic topic;
  final double confidence;
  final String reason;
}

AdvisorScopeResult classifyAdvisorQuestion(String question) {
  final normalized = normalizeQuestion(question);
  if (normalized.isEmpty) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.ambiguous,
      topic: AdvisorTopic.generalBusiness,
      confidence: 0.30,
      reason: 'Soru çok kısa veya belirsiz.',
    );
  }

  if (_containsAny(normalized, _strongCustomerPhrases)) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.inScope,
      topic: AdvisorTopic.customers,
      confidence: 0.95,
      reason: 'Cari, müşteri veya tahsilat sorusu.',
    );
  }

  if (_containsAny(normalized, _strongCashflowPhrases)) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.inScope,
      topic: AdvisorTopic.cashflow,
      confidence: 0.93,
      reason: 'Nakit akışı, harcama veya yatırım kararı sorusu.',
    );
  }

  if (_containsAny(normalized, _strongInventoryPhrases)) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.inScope,
      topic: AdvisorTopic.inventory,
      confidence: 0.93,
      reason: 'Stok, ürün veya tedarik sorusu.',
    );
  }

  if (_containsAny(normalized, _strongSupportPhrases)) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.inScope,
      topic: AdvisorTopic.support,
      confidence: 0.93,
      reason: 'Destek, teşvik veya başvuru hazırlığı sorusu.',
    );
  }

  if (_containsAny(normalized, _strongFinancePhrases)) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.inScope,
      topic: AdvisorTopic.finance,
      confidence: 0.91,
      reason: 'Finans, gelir-gider, maliyet veya kârlılık sorusu.',
    );
  }

  final strongBusinessMatch = _containsAny(normalized, _strongBusinessKeywords);
  if (strongBusinessMatch) {
    return AdvisorScopeResult(
      decision: AdvisorScopeDecision.inScope,
      topic: _detectTopic(normalized),
      confidence: 0.88,
      reason: 'Güçlü işletme anahtar kelimeleri bulundu.',
    );
  }

  if (_containsAny(normalized, _outOfScopePhrases) ||
      _containsAny(normalized, _outOfScopeKeywords)) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.outOfScope,
      topic: AdvisorTopic.outOfScope,
      confidence: 0.92,
      reason: 'Soru kişisel, eğlence, sağlık veya gündelik yaşam kapsamına giriyor.',
    );
  }

  if (_containsAny(normalized, _ambiguousPurchasePhrases)) {
    return const AdvisorScopeResult(
      decision: AdvisorScopeDecision.ambiguous,
      topic: AdvisorTopic.generalBusiness,
      confidence: 0.60,
      reason: 'Soru alım veya karar içeriyor ancak işletme bağlamı net değil.',
    );
  }

  return const AdvisorScopeResult(
    decision: AdvisorScopeDecision.outOfScope,
    topic: AdvisorTopic.outOfScope,
    confidence: 0.70,
    reason: 'Soru SmartKOBİ kapsamındaki işletme yönetimi alanlarına bağlanmıyor.',
  );
}

String normalizeQuestion(String input) {
  return input
      .toLowerCase()
      .trim()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String advisorTopicToModule(AdvisorTopic topic) {
  switch (topic) {
    case AdvisorTopic.customers:
      return 'customers';
    case AdvisorTopic.cashflow:
      return 'cashflow';
    case AdvisorTopic.inventory:
      return 'inventory';
    case AdvisorTopic.support:
    case AdvisorTopic.documents:
      return 'support';
    case AdvisorTopic.finance:
    case AdvisorTopic.sales:
    case AdvisorTopic.pricing:
    case AdvisorTopic.tax:
      return 'finance';
    case AdvisorTopic.reporting:
      return 'reports';
    case AdvisorTopic.generalBusiness:
    case AdvisorTopic.outOfScope:
      return 'general';
  }
}

AdvisorTopic _detectTopic(String normalized) {
  if (_containsAny(normalized, _strongCustomerPhrases)) {
    return AdvisorTopic.customers;
  }
  if (_containsAny(normalized, _strongCashflowPhrases)) {
    return AdvisorTopic.cashflow;
  }
  if (_containsAny(normalized, _strongInventoryPhrases)) {
    return AdvisorTopic.inventory;
  }
  if (_containsAny(normalized, _strongSupportPhrases)) {
    return AdvisorTopic.support;
  }
  if (_containsAny(normalized, _salesKeywords)) {
    return normalized.contains('fiyat') ||
            normalized.contains('zam') ||
            normalized.contains('iskonto')
        ? AdvisorTopic.pricing
        : AdvisorTopic.sales;
  }
  if (_containsAny(normalized, _taxKeywords)) {
    return AdvisorTopic.tax;
  }
  if (_containsAny(normalized, _documentKeywords)) {
    return AdvisorTopic.documents;
  }
  if (_containsAny(normalized, _reportingKeywords)) {
    return AdvisorTopic.reporting;
  }
  return AdvisorTopic.finance;
}

bool _containsAny(String normalized, Set<String> values) {
  for (final value in values) {
    if (normalized.contains(value)) {
      return true;
    }
  }
  return false;
}

const Set<String> _strongCustomerPhrases = {
  'kimden tahsilat yapmaliyim',
  'hangi musteriden tahsilat istemeliyim',
  'tahsilat onceligim kim olmali',
  'geciken tahsilatlarim var mi',
  'kim bana borclu',
  'cari risklerim neler',
  'hangi musteri riskli',
  'tahsilat',
  'alacak',
  'borc',
  'cari',
  'musteri',
  'geciken odeme',
  'geciken tahsilat',
  'borclu',
  'odeme hatirlatma',
};

const Set<String> _strongCashflowPhrases = {
  'nakit',
  'nakit akisi',
  'odeme yapabilir miyim',
  'beni zorlar mi',
  'harcama',
  'makine',
  'ekipman',
  'yatirim',
  'kredi',
  'finansman',
  'bu ay 15 bin tl makine alirsam beni zorlar mi',
  'bu harcamayi yapabilir miyim',
};

const Set<String> _strongInventoryPhrases = {
  'stok',
  'urun',
  'kritik stok',
  'tedarik',
  'barkod',
  'siparis',
  'hangi urunler kritik stokta',
};

const Set<String> _strongSupportPhrases = {
  'kosgeb',
  'destek',
  'tesvik',
  'tubitak',
  'eximbank',
  'hibe',
  'nace',
  'belge',
  'kapasite raporu',
  'ihracat',
};

const Set<String> _strongFinancePhrases = {
  'gelir',
  'gider',
  'kar',
  'zarar',
  'ciro',
  'maliyet',
  'fiyat',
  'zam',
  'iskonto',
  'vergi',
  'rapor',
  'isletme',
  'kobi',
};

const Set<String> _strongBusinessKeywords = {
  'tahsilat',
  'alacak',
  'borc',
  'cari',
  'musteri',
  'odeme',
  'geciken odeme',
  'geciken tahsilat',
  'fatura',
  'gelir',
  'gider',
  'kar',
  'zarar',
  'nakit',
  'nakit akisi',
  'stok',
  'urun',
  'tedarik',
  'satis',
  'ciro',
  'maliyet',
  'fiyat',
  'zam',
  'iskonto',
  'destek',
  'tesvik',
  'kosgeb',
  'tubitak',
  'eximbank',
  'ihracat',
  'b2b',
  'kredi',
  'finansman',
  'vergi',
  'rapor',
  'belge',
  'makine',
  'ekipman',
  'yatirim',
  'harcama',
  'isletme',
  'kobi',
};

const Set<String> _outOfScopeKeywords = {
  'sevgili',
  'iliski',
  'flort',
  'arkadas',
  'aile',
  'yemek',
  'tarif',
  'tatil',
  'moda',
  'hobi',
  'ev isi',
  'mac',
  'futbol',
  'dizi',
  'film',
  'magazin',
  'oyun',
  'sarki',
  'siir',
  'hikaye',
  'siyasi',
  'parti',
  'ideoloji',
  'hastalik',
  'ilac',
  'teshis',
  'tedavi',
  'doz',
  'saglik',
  'odev',
  'kompozisyon',
  'tarih',
  'felsefe',
};

const Set<String> _outOfScopePhrases = {
  'bugun ne yemek yapayim',
  'sevgilime mesaj yaz',
  'iliski mesaji',
  'mac tahmini',
  'siyasi tartisma',
  'ilac tavsiyesi',
  'siir yaz',
  'hikaye yaz',
};

const Set<String> _ambiguousPurchasePhrases = {
  'telefon alayim mi',
  'telefon almali miyim',
  'araba alayim mi',
  'araba almali miyim',
  'eleman alayim mi',
  'eleman almali miyim',
  'yeni bilgisayar alayim mi',
  'bilgisayar alayim mi',
  'telefon',
  'araba',
  'yeni bilgisayar',
};

const Set<String> _salesKeywords = {
  'satis',
  'teklif',
  'fiyat',
  'zam',
  'iskonto',
  'kampanya',
  'b2b',
};

const Set<String> _taxKeywords = {
  'vergi',
  'kdv',
  'stopaj',
  'muhtasar',
};

const Set<String> _documentKeywords = {
  'belge',
  'vergi levhasi',
  'faaliyet belgesi',
  'imza sirkuleri',
};

const Set<String> _reportingKeywords = {
  'rapor',
  'kpi',
  'performans',
};
