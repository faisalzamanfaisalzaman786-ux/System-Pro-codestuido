package com.systempro.faisal;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import okhttp3.*;
import java.io.IOException;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity {

    // اپنا ٹوکن یہاں لکھیں
    private static final String GITHUB_TOKEN = "آپ_کا_ٹوکن_یہاں_پیسٹ_کریں";
    private static final String REPO_OWNER = "faisalzaman";
    private static final String REPO_NAME = "System-Pro-codestuido";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        final EditText pkgInput = findViewById(R.id.num1); // ہم پیکج نیم کے لیے پہلا باکس استعمال کر رہے ہیں
        final EditText nameInput = findViewById(R.id.num2); // ایپ نیم کے لیے دوسرا باکس
        Button buildBtn = findViewById(R.id.add); // فی الحال پلس والے بٹن کو بلڈ بٹن بنا رہے ہیں

        buildBtn.setText("بنائیں APK");

        buildBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String pkg = pkgInput.getText().toString();
                String name = nameInput.getText().toString();
                
                if (!pkg.isEmpty() && !name.isEmpty()) {
                    sendBuildRequest(pkg, name);
                } else {
                    Toast.makeText(MainActivity.this, "پیکج اور نام لکھیں", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    private void sendBuildRequest(String pkg, String name) {
        OkHttpClient client = new OkHttpClient();
        
        try {
            JSONObject payload = new JSONObject();
            payload.put("event_type", "build_new_apk");
            
            JSONObject clientPayload = new JSONObject();
            clientPayload.put("package_name", pkg);
            clientPayload.put("app_name", name);
            payload.put("client_payload", clientPayload);

            RequestBody body = RequestBody.create(
                payload.toString(), 
                MediaType.get("application/json; charset=utf-8")
            );

            Request request = new Request.Builder()
                .url("https://api.github.com/repos/" + REPO_OWNER + "/" + REPO_NAME + "/dispatches")
                .addHeader("Authorization", "Bearer " + GITHUB_TOKEN)
                .addHeader("Accept", "application/vnd.github.v3+json")
                .post(body)
                .build();

            client.newCall(request).enqueue(new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    runOnUiThread(() -> Toast.makeText(MainActivity.this, "ناکام: " + e.getMessage(), Toast.LENGTH_LONG).show());
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
