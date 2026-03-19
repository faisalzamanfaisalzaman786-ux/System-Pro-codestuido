package com.systempro.appyz48c4s;

import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.Button;
import android.widget.RelativeLayout;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;
import java.util.Random;

public class MainActivity extends AppCompatActivity {

    private TextView clockText;
    private TextView dateText;
    private TextView infoText;
    private RelativeLayout mainLayout;
    private Handler handler = new Handler();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // ویوز کو آئی ڈی کے ذریعے جوڑنا
        mainLayout = findViewById(R.id.mainLayout);
        clockText = findViewById(R.id.clockText);
        dateText = findViewById(R.id.dateText);
        infoText = findViewById(R.id.infoText);
        Button changeColorButton = findViewById(R.id.changeColorButton);

        // گھڑی شروع کرنا
        startClock();

        // بٹن پر کلک کرنے کا فنکشن (رنگ بدلنے کے لیے)
        if (changeColorButton != null) {
            changeColorButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    Random random = new Random();
                    int color = Color.argb(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
                    
                    mainLayout.setBackgroundColor(color);
                    infoText.setText("رنگ کامیابی سے تبدیل ہو گیا!");
                    infoText.setTextColor(Color.WHITE);
                }
            });
        }
    }

    private void startClock() {
        handler.post(new Runnable() {
            @Override
            public void run() {
                Calendar calendar = Calendar.getInstance();
                SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm:ss", Locale.getDefault());
                SimpleDateFormat dateFormat = new SimpleDateFormat("EEEE, d MMMM", Locale.getDefault());

                if (clockText != null) clockText.setText(timeFormat.format(calendar.getTime()));
                if (dateText != null) dateText.setText(dateFormat.format(calendar.getTime()));

                handler.postDelayed(this, 1000);
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // میموری لیک سے بچنے کے لیے ہینڈلر کو روکنا
        handler.removeCallbacksAndMessages(null);
    }
}
