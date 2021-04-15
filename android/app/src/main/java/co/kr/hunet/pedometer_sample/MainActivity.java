package co.kr.hunet.pedometer_sample;


import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.fitness.Fitness;
import com.google.android.gms.fitness.FitnessOptions;
import com.google.android.gms.fitness.data.DataPoint;
import com.google.android.gms.fitness.data.DataType;
import com.google.android.gms.fitness.data.Field;
import com.google.android.gms.fitness.request.DataReadRequest;

import java.util.HashMap;
import java.util.List;
import java.util.concurrent.TimeUnit;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity implements MethodChannel.MethodCallHandler {
    private static final int GOOGLE_FIT_REQUEST_CODE = 427;
    private static final int DEVICE_PERMISSION_REQUEST_CODE = 349;

    HashMap<Integer, MethodChannel.Result> resultToComplete = new HashMap<>();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        final String installManagerChannelName = "kr.co.hunet.pedometer_sample";
        MethodChannel installManager = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), installManagerChannelName);
        installManager.setMethodCallHandler(new InstallManager(this));
        
        final String fitnessChannelName = "co.kr.hunet.pedometer_sample/fitness";
        MethodChannel fitnessChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), fitnessChannelName);
        fitnessChannel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method){
            case "request#auth" :
                resultToComplete.put(GOOGLE_FIT_REQUEST_CODE, result);
                requestAuthorization();
                break;
            case "request#permission" :
                // android 10 이상부터 기기의 권한
                resultToComplete.put(DEVICE_PERMISSION_REQUEST_CODE, result);
                requestDevicePermission();
                break;
            case "fetch#data" :
                getData(call, result);
                break;
        }
    }

    // 구글의 GCP 인증
    private void requestAuthorization() {
        FitnessOptions fitnessOptions = getOptions();
        boolean isGranted = GoogleSignIn.hasPermissions(GoogleSignIn.getLastSignedInAccount(this), fitnessOptions);
        if (!isGranted) {
            GoogleSignIn.requestPermissions(
                    this, GOOGLE_FIT_REQUEST_CODE,
                    GoogleSignIn.getLastSignedInAccount(this), fitnessOptions);
        } else {
            MethodChannel.Result result = resultToComplete.get(GOOGLE_FIT_REQUEST_CODE);
            if (result != null)
                result.success(true);
            resultToComplete.remove(GOOGLE_FIT_REQUEST_CODE);
        }
    }

    /// 10 이상부터 기기 권한
    private void requestDevicePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q){
            if (checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION)
                    != PackageManager.PERMISSION_GRANTED){
                requestPermissions(new String[]{Manifest.permission.ACTIVITY_RECOGNITION},
                        DEVICE_PERMISSION_REQUEST_CODE);
                return;
            }
        }
        MethodChannel.Result result = resultToComplete.get(DEVICE_PERMISSION_REQUEST_CODE);
        if (result != null)
            result.success(true);
        resultToComplete.remove(DEVICE_PERMISSION_REQUEST_CODE);
    }
    
    private FitnessOptions getOptions() {
        return FitnessOptions.builder()
                .addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
                .addDataType(DataType.AGGREGATE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
                .build();
    }
    
    private void getData(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        new Thread(){
            @Override
            public void run() {
                try {
                    GoogleSignInAccount account = GoogleSignIn.getAccountForExtension(MainActivity.this, getOptions());
                    Fitness.getHistoryClient(MainActivity.this, account)
                            .readDailyTotal(DataType.TYPE_STEP_COUNT_DELTA)
                            .addOnSuccessListener((res) -> {
//                                List<DataPoint> pointList = res.getDataPoints();
//                                for (DataPoint point : pointList) {
//                                    Log.i("피트니스", "--");
//                                    Log.i("피트니스", "type: " + point.getDataType());
//                                    List<Field> fields = point.getDataType().getFields();
//                                    for (Field f : fields) {
//                                        Log.i("피트니스","\t feild: " + f.getName() + ", value: " + point.getValue(f));
//                                    }
//                                    Log.i("피트니스", "--");
//                                }

                                DataPoint today = res.getDataPoints().get(0);
                                List<Field> fields = today.getDataType().getFields();
                                for (Field f : fields) {
                                    if (f.getName().equals("steps")) {
                                        runOnUiThread(() -> result.success(today.getValue(f).asInt()));
                                    }
                                }
                            })
                            .addOnFailureListener( e -> {
                                runOnUiThread(() -> result.error(e.getLocalizedMessage(), null, null));
                            });
                } catch (Exception e) {
                    runOnUiThread(() -> result.error(e.getLocalizedMessage(), "android fitness getData", null));
                }
            }
        }.start();
    }

    private DataReadRequest getRequest() {
        return new DataReadRequest.Builder()
                .aggregate(DataType.AGGREGATE_STEP_COUNT_DELTA)
                .bucketByTime(1, TimeUnit.DAYS)
                .build();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == GOOGLE_FIT_REQUEST_CODE && resultToComplete.containsKey(requestCode)) {
            MethodChannel.Result result = resultToComplete.get(requestCode);
            if (result == null) return;

            if (resultCode == Activity.RESULT_OK) {
                result.success(true);
            } else if (resultCode == Activity.RESULT_CANCELED) {
                result.success(false);
            }
            resultToComplete.remove(GOOGLE_FIT_REQUEST_CODE);
        } else if (requestCode == DEVICE_PERMISSION_REQUEST_CODE && resultToComplete.containsKey(requestCode)) {
            MethodChannel.Result result = resultToComplete.get(requestCode);
            if (result == null) return;

            if (resultCode == Activity.RESULT_OK) {
                result.success(true);
            } else if (resultCode == Activity.RESULT_CANCELED) {
                result.success(false);
            }
            resultToComplete.remove(DEVICE_PERMISSION_REQUEST_CODE);
        }
    }
}
