import 'package:dio/dio.dart';
import 'package:flutter_nest_nexus_client/flutter_nest_nexus_client.dart';
import 'package:flutter_nest_nexus_client/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  group('SubscriptionClient (live HTTP via mock adapter)', () {
    late Dio dio;
    late DioAdapter adapter;
    late SubscriptionClient client;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
      adapter = DioAdapter(dio: dio);
      client = SubscriptionClient(dio);
    });

    test('me: 활성 구독 응답을 Subscription으로 변환', () async {
      adapter.onGet('/v1/subscriptions/me', (server) {
        server.reply(200, {
          'id': 'sub-1',
          'planCode': 'pro_monthly',
          'status': 'active',
          'platform': 'android',
          'productId': 'pro_monthly',
          'startedAt': '2026-04-01T00:00:00.000Z',
          'expiresAt': '2026-05-01T00:00:00.000Z',
          'autoRenewing': true,
        });
      });

      final sub = await client.me();
      expect(sub.id, 'sub-1');
      expect(sub.planCode, 'pro_monthly');
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.platform, SubscriptionPlatform.android);
      expect(sub.autoRenewing, true);
      expect(sub.status.isEntitled, true);
    });

    test('me: free tier 응답', () async {
      adapter.onGet('/v1/subscriptions/me', (server) {
        server.reply(200, {
          'id': null,
          'planCode': 'free',
          'status': 'free',
          'platform': 'system',
          'productId': null,
          'startedAt': null,
          'expiresAt': null,
          'autoRenewing': false,
        });
      });

      final sub = await client.me();
      expect(sub.isFreeTier, true);
      expect(sub.id, isNull);
      expect(sub.status, SubscriptionStatus.free);
      expect(sub.status.isEntitled, false);
    });

    test('verify: Android 영수증 → Subscription 활성화', () async {
      adapter.onPost(
        '/v1/subscriptions/verify',
        (server) {
          server.reply(201, {
            'id': 'sub-1',
            'planCode': 'pro_monthly',
            'status': 'active',
            'platform': 'android',
            'productId': 'pro_monthly',
            'startedAt': '2026-04-01T00:00:00.000Z',
            'expiresAt': '2026-05-01T00:00:00.000Z',
            'autoRenewing': true,
          });
        },
        data: {
          'platform': 'android',
          'productId': 'pro_monthly',
          'purchaseToken': 'token-xyz',
        },
      );

      final sub = await client.verify(
        platform: SubscriptionPlatform.android,
        productId: 'pro_monthly',
        purchaseToken: 'token-xyz',
      );
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.platform, SubscriptionPlatform.android);
    });

    test('restore: 빈 배열 → 빈 list', () async {
      adapter.onPost('/v1/subscriptions/restore', (server) {
        server.reply(201, []);
      });

      final list = await client.restore();
      expect(list, isEmpty);
    });
  });

  group('MockSubscriptionClient', () {
    test('me: mockSubscription 미설정 시 free tier 응답', () async {
      final mock = MockSubscriptionClient();
      final sub = await mock.me();
      expect(sub.isFreeTier, true);
      expect(sub.planCode, 'free');
    });

    test('me: mockSubscription 설정 시 그대로 반환', () async {
      final mock = MockSubscriptionClient();
      mock.mockSubscription = Subscription(
        id: 'sub-x',
        planCode: 'premium_yearly',
        status: SubscriptionStatus.active,
        platform: SubscriptionPlatform.ios,
        productId: 'premium_yearly',
        startedAt: DateTime(2026),
        expiresAt: DateTime(2027),
        autoRenewing: true,
      );
      final sub = await mock.me();
      expect(sub.planCode, 'premium_yearly');
      expect(sub.platform, SubscriptionPlatform.ios);
    });

    test('verify: 기본 응답 — productId 그대로 planCode로 사용', () async {
      final mock = MockSubscriptionClient();
      final sub = await mock.verify(
        platform: SubscriptionPlatform.android,
        productId: 'pro_monthly',
        purchaseToken: 'tk',
      );
      expect(sub.planCode, 'pro_monthly');
      expect(sub.status, SubscriptionStatus.active);
    });

    test('verifySafe: error → Result.failure', () async {
      final mock = MockSubscriptionClient();
      mock.mockError = const ReceiptInvalidException();
      final r = await mock.verifySafe(
        platform: SubscriptionPlatform.android,
        productId: 'pro_monthly',
        purchaseToken: 'tk',
      );
      expect(r.isFailure, true);
      expect(r.error, isA<ReceiptInvalidException>());
    });
  });

  group('SubscriptionStatus.isEntitled', () {
    test('active / inGracePeriod / cancelled → entitled', () {
      expect(SubscriptionStatus.active.isEntitled, true);
      expect(SubscriptionStatus.inGracePeriod.isEntitled, true);
      expect(SubscriptionStatus.cancelled.isEntitled, true);
    });

    test('free / expired / paused / onHold / pending → not entitled', () {
      expect(SubscriptionStatus.free.isEntitled, false);
      expect(SubscriptionStatus.expired.isEntitled, false);
      expect(SubscriptionStatus.paused.isEntitled, false);
      expect(SubscriptionStatus.onHold.isEntitled, false);
      expect(SubscriptionStatus.pending.isEntitled, false);
    });
  });
}
