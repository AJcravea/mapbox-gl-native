package com.mapbox.mapboxsdk.testapp.activity.fragment;

import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.FragmentTransaction;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.MenuItem;

import com.mapbox.mapboxsdk.camera.CameraPosition;
import com.mapbox.mapboxsdk.camera.CameraUpdateFactory;
import com.mapbox.mapboxsdk.constants.Style;
import com.mapbox.mapboxsdk.geometry.LatLng;
import com.mapbox.mapboxsdk.maps.MapboxMap;
import com.mapbox.mapboxsdk.maps.MapboxMapOptions;
import com.mapbox.mapboxsdk.maps.OnMapReadyCallback;
import com.mapbox.mapboxsdk.maps.SupportMapFragment;
import com.mapbox.mapboxsdk.testapp.R;

public class SupportMapFragmentActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_map_fragment);

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayHomeAsUpEnabled(true);
            actionBar.setDisplayShowHomeEnabled(true);
        }

        SupportMapFragment mapFragment;
        if (savedInstanceState == null) {
            FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();

            MapboxMapOptions options = new MapboxMapOptions();
            options.accessToken(getString(R.string.mapbox_access_token));
            options.styleUrl(Style.SATELLITE_STREETS);

            options.scrollGesturesEnabled(false);
            options.zoomGesturesEnabled(false);
            options.tiltGesturesEnabled(false);
            options.rotateGesturesEnabled(false);

            options.debugActive(false);
            options.compassEnabled(false);
            options.attributionEnabled(false);
            options.logoEnabled(false);

            LatLng dc = new LatLng(38.90252, -77.02291);

            options.minZoom(9);
            options.maxZoom(11);
            options.camera(new CameraPosition.Builder()
                    .target(dc)
                    .zoom(11)
                    .build());

            mapFragment = SupportMapFragment.newInstance(options);

            transaction.add(R.id.fragment_container, mapFragment, "com.mapbox.map");
            transaction.commit();
        } else {
            mapFragment = (SupportMapFragment) getSupportFragmentManager().findFragmentByTag("com.mapbox.map");
        }

        mapFragment.getMapAsync(new OnMapReadyCallback() {
            @Override
            public void onMapReady(@NonNull MapboxMap mapboxMap) {
                mapboxMap.animateCamera(CameraUpdateFactory.newCameraPosition(new CameraPosition.Builder().tilt(45.0).build()), 10000);
            }
        });
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                onBackPressed();
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }
}
