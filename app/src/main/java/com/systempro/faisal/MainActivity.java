package com.systempro.faisal;;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // یہاں ہم فی الحال سادہ کوڈ رکھ رہے ہیں تاکہ بلڈ کامیاب ہو
        android.widget.TextView tv = new android.widget.TextView(this);
        tv.setText("System Pro is Running!");
        setContentView(tv);
    }
}
