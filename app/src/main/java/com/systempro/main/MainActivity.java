package com.systempro.counter;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private int counter = 0;
    private TextView countDisplay;
    private Button countButton, resetButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        countDisplay = findViewById(R.id.countText);
        countButton = findViewById(R.id.btnCount);
        resetButton = findViewById(R.id.btnReset);

        // Count increment logic
        countButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                counter++;
                countDisplay.setText(String.valueOf(counter));
            }
        });

        // Reset logic
        resetButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                counter = 0;
                countDisplay.setText(String.valueOf(counter));
            }
        });
    }
}