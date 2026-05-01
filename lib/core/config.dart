import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// SDK 설정 클래스.
///
/// `baseUrl` 미지정 시 [NestConfig.defaultBaseUrl] (= `https://juny-api.kr`)을
/// 사용한다. 본 SDK가 nest-nexus 프로덕션 도메인 전용이라는 가정에 기반한
/// 기본값이며, 로컬 개발/스테이징 시에는 명시적으로 다른 URL을 전달한다.
///
/// 사용 예:
/// ```dart
/// // 기본 URL 사용
/// final config = NestConfig();
///
/// // 명시적 URL
/// final config = NestConfig(baseUrl: 'http://localhost:3000', token: 'abc');
///
/// // JSON 파일에서 로드
/// final config = await NestConfig.fromAsset('assets/config.json');
/// ```
class NestConfig {
  /// 본 SDK의 기본 NestJS API 도메인.
  ///
  /// 단일 운영 환경(`https://juny-api.kr`) 가정. 로컬/스테이징 사용 시는
  /// 생성자에서 명시적으로 `baseUrl`을 전달해 override 한다.
  static const String defaultBaseUrl = 'https://juny-api.kr';

  final String baseUrl;
  final String? token;
  final String? refreshToken;
  final String refreshEndpoint;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLog;

  const NestConfig({
    this.baseUrl = defaultBaseUrl,
    this.token,
    this.refreshToken,
    this.refreshEndpoint = '/auth/refresh',
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableLog = false,
  });

  factory NestConfig.fromJson(Map<String, dynamic> json) {
    return NestConfig(
      baseUrl: (json['baseUrl'] as String?) ?? defaultBaseUrl,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      refreshEndpoint:
          (json['refreshEndpoint'] as String?) ?? '/auth/refresh',
      connectTimeout: Duration(
        milliseconds: (json['connectTimeoutMs'] as int?) ?? 10000,
      ),
      receiveTimeout: Duration(
        milliseconds: (json['receiveTimeoutMs'] as int?) ?? 30000,
      ),
      enableLog: (json['enableLog'] as bool?) ?? false,
    );
  }

  /// Flutter assets에서 로드 (예: 'assets/config.json').
  /// pubspec.yaml에 assets 등록 필요.
  static Future<NestConfig> fromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return NestConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// 파일 시스템 절대 경로에서 로드.
  /// 주로 테스트 환경이나 데스크톱 앱에서 사용.
  static Future<NestConfig> fromFile(String filePath) async {
    final raw = await File(filePath).readAsString();
    return NestConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
