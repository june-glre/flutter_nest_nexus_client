// 이 파일은 테스트 코드에서만 import하세요. (lib/testing.dart 사용 권장)
// 프로덕션 코드에서는 사용하지 마세요.
//
// 사용 예:
// ```dart
// import 'package:flutter_nest_nexus_client/testing.dart';
//
// final mock = MockNestClient();
// mock.users.mockUsers = [User(id: '1', ...)];
//
// final users = await mock.users.get();
// ```

import '../core/client.dart';
import '../core/exception.dart';
import '../models/user.dart';
import '../modules/auth/auth_client.dart';
import '../modules/user/user_client.dart';
import '../utils/paginated_result.dart';
import '../utils/result.dart';

/// HTTP 요청 없이 동작하는 Mock NestClient.
/// 소비자 앱의 단위 테스트에서 NestClient를 대체하여 사용.
///
/// [NestClientBase]를 구현하므로 DI 컨테이너에서 NestClient와 교체 가능.
class MockNestClient extends NestClientBase {
  @override
  final MockUserClient users;
  @override
  final MockAuthClient auth;

  MockNestClient({
    MockUserClient? users,
    MockAuthClient? auth,
  })  : users = users ?? MockUserClient(),
        auth = auth ?? MockAuthClient();

  String? _token;
  String? _refreshToken;

  @override
  void setToken(String? token) => _token = token;
  @override
  void setRefreshToken(String? token) => _refreshToken = token;

  @override
  String? get currentToken => _token;
  @override
  String? get currentRefreshToken => _refreshToken;
}

/// Mock UserClient.
/// [mockUsers]에 테스트 데이터를 설정하거나 [mockError]로 에러를 시뮬레이션.
class MockUserClient extends UserClientBase {
  List<User> mockUsers = [];
  ApiException? mockError;

  // UserClient의 모든 메서드를 동일한 시그니처로 구현

  Future<List<User>> get() async {
    if (mockError != null) throw mockError!;
    return List.unmodifiable(mockUsers);
  }

  Future<User> getById(String id) async {
    if (mockError != null) throw mockError!;
    final user = mockUsers.where((u) => u.id == id).firstOrNull;
    if (user == null) {
      throw NotFoundException(message: 'User not found: $id');
    }
    return user;
  }

  Future<PaginatedResult<User>> getPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    if (mockError != null) throw mockError!;
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, mockUsers.length);
    final items = start < mockUsers.length
        ? mockUsers.sublist(start, end)
        : <User>[];

    return PaginatedResult(
      items: items,
      total: mockUsers.length,
      page: page,
      limit: limit,
    );
  }

  Future<Result<List<User>>> getSafe() async {
    try {
      return Result.success(await get());
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<User>> getByIdSafe(String id) async {
    try {
      return Result.success(await getById(id));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<PaginatedResult<User>>> getPaginatedSafe({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return Result.success(await getPaginated(page: page, limit: limit));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }
}

/// Mock AuthClient.
/// [mockAuthResponse]에 테스트 데이터를 설정하거나 [mockError]로 에러를 시뮬레이션.
class MockAuthClient extends AuthClientBase {
  AuthResponse? mockAuthResponse;
  User? mockUser;
  RefreshResult? mockRefreshResult;
  ApiException? mockError;

  Future<AuthResponse> login(String email, String password) async {
    if (mockError != null) throw mockError!;
    return mockAuthResponse ??
        AuthResponse(
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token',
          user: User(
            id: 'mock-id',
            email: email,
            name: 'Mock User',
            createdAt: DateTime(2024),
          ),
        );
  }

  Future<User> me() async {
    if (mockError != null) throw mockError!;
    return mockUser ??
        User(
          id: 'mock-id',
          email: 'mock@example.com',
          name: 'Mock User',
          createdAt: DateTime(2024),
        );
  }

  Future<RefreshResult> refresh(String refreshToken) async {
    if (mockError != null) throw mockError!;
    return mockRefreshResult ??
        const RefreshResult(
          accessToken: 'mock-new-access-token',
          refreshToken: 'mock-new-refresh-token',
        );
  }
}
