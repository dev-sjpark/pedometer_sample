package co.kr.hunet.pedometer_sample;


import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        final String installManagerChannelName = "kr.co.hunet.pedometer_sample";
        MethodChannel installManager = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), installManagerChannelName);
        installManager.setMethodCallHandler(new InstallManager(this));
    }
}
