import 'package:dio/dio.dart';
import 'package:flutter_nest_nexus_client/flutter_nest_nexus_client.dart';
import 'package:flutter_nest_nexus_client/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  group('PlanClient (live HTTP via mock adapter)', () {
    late Dio dio;
    late DioAdapter adapter;
    late PlanClient client;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'));
      adapter = DioAdapter(dio: dio);
      client = PlanClient(dio);
    });

    test('list: JSON 배열을 Plan 리스트로 변환', () async {
      adapter.onGet('/v1/plans', (server) {
        server.reply(200, [
          {
            'code': 'free',
            'name': 'Free',
            'description': null,
            'priceCents': 0,
            'currency': 'USD',
            'billingPeriod': 'none',
            'googlePlayProductId': null,
            'appStoreProductId': null,
            'features': {'tier': 'free'},
            'sortOrder': 0,
          },
          {
            'code': 'pro_monthly',
            'name': 'Pro',
            'description': 'Pro tier',
            'priceCents': 499,
            'currency': 'USD',
            'billingPeriod': 'monthly',
            'googlePlayProductId': 'pro_monthly',
            'appStoreProductId': 'pro_monthly',
            'features': {'tier': 'pro'},
            'sortOrder': 10,
          },
        ]);
      });

      final plans = await client.list();
      expect(plans.length, 2);
      expect(plans.first.code, 'free');
      expect(plans.first.billingPeriod, BillingPeriod.none);
      expect(plans.last.code, 'pro_monthly');
      expect(plans.last.priceCents, 499);
      expect(plans.last.billingPeriod, BillingPeriod.monthly);
      expect(plans.last.features['tier'], 'pro');
    });

    test('getByCode: 단일 plan 조회', () async {
      adapter.onGet('/v1/plans/premium_yearly', (server) {
        server.reply(200, {
          'code': 'premium_yearly',
          'name': 'Premium (Yearly)',
          'description': null,
          'priceCents': 9999,
          'currency': 'USD',
          'billingPeriod': 'yearly',
          'googlePlayProductId': null,
          'appStoreProductId': null,
          'features': {'tier': 'premium'},
          'sortOrder': 21,
        });
      });

      final plan = await client.getByCode('premium_yearly');
      expect(plan.code, 'premium_yearly');
      expect(plan.billingPeriod, BillingPeriod.yearly);
    });

    test('getByCode: 404 → PlanNotFoundException (via business code mapping)', () async {
      adapter.onGet('/v1/plans/missing', (server) {
        server.reply(404, {
          'statusCode': 404,
          'message': ['PLAN_NOT_FOUND'],
          'path': '/v1/plans/missing',
        });
      });

      // Note: ErrorInterceptor가 적용되지 않은 raw dio 사용 — DioException이
      // 그대로 throw되며, 본 테스트는 PlanClient의 raw 동작만 검증.
      // ErrorInterceptor 적용된 시나리오는 별도 통합 테스트로 분리.
      expect(
        () => client.getByCode('missing'),
        throwsA(isA<DioException>()),
      );
    });

    test('listSafe: 성공 → Result.success', () async {
      adapter.onGet('/v1/plans', (server) {
        server.reply(200, []);
      });

      final result = await client.listSafe();
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });
  });

  group('MockPlanClient', () {
    test('mockPlans 반환', () async {
      final mock = MockPlanClient();
      mock.mockPlans = [
        const Plan(
          code: 'free',
          name: 'Free',
          description: null,
          priceCents: 0,
          currency: 'USD',
          billingPeriod: BillingPeriod.none,
          googlePlayProductId: null,
          appStoreProductId: null,
          features: {},
          sortOrder: 0,
        ),
      ];

      final plans = await mock.list();
      expect(plans.length, 1);
      expect(plans.first.code, 'free');
    });

    test('getByCode: 없는 code → PlanNotFoundException', () async {
      final mock = MockPlanClient();
      expect(
        () => mock.getByCode('nope'),
        throwsA(isA<PlanNotFoundException>()),
      );
    });

    test('mockError → throw', () async {
      final mock = MockPlanClient();
      mock.mockError = const NetworkException(message: 'offline');
      expect(() => mock.list(), throwsA(isA<NetworkException>()));
    });

    test('listSafe — error를 Result.failure로 반환', () async {
      final mock = MockPlanClient();
      mock.mockError = const ServerException(statusCode: 503);
      final r = await mock.listSafe();
      expect(r.isFailure, true);
    });
  });
}
