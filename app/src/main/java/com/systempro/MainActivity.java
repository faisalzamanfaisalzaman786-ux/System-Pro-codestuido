package com.systempro;

import android.content.Context;
import android.content.Intent;
import android.hardware.camera2.CameraManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.widget.Button;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private boolean isFlashOn = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // پرمیشن چیک کریں
        checkPermissions();

        // بٹنوں کو کوڈ سے جوڑیں
        Button btnFlash = findViewById(R.id.btnFlash);
        Button btnSettings = findViewById(R.id.btnSettings);
        Button btnFiles = findViewById(R.id.btnFiles);

        // ٹارچ جلانے کا کوڈ
        btnFlash.setOnClickListener(v -> toggleFlashlight());

        // سسٹم سیٹنگز کھولنے کا کوڈ
        btnSettings.setOnClickListener(v -> {
            startActivity(new Intent(Settings.ACTION_SETTINGS));
        });

        // فائل مینیجر کی پرمیشن اور رسائی
        btnFiles.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (!android.os.Environment.isExternalStorageManager()) {
                    Intent intent = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
                    startActivity(intent);
                } else {
                    Toast.makeText(this, "فائل مینیجر تک رسائی موجود ہے", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    private void toggleFlashlight() {
        CameraManager cameraManager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
        try {
            String cameraId = cameraManager.getCameraIdList()[0];
            isFlashOn = !isFlashOn;
            cameraManager.setTorchMode(cameraId, isFlashOn);
            Toast.makeText(this, isFlashOn ? "ٹارچ آن ہو گئی" : "ٹارچ آف ہو گئی", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            Toast.makeText(this, "ٹارچ کام نہیں کر رہی", Toast.LENGTH_SHORT).show();
        }
    }

    private void checkPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.System.canWrite(this)) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
                intent.setData(Uri.parse("package:" + getPackageName()));
                startActivity(intent);
            }
        }
    }
}