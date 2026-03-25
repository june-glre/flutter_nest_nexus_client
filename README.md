# flutter_nest_nexus_client

NestJS API 서버를 위한 Flutter SDK.

> **핵심 철학: "Flutter는 API를 몰라도 된다."**
>
> 앱 코드는 DTO, Swagger 스펙, HTTP 상태 코드를 직접 다루지 않습니다.
> SDK가 모든 통신 세부사항을 캡슐화하고, 앱에는 도메인 모델(`User`, `AuthResponse`)만 노출합니다.

---

## 목차

- [설치](#설치)
- [빠른 시작](#빠른-시작)
- [NestClient 생성](#nestclient-생성)
- [인증 & 토큰 관리](#인증--토큰-관리)
- [자동 토큰 갱신](#자동-토큰-갱신)
- [Users 모듈](#users-모듈)
- [Auth 모듈](#auth-모듈)
- [Result 패턴 (예외 없는 에러 처리)](#result-패턴-예외-없는-에러-처리)
- [페이지네이션](#페이지네이션)
- [에러 타입 계층](#에러-타입-계층)
- [설정 파일 사용](#설정-파일-사용)
- [의존성 주입 (DI)](#의존성-주입-di)
- [테스트 — MockNestClient](#테스트--mocknestclient)
- [코드 생성 (openapi-generator)](#코드-생성-openapi-generator)

---

## 설치

`pubspec.yaml`에 추가:

```yaml
dependencies:
  flutter_nest_nexus_client:
    path: ../flutter_nest_nexus_client  # 로컬 경로 또는 pub.dev 버전
```

테스트 코드에서 Mock 사용 시 dev_dependencies에도 추가:

```yaml
dev_dependencies:
  flutter_nest_nexus_client:
    path: ../flutter_nest_nexus_client
```

---

## 빠른 시작

```dart
import 'package:flutter_nest_nexus_client/flutter_nest_nexus_client.dart';

// 1. 클라이언트 생성
final api = NestClient('https://api.example.com', token: 'your-access-token');

// 2. 유저 목록 조회
final users = await api.users.get();  // List<User>

// 3. 현재 사용자 조회
final me = await api.auth.me();       // User

// 4. 페이지네이션
final page = await api.users.getPaginated(page: 1, limit: 20);
print(page.items);       // List<User>
print(page.hasMore);     // bool — 다음 페이지 존재 여부
print(page.totalPages);  // int — 전체 페이지 수
```

---

## NestClient 생성

### 기본 생성자

```dart
final api = NestClient(
  'https://api.example.com',
  token: 'access-token',         // 선택 — 초기 access token
  refreshToken: 'refresh-token', // 선택 — 설정 시 자동 갱신 활성화
  refreshEndpoint: '/auth/refresh', // 기본값
  enableLog: true,               // 개발 중 요청/응답 로그 출력 (기본: false)
);
```

### 설정 파일에서 생성

```dart
// Flutter assets에서 로드 (pubspec.yaml에 assets 등록 필요)
final api = await NestClient.fromConfig('assets/config.json');

// 절대 경로에서 로드 (데스크톱/서버 환경)
final api = await NestClient.fromConfig('/etc/app/config.json');
```

`config.json` 형식:

```json
{
  "baseUrl": "https://api.example.com",
  "token": "access-token",
  "refreshToken": "refresh-token",
  "refreshEndpoint": "/auth/refresh",
  "connectTimeoutMs": 10000,
  "receiveTimeoutMs": 30000,
  "enableLog": false
}
```

`pubspec.yaml`에 assets 등록:

```yaml
flutter:
  assets:
    - assets/config.json
```

---

## 인증 & 토큰 관리

로그인 후 발급된 토큰을 런타임에 업데이트합니다.

```dart
// 로그인
final auth = await api.auth.login('user@example.com', 'password');

// 토큰 업데이트 — 이후 모든 요청에 자동 적용
api.setToken(auth.accessToken);
api.setRefreshToken(auth.refreshToken);

// 현재 토큰 확인
print(api.currentToken);        // String?
print(api.currentRefreshToken); // String?

// 로그아웃
api.setToken(null);
api.setRefreshToken(null);
```

---

## 자동 토큰 갱신

`refreshToken`을 설정하면 401 응답 시 자동으로 토큰을 갱신하고 원래 요청을 재시도합니다.

```dart
final api = NestClient(
  'https://api.example.com',
  token: accessToken,
  refreshToken: refreshToken, // ← 이 값이 있으면 자동 갱신 활성화
);

// 401 발생 시 SDK가 자동으로:
// 1. POST /auth/refresh → { refreshToken } 전송
// 2. 새 accessToken/refreshToken 저장
// 3. 원래 요청 재시도
// 앱 코드는 아무 변경 없이 동작
try {
  final users = await api.users.get();
} on DioException catch (e) {
  if (e.error is UnauthorizedException) {
    // refresh 자체가 실패한 경우 (refresh token 만료 등)
    // → 로그아웃 처리
  }
}
```

**동시 401 처리:** 여러 요청이 동시에 401을 받아도 refresh는 한 번만 실행되고,
나머지 요청은 refresh 완료 후 자동으로 재시도됩니다.

> NestJS refresh 엔드포인트가 응답하는 JSON 형식:
> ```json
> { "accessToken": "...", "refreshToken": "..." }
> ```

---

## Users 모듈

`api.users`로 접근합니다.

### 기본 API (예외 throw)

```dart
// 전체 유저 목록
final users = await api.users.get(); // List<User>

// ID로 단일 유저 조회
final user = await api.users.getById('user-id'); // User

// 페이지네이션 (단일 HTTP 요청)
final page = await api.users.getPaginated(page: 1, limit: 20); // PaginatedResult<User>
```

### Result 패턴 API (예외 없음)

```dart
final result = await api.users.getSafe();
final result = await api.users.getByIdSafe('user-id');
final result = await api.users.getPaginatedSafe(page: 1, limit: 20);
```

자세한 사용법은 [Result 패턴](#result-패턴-예외-없는-에러-처리) 섹션을 참고하세요.

### User 모델

```dart
class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
}
```

---

## Auth 모듈

`api.auth`로 접근합니다.

```dart
// 이메일/비밀번호 로그인
final auth = await api.auth.login('user@example.com', 'password');
// → AuthResponse { accessToken, refreshToken?, user }

// 현재 인증된 사용자 조회 (Authorization 헤더 필요)
final me = await api.auth.me();
// → User

// 수동 토큰 갱신 (자동 갱신이 활성화된 경우 직접 호출 불필요)
final result = await api.auth.refresh(currentRefreshToken);
// → RefreshResult { accessToken, refreshToken? }
```

### AuthResponse 모델

```dart
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final User user;
}
```

---

## Result 패턴 (예외 없는 에러 처리)

`try-catch` 없이 에러를 처리하고 싶을 때 `*Safe()` 메서드를 사용합니다.

### fold — 성공/실패 양쪽 처리

```dart
final result = await api.users.getSafe();

result.fold(
  onSuccess: (users) {
    // List<User> 처리
    print('유저 ${users.length}명 로드됨');
  },
  onFailure: (error) {
    // ApiException 처리
    print('에러: ${error.message}');
  },
);
```

### 상태 확인

```dart
final result = await api.users.getByIdSafe('user-id');

if (result.isSuccess) {
  final user = result.data!; // User
}

if (result.isFailure) {
  final error = result.error!; // ApiException
  print(error.statusCode); // int? (401, 404, 500, ...)
  print(error.message);    // String
}
```

### 에러 타입별 분기

```dart
final result = await api.users.getSafe();

result.fold(
  onSuccess: (users) => showUsers(users),
  onFailure: (error) {
    switch (error) {
      case NetworkException():
        showOfflineMessage();
      case UnauthorizedException():
        navigateToLogin();
      case NotFoundException():
        showNotFoundMessage();
      case ServerException():
        showServerErrorMessage(error.statusCode);
      default:
        showGenericError(error.message);
    }
  },
);
```

---

## 페이지네이션

`getPaginated()` / `getPaginatedSafe()`는 단일 HTTP 요청으로 목록과 메타 정보를 함께 반환합니다.

```dart
final page = await api.users.getPaginated(page: 1, limit: 20);

page.items       // List<User> — 현재 페이지 항목
page.total       // int — 전체 항목 수
page.page        // int — 현재 페이지 번호
page.limit       // int — 페이지당 항목 수

page.hasMore     // bool — 다음 페이지 존재 여부
page.isFirstPage // bool — 첫 번째 페이지 여부
page.totalPages  // int — 전체 페이지 수
```

### 무한 스크롤 예시

```dart
int _currentPage = 1;
List<User> _users = [];
bool _hasMore = true;

Future<void> loadMore() async {
  if (!_hasMore) return;

  final page = await api.users.getPaginated(
    page: _currentPage,
    limit: 20,
  );

  _users.addAll(page.items);
  _hasMore = page.hasMore;
  _currentPage++;
}
```

### 빈 결과

```dart
final empty = PaginatedResult<User>.empty();
// items: [], total: 0, hasMore: false
```

> **NestJS 서버 응답 형식:**
> ```json
> {
>   "data": [...],
>   "meta": { "total": 100, "page": 1, "limit": 20 }
> }
> ```
> `getUsers()` 엔드포인트가 이 형식을 반환해야 합니다.

---

## 에러 타입 계층

모든 예외는 `ApiException`을 상속합니다.

| 클래스 | statusCode | 발생 조건 |
|--------|-----------|----------|
| `NetworkException` | `null` | 연결 실패, 타임아웃 |
| `UnauthorizedException` | `401` | 토큰 만료, refresh 실패 |
| `ForbiddenException` | `403` | 권한 없음 |
| `NotFoundException` | `404` | 리소스 없음 |
| `ServerException` | `5xx` | 서버 에러 |
| `UnknownApiException` | `null` | 기타 에러 |

```dart
try {
  final users = await api.users.get();
} on DioException catch (e) {
  final apiError = e.error; // ApiException

  if (apiError is NetworkException) {
    // 오프라인 처리
  } else if (apiError is UnauthorizedException) {
    // 로그인 화면으로 이동
  } else if (apiError is NotFoundException) {
    // 404 처리
  }
}
```

공통 속성:

```dart
apiError.statusCode // int? — HTTP 상태 코드
apiError.message    // String — 에러 메시지
```

---

## 설정 파일 사용

### NestConfig 직접 생성

```dart
final config = NestConfig(
  baseUrl: 'https://api.example.com',
  token: 'access-token',
  refreshToken: 'refresh-token',
  refreshEndpoint: '/auth/refresh',      // 기본값
  connectTimeout: Duration(seconds: 10), // 기본값
  receiveTimeout: Duration(seconds: 30), // 기본값
  enableLog: false,                      // 기본값
);
```

### fromJson

```dart
final config = NestConfig.fromJson({
  'baseUrl': 'https://api.example.com',
  'connectTimeoutMs': 5000,   // milliseconds
  'receiveTimeoutMs': 15000,
  'enableLog': true,
});
```

### fromAsset (Flutter assets)

```dart
// pubspec.yaml에 등록 후:
final config = await NestConfig.fromAsset('assets/config.json');
```

### fromFile (데스크톱/테스트 환경)

```dart
final config = await NestConfig.fromFile('/etc/app/config.json');
```

---

## 의존성 주입 (DI)

`NestClientBase` 추상 인터페이스를 사용하면 프로덕션과 테스트에서
`NestClient`와 `MockNestClient`를 교체할 수 있습니다.

```dart
// Repository 정의
class UserRepository {
  final NestClientBase _api;
  UserRepository(this._api);

  Future<List<User>> getActiveUsers() async {
    final result = await _api.users.getSafe();
    return result.data ?? [];
  }
}

// 프로덕션
final repo = UserRepository(
  NestClient('https://api.example.com', token: accessToken),
);

// 테스트
final repo = UserRepository(MockNestClient());
```

`UserClientBase` / `AuthClientBase`도 동일하게 사용 가능합니다:

```dart
class AuthService {
  final AuthClientBase _auth;
  AuthService(this._auth);
}
```

---

## 테스트 — MockNestClient

HTTP 요청 없이 동작하는 Mock 클라이언트입니다.
**테스트 코드에서만 import하세요.**

```dart
import 'package:flutter_nest_nexus_client/testing.dart'; // ← testing.dart 사용
```

> 메인 라이브러리(`flutter_nest_nexus_client.dart`)에는 Mock이 포함되지 않습니다.

### 기본 사용

```dart
test('유저 목록 표시', () async {
  final mock = MockNestClient();

  mock.users.mockUsers = [
    User(id: '1', email: 'alice@test.com', name: 'Alice', createdAt: DateTime(2024)),
    User(id: '2', email: 'bob@test.com', name: 'Bob', createdAt: DateTime(2024)),
  ];

  final users = await mock.users.get();
  expect(users.length, 2);
  expect(users.first.name, 'Alice');
});
```

### 에러 시뮬레이션

```dart
test('네트워크 에러 처리', () async {
  final mock = MockNestClient();
  mock.users.mockError = const NetworkException(message: 'No internet');

  expect(
    () => mock.users.get(),
    throwsA(isA<NetworkException>()),
  );
});

test('getSafe — 에러를 Result.failure로 반환', () async {
  final mock = MockNestClient();
  mock.users.mockError = const ServerException(statusCode: 500);

  final result = await mock.users.getSafe();
  expect(result.isFailure, true);
  expect(result.error, isA<ServerException>());
});
```

### 페이지네이션 테스트

```dart
test('무한 스크롤 페이지네이션', () async {
  final mock = MockNestClient();
  mock.users.mockUsers = List.generate(
    25,
    (i) => User(id: '$i', email: '$i@test.com', name: 'User$i', createdAt: DateTime(2024)),
  );

  final page1 = await mock.users.getPaginated(page: 1, limit: 10);
  expect(page1.items.length, 10);
  expect(page1.total, 25);
  expect(page1.hasMore, true);

  final page3 = await mock.users.getPaginated(page: 3, limit: 10);
  expect(page3.items.length, 5);
  expect(page3.hasMore, false);
});
```

### 인증 테스트

```dart
test('로그인 기본 동작', () async {
  final mock = MockNestClient();

  final auth = await mock.auth.login('test@test.com', 'password');
  expect(auth.accessToken, isNotEmpty);
  expect(auth.user.email, 'test@test.com');
});

test('커스텀 응답 설정', () async {
  final mock = MockNestClient();
  mock.auth.mockAuthResponse = AuthResponse(
    accessToken: 'custom-token',
    user: User(id: '1', email: 'alice@test.com', name: 'Alice', createdAt: DateTime(2024)),
  );

  final auth = await mock.auth.login('any@email.com', 'any');
  expect(auth.accessToken, 'custom-token');
});
```

---

## 코드 생성 (openapi-generator)

`lib/generated/` 폴더는 NestJS Swagger 스펙에서 자동 생성됩니다.
새로운 엔드포인트 추가 또는 API 변경 시 재생성합니다.

### 사전 요구사항

```bash
# macOS
brew install openapi-generator

# npm
npm install -g @openapitools/openapi-generator-cli
```

### 생성 실행

```bash
# 로컬 NestJS 서버 (기본값)
./scripts/generate.sh

# 특정 URL 지정
./scripts/generate.sh http://localhost:3000/api-json
./scripts/generate.sh https://api.example.com/api-json
```

스크립트가 자동으로 `build_runner`까지 실행합니다.

### NestJS Swagger 설정 예시

```typescript
// main.ts
app.useGlobalPrefix('api');
const config = new DocumentBuilder().setTitle('API').build();
const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup('api', app, document);
// Swagger JSON URL: http://localhost:3000/api-json
```

### 수동으로 build_runner 실행

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 생성 후 작업

새 엔드포인트가 추가된 경우 `lib/modules/` 아래 해당 클라이언트 파일을 업데이트합니다.
`lib/models/`, `lib/modules/`, `lib/core/`는 재생성 시 변경되지 않습니다.

---

## 아키텍처

```
NestClientBase (abstract interface)
    │
    ├── NestClient (프로덕션)
    │     ├── Dio 인터셉터 체인
    │     │     ├── AuthInterceptor         — Authorization 헤더 주입
    │     │     ├── TokenRefreshInterceptor — 401 → refresh → retry
    │     │     ├── ErrorInterceptor        — DioException → ApiException 변환
    │     │     └── NestLogInterceptor      — 요청/응답 로깅 (선택)
    │     │
    │     ├── UserClient (UserClientBase)
    │     └── AuthClient (AuthClientBase)
    │
    └── MockNestClient (테스트용)
          ├── MockUserClient (UserClientBase)
          └── MockAuthClient (AuthClientBase)

라이브러리 export 구분:
  flutter_nest_nexus_client.dart  — 프로덕션 API (Mock 제외)
  testing.dart                    — MockNestClient, MockUserClient, MockAuthClient
```

---

## 라이선스

MIT
