import 'package:dio/dio.dart';

import '../../core/exception.dart';
import '../../generated/api/user_api.dart';
import '../../models/user.dart';
import '../../utils/paginated_result.dart';
import '../../utils/result.dart';

/// DI 및 테스트에서 [UserClient]와 [MockUserClient]를 교체할 수 있게 하는 인터페이스.
abstract class UserClientBase {
  Future<List<User>> get();
  Future<User> getById(String id);
  Future<PaginatedResult<User>> getPaginated({int page = 1, int limit = 20});
  Future<Result<List<User>>> getSafe();
  Future<Result<User>> getByIdSafe(String id);
  Future<Result<PaginatedResult<User>>> getPaginatedSafe({
    int page = 1,
    int limit = 20,
  });
}

class UserClient extends UserClientBase {
  final UserApi _api;

  UserClient(this._api);

  // ─── 기본 API (예외 throw) ──────────────────────────────────────────

  /// 모든 유저 목록 반환.
  /// [ApiException] 계열의 예외를 throw할 수 있음.
  Future<List<User>> get() async {
    final paged = await _api.getUsers();
    return paged.data.map(User.fromDto).toList();
  }

  /// ID로 유저 조회.
  Future<User> getById(String id) async {
    final dto = await _api.getUserById(id);
    return User.fromDto(dto);
  }

  /// 페이지네이션으로 유저 목록 반환.
  /// 단일 HTTP 호출로 items + meta를 수신 (N+1 방지).
  Future<PaginatedResult<User>> getPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    final paged = await _api.getUsers(page: page, limit: limit);
    return PaginatedResult(
      items: paged.data.map(User.fromDto).toList(),
      total: paged.meta.total,
      page: paged.meta.page,
      limit: paged.meta.limit,
    );
  }

  // ─── Result 패턴 API (예외 없이 반환) ─────────────────────────────

  /// 예외 대신 [Result]로 성공/실패를 반환.
  Future<Result<List<User>>> getSafe() async {
    try {
      return Result.success(await get());
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  /// ID로 유저 조회 — Result 패턴.
  Future<Result<User>> getByIdSafe(String id) async {
    try {
      return Result.success(await getById(id));
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  /// 페이지네이션 조회 — Result 패턴.
  Future<Result<PaginatedResult<User>>> getPaginatedSafe({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return Result.success(await getPaginated(page: page, limit: limit));
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  ApiException _extractException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return UnknownApiException(
      message: e.message ?? 'Unknown error',
      originalError: e,
    );
  }
}
