package com.systempro.main;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.view.Gravity;
public class MainActivity extends Activity {
    @Override protected void onCreate(Bundle saved) {
        super.onCreate(saved);
        TextView tv = new TextView(this);
        tv.setText("System Pro Native App\nSuccessfully Built!");
        tv.setTextSize(24);
        tv.setGravity(Gravity.CENTER);
        setContentView(tv);
    }
}
