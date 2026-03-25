/// flutter_nest_nexus_client 테스트 전용 라이브러리.
///
/// 프로덕션 코드에서 import하지 마세요.
///
/// 사용법:
/// ```dart
/// // test/my_widget_test.dart
/// import 'package:flutter_nest_nexus_client/testing.dart';
///
/// final mock = MockNestClient();
/// mock.users.mockUsers = [User(id: '1', email: 'a@test.com', ...)];
/// ```
library flutter_nest_nexus_client_testing;

export 'testing/mock_nest_client.dart';
