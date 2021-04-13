package co.kr.hunet.pedometer_sample;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class InstallManager implements MethodChannel.MethodCallHandler {
    // flutter 에서 InstallStatus 의 이넘 인덱스
    private static final int AVAILABLE = 0;
    private static final int INACTIVATE = 1;
    private static final int NOT_INSTALL = 2;

    // 연동 대상앱들의 패키지명
    private static final String SAMSUNG_HEALTH_PACKAGE_NAME = "com.sec.android.app.shealth";
    private static final String GOOGLE_FITNESS_PACKAGE_NAME = "com.google.android.apps.fitness";

    private final Context context;

    InstallManager(Context context) {
        this.context = context;
    }

    @SuppressWarnings("ConstantConditions")
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method){
            case "syncApp#installed" :
                int[] flags = getAvailableSyncApp();
                result.success(flags);
                break;
            case "open#store":
                int type = call.argument("target");
                String target = type == 0 ? SAMSUNG_HEALTH_PACKAGE_NAME : GOOGLE_FITNESS_PACKAGE_NAME;
                openStoreUrl(target);
                result.success(null);
                break;
        }
    }

    /**
     * <h3>연동 대상 어플리케이션의 사용가능 여부 확인<h3/>
     * <p>안드로이드의 경우 연동 대상 어플이 2가지가 있다. 아래는 해당 목록이다.</p>
     * <ol>
     *     <li>삼성 헬스</li>
     *     <li>구글 피트니스</li>
     * </ol>
     * <p>
     *     {@link PackageManager}를 통해서 설치된 어플리케이션의 목록을 확인하는데, 기본적으로 아무런 설정값 없이 검색을 한다.
     *     그러나 android api level 24 이후부터는 설치되었음에도, 비활성화인 상태의 어플리케이션 경우 설정값없이 검색하면 
     *     목록에 포함되지 않기 때문에 PackageManager.MATCH_DISABLED_COMPONENTS flag 를 사용해서 재검색한다. 
     * </p>
     * @return 설치상태를 의미하는 flag들. 
     */
    private int[] getAvailableSyncApp() {
        String[] checkList = new String[]{SAMSUNG_HEALTH_PACKAGE_NAME, GOOGLE_FITNESS_PACKAGE_NAME};

        PackageManager pm = context.getPackageManager();
        int[] installFlags =  new int[2];

        for (int i = 0; i < checkList.length; i++) {
            boolean installCheckNoFlag = isInstalled(pm, checkList[i], 0);
            if (installCheckNoFlag) {
                installFlags[i] = AVAILABLE;
                continue;
            }
            // 플래그 없이 확인시 (비활성 상태의 앱은 반환하지 않는다.) false이면, 비활성 여부확인
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // 비활성을 포함하여 결과 확인
                boolean installCheckWithFlag = isInstalled(pm, checkList[i], PackageManager.MATCH_DISABLED_COMPONENTS);
                if (installCheckWithFlag) installFlags[i] = INACTIVATE;
                else installFlags[i] = NOT_INSTALL;
            }
        }
        return installFlags;
    }

    /**
     * 특정 파키지명을 통해 설치됫는지 확인하는 함수
     * @param pm {@link PackageManager}객체
     * @param packageName 확인하고자 하는 패키지의 풀네임
     * @param flag 설정값.
     * @return flag를 통해 검색한 결과값.
     */
    private boolean isInstalled(PackageManager pm, String packageName, int flag) {
        try {
            pm.getApplicationInfo(packageName, flag);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    /**
     * 연동하고자 하는 어플이 사용가능하지 않은 경우, play store 로 연결해서 설치 및 사용을 유도한다.
     *
     * @param packageName 연동하고자 하는 어플리케이션의 패키지명
     */
    private void openStoreUrl(String packageName) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse(
                "https://play.google.com/store/apps/details?id=" + packageName));
        intent.setPackage("com.android.vending");
        try {
            context.startActivity(intent);
        } catch (ActivityNotFoundException e) {
            log("play store 없는 에뮬레이터에서 실행하려다 딱걸림");
        }
    }



    private void log(String msg) {
        Log.i("CHECK#INSTALL", msg);
    }
}
