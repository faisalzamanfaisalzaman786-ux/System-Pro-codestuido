package com.systempro.faisal;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import okhttp3.*;
import org.json.JSONObject;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // ڈائنامک طریقے سے آئی ڈیز ڈھونڈنا تاکہ ایرر نہ آئے
        final EditText pkgInput = findViewById(getResources().getIdentifier("num1", "id", getPackageName()));
        final EditText nameInput = findViewById(getResources().getIdentifier("num2", "id", getPackageName()));
        Button buildBtn = findViewById(getResources().getIdentifier("add", "id", getPackageName()));

        buildBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String pkgName = pkgInput.getText().toString();
                String appName = nameInput.getText().toString();

                if (!pkgName.isEmpty() && !appName.isEmpty()) {
                    sendBuildRequest(pkgName, appName);
                } else {
                    Toast.makeText(MainActivity.this, "تمام خانے پُر کریں", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    private void sendBuildRequest(String pkg, String name) {
        OkHttpClient client = new OkHttpClient();
        
        // یہاں اپنا اصلی ٹوکن لازمی ڈالیں
        String token = "YOUR_GITHUB_TOKEN_HERE"; 

        try {
            JSONObject json = new JSONObject();
            json.put("event_type", "build_new_apk");
            JSONObject clientPayload = new JSONObject();
            clientPayload.put("package_name", pkg);
            clientPayload.put("app_name", name);
            json.put("client_payload", clientPayload);

            RequestBody body = RequestBody.create(
                json.toString(),
                MediaType.get("application/json; charset=utf-8")
            );

            Request request = new Request.Builder()
                .url("https://api.github.com/repos/faisalzamanfaisalzaman786-ux/System-Pro-codestuido/dispatches")
                .post(body)
                .addHeader("Authorization", "Bearer " + token)
                .addHeader("Accept", "application/vnd.github.v3+json")
                .build();

            client.newCall(request).enqueue(new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    runOnUiThread(() -> Toast.makeText(MainActivity.this, "سگنل فیل ہو گیا", Toast.LENGTH_LONG).show());
                }

                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    runOnUiThread(() -> Toast.makeText(MainActivity.this, "بلڈ شروع ہو گیا ہے!", Toast.LENGTH_LONG).show());
                }
            });

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
