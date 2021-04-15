/// 권한 미동의시 발생하는 에러
class AuthenticationMissingError extends Error {
  @override
  String toString() {
    return '퍼미션 미동의로 인한 에러';
  }
}

/// Health 패키지 사용에 필요한 권한의 종류
enum AuthState {
  /// 요청하지 않음
  neverRequest,
  /// 거절
  denied,
  /// 승인
  granted,
}