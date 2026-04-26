<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="App Name"
        android:textColor="#00FFCC"
        android:layout_marginBottom="4dp" />

    <EditText
        android:id="@+id/etAppName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:background="#030617"
        android:textColor="#ffffff"
        android:padding="8dp"
        android:layout_marginBottom="12dp" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Package ID"
        android:textColor="#00FFCC"
        android:layout_marginBottom="4dp" />

    <EditText
        android:id="@+id/etPkgName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:background="#030617"
        android:textColor="#ffffff"
        android:padding="8dp"
        android:layout_marginBottom="12dp" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="GitHub Token (ghp_...)"
        android:textColor="#00FFCC"
        android:layout_marginBottom="4dp" />

    <EditText
        android:id="@+id/etGhToken"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:background="#030617"
        android:textColor="#ffffff"
        android:padding="8dp"
        android:layout_marginBottom="12dp"
        android:inputType="textPassword" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Repository (owner/name)"
        android:textColor="#00FFCC"
        android:layout_marginBottom="4dp" />

    <EditText
        android:id="@+id/etGhRepo"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:background="#030617"
        android:textColor="#ffffff"
        android:padding="8dp"
        android:layout_marginBottom="12dp" />

</LinearLayout>
