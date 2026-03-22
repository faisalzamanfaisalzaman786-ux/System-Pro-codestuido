// ضروری امپورٹس شامل کریں
import android.content.Intent;
import android.graphics.Bitmap;
import android.provider.MediaStore;
import android.widget.ImageView;

// کلاس کے اندر یہ میتھڈ اور ویری ایبلز شامل کریں
private static final int CAMERA_REQUEST = 1888;
private ImageView imageView;

// onCreate کے اندر بٹن کلک میں یہ لاجک ڈالیں
imageView = findViewById(R.id.capturedImage);
myButton.setOnClickListener(new View.OnClickListener() {
    @Override
    public void onClick(View v) {
        Intent cameraIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        startActivityForResult(cameraIntent, CAMERA_REQUEST);
    }
});

// تصویر واپس لینے کے لیے یہ فنکشن شامل کریں
@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == CAMERA_REQUEST && resultCode == Activity.RESULT_OK) {
        Bitmap photo = (Bitmap) data.getExtras().get("data");
        imageView.setImageBitmap(photo);
    }
}
