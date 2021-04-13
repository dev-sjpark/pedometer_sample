import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:pedometer_sample/dto/application_info.dart';
import 'package:pedometer_sample/util/install_manager.dart';

void main() {
  runApp(PedometerSampleApp());
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

  @override
  void initState() {
    checkApplicationState();
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  void checkApplicationState(){
    if (mounted) {
      setState(() => _appInfo = Completer());
    }
    installManger.checkSyncAppInstalled().then((list) => _appInfo.complete(list));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
      floatingActionButton: _fab(),
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

  /// 플로팅 액션 버튼
  _fab() => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: FloatingActionButton(
      onPressed: onRefresh,
      child: Icon(Icons.refresh),
    ),
  );

  /// 바디 영역
  _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _platformInfo(),
      _statusChecker(),
    ],
  );

  /// 바디 최상단 플렛폼의 종류를 표시
  _platformInfo() => Container(
    padding: EdgeInsets.all(16),
    child: Text(
      Platform.isAndroid ? 'ANDROID' : 'iOS',
      textAlign: TextAlign.center,
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
        padding: EdgeInsets.all(16),
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
                color: Theme.of(context).primaryColor,
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

}

/// ### [_HomeState]에서 사용되는 각 콜백들의 모음
extension CallBacks on _HomeState {

  /// 플로팅 액션 버튼에 대한 클릭이벤트
  void onRefresh(){

  }

  /// ### store Url 버튼의 온탭 이벤트
  /// 사용가능하지 않은 어플리케이션의 경우 play store 로 연결
  void _onTapPlayStore(SyncTarget target) {
    installManger.openStoreUrl(target);
  }

}

