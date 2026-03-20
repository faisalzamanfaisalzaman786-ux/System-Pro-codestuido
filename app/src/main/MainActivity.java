package com. systempro.dynamic;

import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.widget.RelativeLayout;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private RelativeLayout mainLayout;
    private TextView infoText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // IDs کو یہاں جوڑا گیا ہے
        mainLayout = findViewById(R.id.mainLayout);
        infoText = findViewById(R.id.infoText);
        Button changeColorButton = findViewById(R.id.changeColorButton);

        if (changeColorButton != null) {
            changeColorButton.setOnClickListener(v -> {
                infoText.setText("System Pro Working!");
            });
        }
    }
}
