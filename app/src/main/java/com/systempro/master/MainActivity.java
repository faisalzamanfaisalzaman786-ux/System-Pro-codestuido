package com.systempro.master;

import android.os.Bundle;
import android.widget.Button;
import android.widget.ImageView;
import androidx.appcompat.app.AppCompatActivity;
// مخصوص R پیکیج کو امپورٹ کرنا ضروری ہے
import com.systempro.master.R;

public class MainActivity extends AppCompatActivity {

    private ImageView imageView;

    @Override
    protected void Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // یہاں اب R پیکیج کا ایرر نہیں آئے گا
        setContentView(R.layout.activity_main);

        imageView = findViewById(R.id.capturedImage);
        Button btn = findViewById(R.id.actionButton);
        
        // آپ کی مزید لاجک یہاں آئے گی
    }
}
