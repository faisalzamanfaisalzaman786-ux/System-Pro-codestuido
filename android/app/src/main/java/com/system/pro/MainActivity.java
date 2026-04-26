package com.system.pro;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;

public class MainActivity extends AppCompatActivity {

    private Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // App started successfully
        showToast("Welcome to System Pro");
    }

    private void showToast(String message) {
        mainHandler.post(() -> Toast.makeText(MainActivity.this, message, Toast.LENGTH_SHORT).show());
    }

    // Fixed Method for Download/Connection logic
    private void checkConnection(HttpURLConnection conn) {
        new Thread(() -> {
            try {
                // Handling potential IOException here
                int responseCode = conn.getResponseCode();
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    showToast("Connection Successful");
                } else {
                    showToast("Connection Failed: " + responseCode);
                }
            } catch (IOException e) {
                e.printStackTrace();
                showToast("Network Error: Please check your internet");
            }
        }).start();
    }
}
