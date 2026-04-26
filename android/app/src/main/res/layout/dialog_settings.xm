<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView android:text="App Name" android:textColor="#00FFCC" android:layout_marginBottom="4dp"/>
    <EditText android:id="@+id/etAppName" android:background="#030617" android:textColor="#ffffff" android:padding="8dp" android:layout_marginBottom="12dp"/>

    <TextView android:text="Package ID" android:textColor="#00FFCC" android:layout_marginBottom="4dp"/>
    <EditText android:id="@+id/etPkgName" android:background="#030617" android:textColor="#ffffff" android:padding="8dp" android:layout_marginBottom="12dp"/>

    <TextView android:text="GitHub Token (ghp_...)" android:textColor="#00FFCC" android:layout_marginBottom="4dp"/>
    <EditText android:id="@+id/etGhToken" android:background="#030617" android:textColor="#ffffff" android:padding="8dp" android:layout_marginBottom="12dp" android:inputType="textPassword"/>

    <TextView android:text="Repository (owner/name)" android:textColor="#00FFCC" android:layout_marginBottom="4dp"/>
    <EditText android:id="@+id/etGhRepo" android:background="#030617" android:textColor="#ffffff" android:padding="8dp" android:layout_marginBottom="12dp"/>
</LinearLayout>
