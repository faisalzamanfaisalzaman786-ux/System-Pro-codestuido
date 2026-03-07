package com.systempro;

import android.content.Context;
import android.content.Intent;
import android.hardware.camera2.CameraManager;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private boolean isFlashOn = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // بغیر XML کے ڈیزائن بنانا (Dynamic UI)
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER);
        layout.setPadding(50, 50, 50, 50);

        // 1. ٹارچ کا بٹن
        Button btnFlash = new Button(this);
        btnFlash.setText("🔦 ٹارچ آن/آف کریں");
        btnFlash.setOnClickListener(v -> toggleFlash());
        layout.addView(btnFlash);

        // 2. وائی فائی سیٹنگز کا بٹن
        Button btnWifi = new Button(this);
        btnWifi.setText("📶 وائی فائی سیٹنگز");
        btnWifi.setOnClickListener(v -> {
            startActivity(new Intent(Settings.ACTION_WIFI_SETTINGS));
        });
        layout.addView(btnWifi);

        // 3. کیمرہ کھولنے کا بٹن
        Button btnCam = new Button(this);
        btnCam.setText("📷 کیمرہ کھولیں");
        btnCam.setOnClickListener(v -> {
            Intent intent = new Intent("android.media.action.IMAGE_CAPTURE");
            startActivity(intent);
        });
        layout.addView(btnCam);

        setContentView(layout);
    }

    private void toggleFlash() {
        CameraManager camManager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
        try {
            String cameraId = camManager.getCameraIdList()[0];
            isFlashOn = !isFlashOn;
            camManager.setTorchMode(cameraId, isFlashOn);
            Toast.makeText(this, isFlashOn ? "آن" : "آف", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            Toast.makeText(this, "خرابی: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }
}