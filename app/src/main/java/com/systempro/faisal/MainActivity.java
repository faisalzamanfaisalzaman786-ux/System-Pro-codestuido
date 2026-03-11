package com.systempro.faisal;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraManager;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

public class MainActivity extends AppCompatActivity {

    private static final int CAMERA_PERMISSION_CODE = 100;
    private Button btnTorch;
    private TextView statusText;
    private boolean isFlashOn = false;
    private CameraManager cameraManager;
    private String cameraId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btnTorch = findViewById(R.id.btn_torch);
        statusText = findViewById(R.id.status_text);

        cameraManager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);

        // Check if device has flash
        if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
            Toast.makeText(this, "آپ کے ڈیوائس میں فلاش نہیں ہے", Toast.LENGTH_LONG).show();
            btnTorch.setEnabled(false);
            return;
        }

        // Get camera ID (usually back camera)
        try {
            cameraId = cameraManager.getCameraIdList()[0];
        } catch (CameraAccessException e) {
            e.printStackTrace();
            Toast.makeText(this, "کیمرہ تک رسائی ممکن نہیں", Toast.LENGTH_SHORT).show();
        }

        // Request camera permission for Android 6+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                    != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.CAMERA},
                        CAMERA_PERMISSION_CODE);
            }
        }

        btnTorch.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                switchFlashlight();
            }
        });
    }

    private void switchFlashlight() {
        if (cameraId == null) return;

        try {
            if (!isFlashOn) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    cameraManager.setTorchMode(cameraId, true);
                }
                isFlashOn = true;
                btnTorch.setText("OFF");
                btnTorch.setBackgroundTintList(ContextCompat.getColorStateList(this, android.R.color.holo_green_dark));
                statusText.setText("Flashlight is ON");
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    cameraManager.setTorchMode(cameraId, false);
                }
                isFlashOn = false;
                btnTorch.setText("ON");
                btnTorch.setBackgroundTintList(ContextCompat.getColorStateList(this, R.color.dark_grey));
                statusText.setText("Flashlight is OFF");
            }
        } catch (CameraAccessException e) {
            Toast.makeText(this, "خرابی: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == CAMERA_PERMISSION_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "کیمرے کی اجازت مل گئی", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "کیمرے کی اجازت ضروری ہے", Toast.LENGTH_LONG).show();
                btnTorch.setEnabled(false);
            }
        }
    }
}