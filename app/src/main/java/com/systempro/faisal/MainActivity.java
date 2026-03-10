package com.systempro.faisal;

import android.content.Context;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraManager;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

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
        try {
            // بیک کیمرہ کی ID حاصل کریں
            cameraId = cameraManager.getCameraIdList()[0];
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }

        btnTorch.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                switchFlashlight();
            }
        });
    }

    private void switchFlashlight() {
        try {
            if (!isFlashOn) {
                cameraManager.setTorchMode(cameraId, true);
                isFlashOn = true;
                btnTorch.setText("OFF");
                btnTorch.setBackgroundTintList(android.content.res.ColorStateList.valueOf(0xFF00E676)); // Green
                statusText.setText("Flashlight is ON");
            } else {
                cameraManager.setTorchMode(cameraId, false);
                isFlashOn = false;
                btnTorch.setText("ON");
                btnTorch.setBackgroundTintList(android.content.res.ColorStateList.valueOf(0xFF2D3748)); // Dark Grey
                statusText.setText("Flashlight is OFF");
            }
        } catch (CameraAccessException e) {
            Toast.makeText(this, "Error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }
}