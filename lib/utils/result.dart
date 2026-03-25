import '../core/exception.dart';

/// 성공/실패를 명시적으로 표현하는 Result 타입.
/// try-catch 없이 에러를 처리할 수 있게 해줌.
///
/// 사용 예:
/// ```dart
/// final result = await api.users.getSafe();
/// result.fold(
///   onSuccess: (users) => print(users),
///   onFailure: (error) => print(error.message),
/// );
/// ```
class Result<T> {
  final T? _data;
  final ApiException? _error;

  const Result._({T? data, ApiException? error})
      : _data = data,
        _error = error;

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(ApiException error) => Result._(error: error);

  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;

  T? get data => _data;
  ApiException? get error => _error;

  /// 성공/실패 양쪽을 처리하는 fold 패턴.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiException error) onFailure,
  }) {
    if (isSuccess) return onSuccess(_data as T);
    return onFailure(_error!);
  }

  @override
  String toString() => isSuccess
      ? 'Result.success($_data)'
      : 'Result.failure(${_error?.message})';
}
