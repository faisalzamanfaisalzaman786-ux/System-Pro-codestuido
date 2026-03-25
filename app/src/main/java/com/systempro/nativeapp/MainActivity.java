
package com.systempro.nativeapp;

import android.app.Activity;
import android.os.Bundle;
import android.widget.LinearLayout;
import android.widget.Button;
import android.widget.TextView;
import android.view.Gravity;
import android.graphics.Color;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle saved) {
        super.onCreate(saved);

        // پیور نیٹو لے آؤٹ بنانا
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER);
        layout.setBackgroundColor(Color.parseColor("#0d1117")); // آپ کا فیورٹ ڈارک تھیم

        TextView tv = new TextView(this);
        tv.setText("System Pro Native Ready!");
        tv.setTextColor(Color.WHITE);
        tv.setTextSize(24);
        tv.setPadding(0, 0, 0, 50);

        Button btn = new Button(this);
        btn.setText("Native Feature Test");
        btn.setBackgroundColor(Color.parseColor("#58a6ff"));
        btn.setTextColor(Color.WHITE);

        // بٹن پر کلک کرنے کا نیٹو ایکشن
        btn.setOnClickListener(v -> {
            tv.setText("Deep Access Enabled ✅");
            btn.setText("Success!");
        });

        layout.addView(tv);
        layout.addView(btn);
        setContentView(layout);
    }
}