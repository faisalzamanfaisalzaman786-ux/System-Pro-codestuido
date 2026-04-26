package com.system.pro; // Agar aap package badalte hain, to is line ko bhi badal dein

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Ye line layout file (activity_main.xml) ko connect karti hai
        // Ensure karein ke res/layout folder mein activity_main.xml maujood ho
        setContentView(R.layout.activity_main);
    }
}
