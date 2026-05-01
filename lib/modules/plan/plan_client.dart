import 'package:dio/dio.dart';

import '../../core/exception.dart';
import '../../models/plan.dart';
import '../../utils/result.dart';

/// DI 및 테스트에서 [PlanClient]와 [MockPlanClient]를 교체할 수 있게 하는 인터페이스.
abstract class PlanClientBase {
  Future<List<Plan>> list();
  Future<Plan> getByCode(String code);
  Future<Result<List<Plan>>> listSafe();
  Future<Result<Plan>> getByCodeSafe(String code);
}

/// `/v1/plans` 엔드포인트 래퍼. 인증 없이 호출되는 public 엔드포인트이므로
/// AuthInterceptor가 token을 첨부해도 서버는 무시한다.
class PlanClient extends PlanClientBase {
  final Dio _dio;

  PlanClient(this._dio);

  @override
  Future<List<Plan>> list() async {
    final res = await _dio.get<List<dynamic>>('/v1/plans');
    final data = res.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Plan.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Plan> getByCode(String code) async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/plans/$code');
    final data = res.data;
    if (data == null) {
      throw const UnknownApiException(message: 'Empty plan response');
    }
    return Plan.fromJson(data);
  }

  // ─── Result 패턴 ──────────────────────────────────────────────────

  @override
  Future<Result<List<Plan>>> listSafe() async {
    try {
      return Result.success(await list());
    } on DioException catch (e) {
      return Result.failure(_extract(e));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Plan>> getByCodeSafe(String code) async {
    try {
      return Result.success(await getByCode(code));
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
