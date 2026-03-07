package com.systempro;

import android.os.Bundle;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        findViewById(R.id.mainButton).setOnClickListener(v -> {
            Toast.makeText(this, "System Pro: Operations Online", Toast.LENGTH_SHORT).show();
        });
    }
}