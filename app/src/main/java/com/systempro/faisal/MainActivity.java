package com.systempro.faisal;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // ڈیزائن سے چیزوں کو جوڑنا
        final EditText n1 = findViewById(R.id.num1);
        final EditText n2 = findViewById(R.id.num2);
        final TextView res = findViewById(R.id.result);

        // کیلکولیٹر کے بٹنوں کے لیے کلک لسٹر
        View.OnClickListener listener = new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                try {
                    double a = Double.parseDouble(n1.getText().toString());
                    double b = Double.parseDouble(n2.getText().toString());
                    double total = 0;

                    if (v.getId() == R.id.add) total = a + b;
                    else if (v.getId() == R.id.sub) total = a - b;
                    else if (v.getId() == R.id.mul) total = a * b;
                    else if (v.getId() == R.id.div) total = (b != 0) ? a / b : 0;

                    res.setText("نتیجہ: " + total);
                } catch (Exception e) {
                    res.setText("براہ کرم نمبر لکھیں");
                }
            }
        };

        // بٹنوں کو ایکٹیویٹ کرنا
        findViewById(R.id.add).setOnClickListener(listener);
        findViewById(R.id.sub).setOnClickListener(listener);
        findViewById(R.id.mul).setOnClickListener(listener);
        findViewById(R.id.div).setOnClickListener(listener);
    }
}
