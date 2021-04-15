import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:health/health.dart';
import 'package:pedometer_sample/helper/health_helper.dart';
import 'package:pedometer_sample/util/install_manager.dart';

import 'model/application_info.dart';

void main() {
  runApp(PedometerSampleApp());

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
}

class PedometerSampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final installManger = InstallManager();
  Completer<List<ApplicationInfo>> _appInfo = Completer();

  /// 스토어 오픈으로 인한 life cycle 변경 이벤트시 확인용으로 사용
  bool _isOpenedStore = false;

  /// health 패키지의 wrapper class
  HealthHelper? _healthHelper;
  /// health 패키지에서 받아온 데이터
  int _healthStep = 0;

  @override
  void initState() {
    checkApplicationState();
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  /// 어플의 설치여부 확
  void checkApplicationState(){
    if (mounted) {
      setState(() => _appInfo = Completer());
    }
    installManger.checkSyncAppInstalled().then((list) {
      _appInfo.complete(list);

      // 사용가능한 서비스에 대해서만 wrapper 생성
      list.forEach((info) {
        if (Platform.isAndroid) {
          if (info.target == SyncTarget.googleFitness &&
              info.status == InstallStatus.available) {
            if (mounted) setState(() {
              _healthHelper ??= HealthHelper();
            });
          }
          if (info.target == SyncTarget.samsungHealth &&
              info.status == InstallStatus.available) {

          }
        }else {
          if (mounted) setState(() {
            _healthHelper ??= HealthHelper();
          });
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 스토어 다녀온 경우 재확인
      if (_isOpenedStore) checkApplicationState();
      _isOpenedStore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
      body: _body(),
    );
  }

  /// 상단 앱바
  _appBar() => AppBar(
    backgroundColor: Colors.white,
    centerTitle: true,
    elevation: 0.0,
    title: Text(
      'Pedometer sample',
      style: TextStyle(
        fontSize: 16,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// 바디 영역
  _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _platformInfo(),
      _statusChecker(),

      // data viewer
      _dataViewer(),
    ],
  );

  /// 바디 최상단 플렛폼의 종류를 표시
  _platformInfo() => Container(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      'platform: ${Platform.isAndroid ? 'ANDROID' : 'iOS'}',
    ),
  );

  /// 바디의 상단 플랫폼의 종류를 보여주는 부분 아래. 플랫폼과 어플 설치 상태를 보여준다.
  _statusChecker() => FutureBuilder<List<ApplicationInfo>>(
    future: _appInfo.future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // loading progress
        return Container(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      // future 완료!!
      final infos = snapshot.data!;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: infos.map((info) => __appStatusRow(info)).toList(),
        ),
      );
    },
  );

  /// 어플의 설치 여부를 표시하는 각 한줄의 위젯
  Widget __appStatusRow(ApplicationInfo info){
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              info.targetLabel,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            info.statusDesc,
          ),

          // URL 버튼
          info.status != InstallStatus.available ? GestureDetector(
            onTap: () => _onTapPlayStore(info.target),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Theme.of(context).primaryColorDark,
              ),
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'store URL',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ) : SizedBox(),
        ],
      ),
    );
  }

  /// body에 붙는 데이터 뷰어 (카드형식의 scroller)
  _dataViewer() {
    final List<Widget> children;
    if (Platform.isAndroid) {
      children = [
        _fitness(),
      ];
    }else {
      children = [
        _iosHealth(),
      ];
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// 구글 피트니스 데이터 표시
  Widget _fitness() => Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.brown,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '구글 피트니스',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1
                ),
              ),
            ),

            Text(
              _healthHelper != null ? '사용가능' : '사용불가능',
              style: TextStyle(
                  color: Colors.white,
                  height: 1
              ),
            ),
          ],
        ),

        // fetch button
        GestureDetector(
          onTap: _onTapFitnessPatch,
          child: Container(
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'patch data',
              ),
            ),
          ),
        ),

        // data viewer
        _healthHelper != null ? Container(
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '오늘의 걸음수',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              SizedBox(width: 8,),

              Text(
                _healthStep.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ) : SizedBox(),
      ],
    ),
  );

  /// iOS 건강 데이터 표시
  Widget _iosHealth() => Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.deepOrange,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '건강앱',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1
                ),
              ),
            ),

            Text(
              _healthHelper != null ? '사용가능' : '사용불가능',
              style: TextStyle(
                  color: Colors.white,
                  height: 1
              ),
            ),
          ],
        ),

        // fetch button
        GestureDetector(
          onTap: _onTapHealthPatch,
          child: Container(
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'patch data',
              ),
            ),
          ),
        ),
      ],
    ),
  );

}

/// ### [_HomeState]에서 사용되는 각 사용자 인터렉션으로 인한 콜백들의 모음
extension CallBacks on _HomeState {

  /// 플로팅 액션 버튼에 대한 클릭이벤트
  void onRefresh(){
    checkApplicationState();
  }

  /// ### store Url 버튼의 온탭 이벤트
  /// 사용가능하지 않은 어플리케이션의 경우 play store 로 연결
  void _onTapPlayStore(SyncTarget target) {
    _isOpenedStore = true;
    installManger.openStoreUrl(target);
  }

  /// ### 구글 피트니스 데이터 받아오기 버튼 선택시
  void _onTapFitnessPatch() async{
    bool granted = _healthHelper?.isAuth ?? false;
    if (!granted) {
      bool isAuth = await _healthHelper?.requestPermission() ?? false;
      print(isAuth);
    }
    // fetch data
    int step = await _healthHelper!.getTodayStep();
    if (mounted) setState(() => _healthStep = step);
  }

  /// iOS 데이터 받아오기 버튼 선택시
  void _onTapHealthPatch() async{
    bool granted = _healthHelper?.isAuth ?? false;
    if (!granted) {
      bool isAuth = await _healthHelper?.requestPermission() ?? false;
      print(isAuth);
    }
    int step = await _healthHelper!.getTodayStep();
    print("오늘 총 걸음수: $step}");
  }
}

