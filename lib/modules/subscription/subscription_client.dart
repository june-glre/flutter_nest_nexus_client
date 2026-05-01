import 'package:dio/dio.dart';

import '../../core/exception.dart';
import '../../models/subscription.dart';
import '../../utils/result.dart';

/// DI 및 테스트에서 [SubscriptionClient]와 [MockSubscriptionClient]를 교체할 수
/// 있게 하는 인터페이스.
abstract class SubscriptionClientBase {
  Future<Subscription> me();
  Future<Subscription> verify({
    required SubscriptionPlatform platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
    String? appId,
  });
  Future<List<Subscription>> restore({String? appId});

  Future<Result<Subscription>> meSafe();
  Future<Result<Subscription>> verifySafe({
    required SubscriptionPlatform platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
    String? appId,
  });
  Future<Result<List<Subscription>>> restoreSafe({String? appId});
}

/// `/v1/subscriptions/*` 엔드포인트 래퍼.
///
/// 모든 호출은 인증된 사용자를 전제로 한다 (AuthInterceptor가 Bearer 토큰 첨부).
/// `appId`는 백엔드의 Firebase custom claim 동기화 트리거 — 본 SDK가 Firebase를
/// 사용하지 않는 클라이언트에서는 null로 두면 된다.
class SubscriptionClient extends SubscriptionClientBase {
  final Dio _dio;

  SubscriptionClient(this._dio);

  @override
  Future<Subscription> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/subscriptions/me');
    final data = res.data;
    if (data == null) {
      throw const UnknownApiException(message: 'Empty subscription response');
    }
    return Subscription.fromJson(data);
  }

  @override
  Future<Subscription> verify({
    required SubscriptionPlatform platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
    String? appId,
  }) async {
    final body = <String, dynamic>{
      'platform': platform.wireValue,
      'productId': productId,
      if (purchaseToken != null) 'purchaseToken': purchaseToken,
      if (transactionId != null) 'transactionId': transactionId,
    };
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/subscriptions/verify',
      data: body,
      options: appId == null
          ? null
          : Options(headers: {'x-app-id': appId}),
    );
    final data = res.data;
    if (data == null) {
      throw const UnknownApiException(message: 'Empty verify response');
    }
    return Subscription.fromJson(data);
  }

  @override
  Future<List<Subscription>> restore({String? appId}) async {
    final res = await _dio.post<List<dynamic>>(
      '/v1/subscriptions/restore',
      options: appId == null
          ? null
          : Options(headers: {'x-app-id': appId}),
    );
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Subscription.fromJson)
        .toList(growable: false);
  }

  // ─── Result 패턴 ──────────────────────────────────────────────────

  @override
  Future<Result<Subscription>> meSafe() => _safe(() => me());

  @override
  Future<Result<Subscription>> verifySafe({
    required SubscriptionPlatform platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
    String? appId,
  }) =>
      _safe(() => verify(
            platform: platform,
            productId: productId,
            purchaseToken: purchaseToken,
            transactionId: transactionId,
            appId: appId,
          ));

  @override
  Future<Result<List<Subscription>>> restoreSafe({String? appId}) =>
      _safe(() => restore(appId: appId));

  Future<Result<T>> _safe<T>(Future<T> Function() fn) async {
    try {
      return Result.success(await fn());
    } on DioException catch (e) {
      return Result.failure(_extract(e));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  ApiException _extract(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return UnknownApiException(
      message: e.message ?? 'Unknown error',
      originalError: e,
    );
  }
}
