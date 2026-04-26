package com.system.pro.builder;   // ← اپنے پیکیج نام سے بدلیں

import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // فرض کیا کہ activity_main میں btnSettings نامی بٹن موجود ہے
        View settingsBtn = findViewById(R.id.btnSettings);
        if (settingsBtn != null) {
            settingsBtn.setOnClickListener(v -> showSettingsDialog());
        }
    }

    private void showSettingsDialog() {
        View dialogView = getLayoutInflater().inflate(R.layout.dialog_settings, null);
        EditText etAppName = dialogView.findViewById(R.id.etAppName);
        EditText etPkgName = dialogView.findViewById(R.id.etPkgName);
        EditText etGhToken = dialogView.findViewById(R.id.etGhToken);
        EditText etGhRepo = dialogView.findViewById(R.id.etGhRepo);

        new AlertDialog.Builder(this)
                .setTitle("Settings")
                .setView(dialogView)
                .setPositiveButton("Save", null)
                .setNegativeButton("Cancel", null)
                .show();
    }
}
