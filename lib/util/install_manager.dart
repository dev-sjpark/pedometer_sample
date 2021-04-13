import 'package:flutter/services.dart';
import 'dart:io' show Platform;

import 'package:pedometer_sample/dto/application_info.dart';

/// ## 각 플렛폼에서 연동하고자 하는 어플리케이션이 설치 됫는지 확인하는 클래스
/// Android 의 경우, 삼성 헬스와 구글 핏의 설치 여부를 확인하고, iOS 의 경우, 건강 얍의 설치여부를 확인한다.
/// 또한 필요시, 설치링크로 이동하게 한다.
class InstallManager {
  static InstallManager? _instance;
  InstallManager._() { _instance = this; }

  // single tone
  factory InstallManager() => _instance ?? InstallManager._();

  static const _CHANNEL_NAME = 'kr.co.hunet.pedometer_sample';
  MethodChannel _channel = MethodChannel(_CHANNEL_NAME);

  /// ### 연동하고자 하는 어플리케이션의 설치여부를 확인.
  Future<List<ApplicationInfo>> checkSyncAppInstalled() async {
    if (Platform.isAndroid) {
      List<int> flags = await _channel.invokeListMethod<int>('syncApp#installed') ?? [];
      List<ApplicationInfo> appStatus = [];
      for (int i = 0; i < flags.length; i ++) {
        appStatus.add(ApplicationInfo.decode(i, flags[i]));
      }
      return appStatus;
    } else {
      // iOS 의 경우 기본앱이므로 항상 사용가능으로 반환.
      return [ApplicationInfo(target: SyncTarget.iosHealth, status: InstallStatus.available)];
    }
  }

  /// ### store URL 을 통해 store 로 이동
  void openStoreUrl(SyncTarget target){
    if (Platform.isAndroid) {
      _channel.invokeMethod('open#store', {'target' : target.index});
    } else {
      _channel.invokeMethod('open#store');
    }
  }

}

