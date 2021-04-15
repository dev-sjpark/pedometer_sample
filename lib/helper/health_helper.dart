import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:pedometer_sample/model/auth_util.dart';

/// ### Health 패키지의 [HealthFactory]를 감싼 wrapper class
class HealthHelper {
  static HealthHelper? _instance;
  HealthHelper._(){
    _instance ??= this;
  }
  /// single tone 생성자 - auth 떄문에 single tone 처리
  factory HealthHelper() => _instance ?? HealthHelper._();


  /// android 부분 플러그인 에러로 직접 구현
  MethodChannel _channel = MethodChannel('co.kr.hunet.pedometer_sample/fitness');
  /// 권한 상태
  AuthState _auth =  AuthState.neverRequest;
  /// 권한 상태 확인
  bool get isAuth => _auth == AuthState.granted;

  /// fetch 를 통해 가져올 데이터의 종류
  final _dataTypes = [ HealthDataType.STEPS ];
  /// 플러그인 클래스
  final HealthFactory _factory = HealthFactory();

  /// ## 현 시간까지의 데이터 요청
  Future<int> getTodayStep([DateTime? startTime]) async{
    if (!isAuth) throw AuthenticationMissingError();
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod<int>('fetch#data') ?? 0;
      } else {
        final now = DateTime.now();
        List<HealthDataPoint> result = await _factory.getHealthDataFromTypes(
          DateTime(now.year, now.month, now.day),
          now,
          _dataTypes,
        );
        int total = 0;
        result.forEach((datePoint) {
          print(datePoint);
          total += datePoint.value.toInt();
        });
        return total;
      }
      return 0;
    } catch (e) {
      final appLabel = Platform.isAndroid ? '구글 피트니스' : 'iOS HealthKit';
      print('$appLabel를 통한 데이터 받아오기 실패 >> $e');
      rethrow;
    }
  }

  /// 권한 요청하는 함수
  Future<bool> requestPermission() async{
    if(Platform.isAndroid) {
      List<bool?> results = await Future.wait<bool?>([
        _channel.invokeMethod<bool>('request#auth'),
        _channel.invokeMethod<bool>('request#permission')
      ]);
      bool authResult = results.every((element) => element ?? false);
      _auth = authResult ? AuthState.granted : AuthState.denied;
      return authResult;
    } else { // ios
      bool authResult = await _factory.requestAuthorization(_dataTypes);
      _auth = authResult ? AuthState.granted : AuthState.denied;
      return authResult;
    }
  }
}