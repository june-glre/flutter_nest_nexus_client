/// flutter_nest_nexus_client
///
/// NestJS API 서버를 위한 Flutter SDK.
/// 핵심 철학: "Flutter는 API를 몰라도 된다."
///
/// 기본 사용법:
/// ```dart
/// final api = NestClient('https://api.example.com', token: 'your-token');
/// final users = await api.users.get();
/// final me = await api.auth.me();
/// ```
///
/// 설정 파일 사용:
/// ```dart
/// final api = await NestClient.fromConfig('assets/config.json');
/// ```
///
/// 자동 토큰 갱신 사용:
/// ```dart
/// final api = NestClient(
///   'https://api.example.com',
///   token: accessToken,
///   refreshToken: refreshToken,
/// );
/// // 이후 401 응답 시 자동으로 토큰 갱신 및 요청 재시도
/// ```
///
/// Result 패턴 (예외 없는 에러 처리):
/// ```dart
/// final result = await api.users.getSafe();
/// result.fold(
///   onSuccess: (users) => print(users),
///   onFailure: (error) => print(error.message),
/// );
/// ```
library flutter_nest_nexus_client;

// Core
export 'core/client.dart';
export 'core/config.dart';
export 'core/exception.dart';

// App-friendly Models
export 'models/user.dart';

// Domain Clients
export 'modules/user/user_client.dart';
export 'modules/auth/auth_client.dart';

// Utilities
export 'utils/result.dart';
export 'utils/paginated_result.dart';

// Testing Support는 lib/testing.dart에서 별도 제공.
// 프로덕션 코드에서 import하지 마세요:
//   import 'package:flutter_nest_nexus_client/testing.dart';

// generated/ 는 의도적으로 export하지 않음.
// 앱은 DTO가 아닌 도메인 모델(User, AuthResponse)만 알면 됨.
