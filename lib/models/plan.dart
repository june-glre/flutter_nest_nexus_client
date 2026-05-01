/// Plan(요금제)의 청구 주기.
///
/// 백엔드의 `BillingPeriod` enum과 1:1 매핑.
enum BillingPeriod {
  monthly,
  yearly,
  lifetime,
  none;

  static BillingPeriod fromString(String? raw) {
    switch (raw) {
      case 'monthly':
        return BillingPeriod.monthly;
      case 'yearly':
        return BillingPeriod.yearly;
      case 'lifetime':
        return BillingPeriod.lifetime;
      case 'none':
      default:
        return BillingPeriod.none;
    }
  }
}

/// nest-nexus의 구독 Plan(요금제) 표현. 클라이언트는 안정 키 [code]로 plan을 식별.
///
/// `features`는 백엔드와 공유되는 free-form 권한 매핑(예: `{"tier": "premium"}`).
/// 클라이언트 UI에서 직접 참조해 권한별 분기에 사용할 수 있다.
class Plan {
  /// 안정 식별자(예: `pro_monthly`). 가격이 바뀌면 새 plan이 만들어지므로
  /// 코드 자체가 가격 정책의 버전 역할을 한다.
  final String code;
  final String name;
  final String? description;

  /// 표시용 가격(센트). 실제 결제 금액은 스토어 통화 표기를 우선한다.
  final int priceCents;

  /// ISO 4217 통화 코드.
  final String currency;

  final BillingPeriod billingPeriod;

  /// Google Play Console에 등록된 product ID. null이면 본 plan은 Android에서 노출되지 않음.
  final String? googlePlayProductId;

  /// App Store Connect에 등록된 product ID.
  final String? appStoreProductId;

  /// 권한/한도 매핑(자유 형식).
  final Map<String, dynamic> features;

  /// 정렬용 가중치(작을수록 위).
  final int sortOrder;

  const Plan({
    required this.code,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.billingPeriod,
    required this.googlePlayProductId,
    required this.appStoreProductId,
    required this.features,
    required this.sortOrder,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        priceCents: (json['priceCents'] as num).toInt(),
        currency: json['currency'] as String? ?? 'USD',
        billingPeriod: BillingPeriod.fromString(json['billingPeriod'] as String?),
        googlePlayProductId: json['googlePlayProductId'] as String?,
        appStoreProductId: json['appStoreProductId'] as String?,
        features: (json['features'] as Map?)?.cast<String, dynamic>() ?? const {},
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() => 'Plan($code, $billingPeriod, ${priceCents}c)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Plan && other.code == code);

  @override
  int get hashCode => code.hashCode;
}
