/// 페이지네이션 결과를 표현하는 타입.
///
/// 사용 예:
/// ```dart
/// final result = await api.users.getPaginated(page: 1, limit: 20);
/// print(result.items);       // List<User>
/// print(result.hasMore);     // 다음 페이지 존재 여부
/// print(result.totalPages);  // 전체 페이지 수
/// ```
class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;

  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// 다음 페이지가 존재하는지 여부.
  bool get hasMore => (page * limit) < total;

  /// 현재 페이지가 첫 번째 페이지인지 여부.
  bool get isFirstPage => page == 1;

  /// 전체 페이지 수.
  int get totalPages => limit > 0 ? (total / limit).ceil() : 0;

  /// 빈 결과 생성 팩토리.
  factory PaginatedResult.empty() => const PaginatedResult(
        items: [],
        total: 0,
        page: 1,
        limit: 20,
      );

  @override
  String toString() =>
      'PaginatedResult(page: $page/$totalPages, items: ${items.length}/$total)';
}
