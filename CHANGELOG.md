## 0.1.0

**최초 실사용 릴리스.** 본 SDK는 사용자의 단일 운영 백엔드(`https://juny-api.kr`)를 가정한 개인 사용 패키지이며, 외부 사용자는 없음.

### Added
- `NestConfig.defaultBaseUrl = 'https://juny-api.kr'` — `NestClient()` 무인자 호출 시 기본 사용.
- `NestClient.withUrl(String url, ...)` — 로컬 개발/스테이징 등 base URL override 전용 factory.
- `PlanClient` (`/v1/plans`) — 활성 plan 목록 + 단일 plan 조회. 인증 불필요(public).
- `SubscriptionClient` (`/v1/subscriptions/me|verify|restore`) — IAP 영수증 검증 + 사용자 구독 상태 동기화. `appId` 헤더로 Firebase `isPremium` custom claim 연동(선택).
- 도메인 모델: `Plan`, `Subscription`, `BillingPeriod`, `SubscriptionStatus`, `SubscriptionPlatform`.
- 예외 타입: `ReceiptInvalidException`, `PlanNotFoundException`, `SubscriptionNotFoundException`, `ProductPlatformMismatchException`.
- `ErrorInterceptor`가 백엔드 message(`['RECEIPT_INVALID']` 등)를 자동으로 도메인 예외로 매핑.
- `MockPlanClient`, `MockSubscriptionClient` — 테스트 지원.

### Changed (Breaking)
- `NestClient(String baseUrl, {...})` → `NestClient({String? token, ...})` 로 시그니처 변경. 기존 positional baseUrl 호출은 `NestClient.withUrl(...)` 으로 마이그레이션 필요.
- `NestConfig.baseUrl`이 required에서 optional(default = `https://juny-api.kr`)로 변경.

### Migration

| Before (0.0.1) | After (0.1.0) |
|----------------|---------------|
| `NestClient('https://api.example.com')` | `NestClient.withUrl('https://api.example.com')` |
| `NestClient('https://api.example.com', token: 't')` | `NestClient.withUrl('https://api.example.com', token: 't')` |
| (없음) | `NestClient(token: 't')` — default base 사용 |

## 0.0.1

* 초기 스캐폴드: AuthClient, UserClient, dio 기반 NestClient, 자동 토큰 갱신, Result 패턴.
