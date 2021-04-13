package co.kr.hunet.pedometer_sample;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
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

    private final Context context;

    InstallManager(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method){
            case "syncApp#installed" :
                int[] flags = getAvailableSyncApp();
                result.success(flags);
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
        final String samsungHealthPackageName = "com.sec.android.app.shealth";
        final String googleFitnessPackageName = "com.google.android.apps.fitness";
        String[] checkList = new String[]{samsungHealthPackageName, googleFitnessPackageName};

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

    private void log(String msg) {
        Log.i("CHECK#INSTALL", msg);
    }
}
