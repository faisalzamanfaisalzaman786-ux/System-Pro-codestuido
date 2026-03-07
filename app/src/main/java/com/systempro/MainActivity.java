package com.systempro;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // یہ لائن آپ کی XML فائل کو جاوا سے جوڑتی ہے
        setContentView(R.layout.activity_main);
    }
}
