package com.example.torchsos; // اپنا پیکیج نام تبدیل کریں

import android.Manifest;
import android.content.pm.PackageManager;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraManager;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

public class MainActivity extends AppCompatActivity {

    private CameraManager cameraManager;
    private String cameraId;
    private boolean isFlashOn = false;
    private Handler handler = new Handler();
    private Runnable sosRunnable;
    private boolean sosActive = false;

    private Button btnSOS, btnOff;

    private static final int CAMERA_REQUEST_CODE = 100;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btnSOS = findViewById(R.id.btnSOS);
        btnOff = findViewById(R.id.btnOff);

        cameraManager = (CameraManager) getSystemService(CAMERA_SERVICE);
        try {
            cameraId = cameraManager.getCameraIdList()[0]; // عام طور پر بیک کیمرا
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }

        // پرمیشن چیک کریں
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.CAMERA}, CAMERA_REQUEST_CODE);
        }

        btnSOS.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startSOS();
            }
        });

        btnOff.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                stopSOS();
                turnFlashOff();
            }
        });
    }

    private void startSOS() {
        if (sosActive) return;
        sosActive = true;
        btnSOS.setEnabled(false);
        btnOff.setEnabled(true);

        // SOS پیٹرن: 3 چھوٹی، 3 لمبی، 3 چھوٹی (ڈاٹ = 200ms، ڈیش = 600ms)
        sosRunnable = new Runnable() {
            int step = 0;
            long[] pattern = {200, 200, 200, 600, 600, 600, 200, 200, 200}; // آن کے اوقات
            long[] offPattern = {200, 200, 200, 600, 600, 600, 200, 200, 200}; // آف کے اوقات (وقفے)

            @Override
            public void run() {
                if (!sosActive) return;

                if (step < pattern.length) {
                    turnFlashOn();
                    handler.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            turnFlashOff();
                            handler.postDelayed(this, offPattern[step]); // اگلے مرحلے کا انتظار
                        }
                    }, pattern[step]);

                    step++;
                    handler.postDelayed(this, pattern[step-1] + offPattern[step-1]);
                } else {
                    // دہرانے کے لیے دوبارہ شروع کریں
                    step = 0;
                    handler.post(this);
                }
            }
        };
        handler.post(sosRunnable);
    }

    private void stopSOS() {
        sosActive = false;
        btnSOS.setEnabled(true);
        btnOff.setEnabled(false);
        handler.removeCallbacks(sosRunnable);
    }

    private void turnFlashOn() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                cameraManager.setTorchMode(cameraId, true);
                isFlashOn = true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void turnFlashOff() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                cameraManager.setTorchMode(cameraId, false);
                isFlashOn = false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == CAMERA_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "کیمرا پرمیشن مل گیا", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "پرمیشن کے بغیر ٹارچ کام نہیں کرے گی", Toast.LENGTH_LONG).show();
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopSOS();
        turnFlashOff();
    }
}