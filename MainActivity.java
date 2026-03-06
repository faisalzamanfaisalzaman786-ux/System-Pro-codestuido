package com.example.systempro;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button actionButton = findViewById(R.id.actionButton);

        actionButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // یہاں آپ اپنی ایپ کا کوئی بھی فنکشن لکھ سکتے ہیں
                Toast.makeText(MainActivity.this, "سسٹم پرو ایکٹیویٹ ہو گیا ہے!", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
