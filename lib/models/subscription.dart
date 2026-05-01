/// 구독 플랫폼.
///
/// 백엔드 `SubscriptionPlatform` enum과 1:1 매핑.
enum SubscriptionPlatform {
  android,
  ios,
  system;

  String get wireValue {
    switch (this) {
      case SubscriptionPlatform.android:
        return 'android';
      case SubscriptionPlatform.ios:
        return 'ios';
      case SubscriptionPlatform.system:
        return 'system';
    }
  }

  static SubscriptionPlatform fromString(String? raw) {
    switch (raw) {
      case 'android':
        return SubscriptionPlatform.android;
      case 'ios':
        return SubscriptionPlatform.ios;
      case 'system':
      default:
        return SubscriptionPlatform.system;
    }
  }
}

/// 구독 상태.
///
/// `free`는 활성 구독이 없는 상태 — 백엔드가 응답을 표준화하기 위해 사용하는 값.
enum SubscriptionStatus {
  active,
  inGracePeriod,
  onHold,
  paused,
  cancelled,
  expired,
  pending,
  free;

  /// 사용자에게 권한이 부여되어야 하는 상태인지.
  bool get isEntitled =>
      this == SubscriptionStatus.active ||
      this == SubscriptionStatus.inGracePeriod ||
      this == SubscriptionStatus.cancelled; // 만료 전까지 entitled

  static SubscriptionStatus fromString(String? raw) {
    switch (raw) {
      case 'active':
        return SubscriptionStatus.active;
      case 'in_grace_period':
        return SubscriptionStatus.inGracePeriod;
      case 'on_hold':
        return SubscriptionStatus.onHold;
      case 'paused':
        return SubscriptionStatus.paused;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'free':
      default:
        return SubscriptionStatus.free;
    }
  }
}

/// nest-nexus의 사용자 구독 응답.
///
/// 활성 구독이 없으면 [planCode]=`'free'`, [status]=[SubscriptionStatus.free],
/// [id]=null인 응답이 온다 — 클라이언트는 항상 같은 모양의 객체를 받는다.
class Subscription {
  /// 활성 구독이 있을 때만 채워짐.
  final String? id;

  final String planCode;
  final SubscriptionStatus status;
  final SubscriptionPlatform platform;
  final String? productId;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool autoRenewing;

  const Subscription({
    required this.id,
    required this.planCode,
    required this.status,
    required this.platform,
    required this.productId,
    required this.startedAt,
    required this.expiresAt,
    required this.autoRenewing,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String?,
        planCode: json['planCode'] as String,
        status: SubscriptionStatus.fromString(json['status'] as String?),
        platform:
            SubscriptionPlatform.fromString(json['platform'] as String?),
        productId: json['productId'] as String?,
        startedAt: _parseDate(json['startedAt']),
        expiresAt: _parseDate(json['expiresAt']),
        autoRenewing: (json['autoRenewing'] as bool?) ?? false,
      );

  /// 활성 구독이 없는 사용자(free tier) 응답을 의미. 백엔드가 명시적으로 free
  /// 응답을 보내올 때만 true.
  bool get isFreeTier => status == SubscriptionStatus.free;

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  @override
  String toString() => 'Subscription($planCode, $status)';
}
