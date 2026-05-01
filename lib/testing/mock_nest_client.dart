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
import '../models/plan.dart';
import '../models/subscription.dart';
import '../models/user.dart';
import '../modules/auth/auth_client.dart';
import '../modules/plan/plan_client.dart';
import '../modules/subscription/subscription_client.dart';
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
  @override
  final MockPlanClient plans;
  @override
  final MockSubscriptionClient subscriptions;

  MockNestClient({
    MockUserClient? users,
    MockAuthClient? auth,
    MockPlanClient? plans,
    MockSubscriptionClient? subscriptions,
  })  : users = users ?? MockUserClient(),
        auth = auth ?? MockAuthClient(),
        plans = plans ?? MockPlanClient(),
        subscriptions = subscriptions ?? MockSubscriptionClient();

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

/// Mock PlanClient.
/// [mockPlans]에 테스트 plan을 설정하거나 [mockError]로 에러를 시뮬레이션.
class MockPlanClient extends PlanClientBase {
  List<Plan> mockPlans = [];
  ApiException? mockError;

  @override
  Future<List<Plan>> list() async {
    if (mockError != null) throw mockError!;
    return List.unmodifiable(mockPlans);
  }

  @override
  Future<Plan> getByCode(String code) async {
    if (mockError != null) throw mockError!;
    final plan = mockPlans.where((p) => p.code == code).firstOrNull;
    if (plan == null) {
      throw PlanNotFoundException(message: 'Plan not found: $code');
    }
    return plan;
  }

  @override
  Future<Result<List<Plan>>> listSafe() async {
    try {
      return Result.success(await list());
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Plan>> getByCodeSafe(String code) async {
    try {
      return Result.success(await getByCode(code));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }
}

/// Mock SubscriptionClient.
/// [mockSubscription]에 테스트 구독을 설정하거나 [mockError]로 에러를 시뮬레이션.
/// [mockSubscription]이 null이면 [Subscription]의 free tier를 응답.
class MockSubscriptionClient extends SubscriptionClientBase {
  Subscription? mockSubscription;
  List<Subscription>? mockRestoreList;
  ApiException? mockError;

  @override
  Future<Subscription> me() async {
    if (mockError != null) throw mockError!;
    return mockSubscription ?? _freeTier();
  }

  @override
  Future<Subscription> verify({
    required SubscriptionPlatform platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
    String? appId,
  }) async {
    if (mockError != null) throw mockError!;
    return mockSubscription ??
        Subscription(
          id: 'mock-sub-id',
          planCode: productId,
          status: SubscriptionStatus.active,
          platform: platform,
          productId: productId,
          startedAt: DateTime(2026),
          expiresAt: DateTime(2026, 12),
          autoRenewing: true,
        );
  }

  @override
  Future<List<Subscription>> restore({String? appId}) async {
    if (mockError != null) throw mockError!;
    return mockRestoreList ?? [mockSubscription ?? _freeTier()];
  }

  @override
  Future<Result<Subscription>> meSafe() async {
    try {
      return Result.success(await me());
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Subscription>> verifySafe({
    required SubscriptionPlatform platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
    String? appId,
  }) async {
    try {
      return Result.success(await verify(
        platform: platform,
        productId: productId,
        purchaseToken: purchaseToken,
        transactionId: transactionId,
        appId: appId,
      ));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Subscription>>> restoreSafe({String? appId}) async {
    try {
      return Result.success(await restore(appId: appId));
    } on ApiException catch (e) {
      return Result.failure(e);
    }
  }

  Subscription _freeTier() => const Subscription(
        id: null,
        planCode: 'free',
        status: SubscriptionStatus.free,
        platform: SubscriptionPlatform.system,
        productId: null,
        startedAt: null,
        expiresAt: null,
        autoRenewing: false,
      );
}
