import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// SDK 설정 클래스.
///
/// 사용 예:
/// ```dart
/// // 직접 생성
/// final config = NestConfig(baseUrl: 'https://api.example.com', token: 'abc');
///
/// // JSON 파일에서 로드
/// final config = await NestConfig.fromAsset('assets/config.json');
/// ```
class NestConfig {
  final String baseUrl;
  final String? token;
  final String? refreshToken;
  final String refreshEndpoint;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLog;

  const NestConfig({
    required this.baseUrl,
    this.token,
    this.refreshToken,
    this.refreshEndpoint = '/auth/refresh',
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableLog = false,
  });

  factory NestConfig.fromJson(Map<String, dynamic> json) {
    return NestConfig(
      baseUrl: json['baseUrl'] as String,
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
