import 'package:pedometer_sample/util/install_manager.dart';

/// 연동 어플의 종류 enum
enum SyncTarget {
  /// 삼성 핼스
  samsungHealth,
  /// 구글 피트니스
  googleFitness,
  /// iOS의 건강앱
  iosHealth,
}

/// 설치 상태를 나타내는 enum
enum InstallStatus {
  /// 사용가능
  available,
  /// 비활성화 (only Android)
  inactivate,
  /// 미설치 (only Android)
  notInstall,
}

/// ### 사용가능한 어플리케이션 정보
/// [InstallManager]에서 사용가능한 어플리케이션 정보를 받아올때 사용되는 클래스.
/// 어떤 각 어플리케이션의 종류와 상태를 나타낸다.
/// - iOS의 경우, 건강앱이 기본 앱이기에 [target]은 [SyncTarget.iosHealth]이고 [status]는
/// [InstallStatus.available]인 객체가 사용된다.
/// - Android 의 경우 메서드 채널을 통해 확인하여 결과값을 반환한다.
class ApplicationInfo {
  final SyncTarget target;
  final InstallStatus status;

  ApplicationInfo({required this.target, required this.status});

  factory ApplicationInfo.decode(int targetIdx, int statusIdx) => ApplicationInfo(
    target: SyncTarget.values[targetIdx],
    status: InstallStatus.values[statusIdx],
  );

  /// ### 각 연동 어플리케이션의 라벨 반환
  String get targetLabel {
    String label = '';
    switch (target){
      case SyncTarget.samsungHealth:
        label = '삼성 헬스';
        break;
      case SyncTarget.googleFitness:
        label = '구글 피트니스';
        break;
      case SyncTarget.iosHealth:
        label = '건강';
        break;
    }
    return label;
  }

  /// ### 각 연동 어플리케이션의 설치상태 설명 반환
  String get statusDesc {
    String desc = '';
    switch (status) {
      case InstallStatus.available:
        desc = '사용가능';
        break;
      case InstallStatus.inactivate:
        desc = '비활성화';
        break;
      case InstallStatus.notInstall:
        desc = '미설치';
        break;
    }
    return desc;
  }
}