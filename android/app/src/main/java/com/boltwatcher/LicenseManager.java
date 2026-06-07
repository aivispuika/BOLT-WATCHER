package com.boltwatcher;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

public class LicenseManager {

    private static final String TAG  = "BoltWatcher";
    private static final String PREFS = "boltwatcher";
    private static final String PREF_AUTO_NR   = "auto_nr";
    private static final String PREF_LICENSED  = "licensed";
    private static final String PREF_LAST_CHECK = "last_check";
    private static final long CHECK_INTERVAL_MS = 24 * 60 * 60 * 1000L;
    public  static final String APP_VERSION = "1.1";

    private static final String SHEETS_URL =
        "https://script.google.com/macros/s/AKfycbyCD2UjphebDijqxCOC76M0t6D-4LE7IT2aBUaur4wHp0PQbRVC4VREFIv7Bdp86PnNLQ/exec";

    public interface LicenseCallback { void onResult(boolean licensed); }

    public static boolean isLicensedLocally(Context ctx) {
        return ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                  .getBoolean(PREF_LICENSED, false);
    }

    public static void checkLicense(Context ctx, LicenseCallback cb) {
        SharedPreferences p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        String autoNr = p.getString(PREF_AUTO_NR, "");
        if (autoNr.isEmpty()) { cb.onResult(false); return; }

        long now = System.currentTimeMillis();
        if (now - p.getLong(PREF_LAST_CHECK, 0) < CHECK_INTERVAL_MS) {
            cb.onResult(p.getBoolean(PREF_LICENSED, false));
            return;
        }

        new Thread(() -> {
            boolean result = false;
            try {
                String url = SHEETS_URL
                    + "?auto_nr=" + URLEncoder.encode(autoNr, "UTF-8")
                    + "&version=" + URLEncoder.encode(APP_VERSION, "UTF-8");
                HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
                conn.setConnectTimeout(8000);
                conn.setReadTimeout(8000);
                conn.setInstanceFollowRedirects(true);
                BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                String resp = br.readLine(); br.close(); conn.disconnect();
                result = "OK".equals(resp != null ? resp.trim() : "");
            } catch (Exception e) {
                result = p.getBoolean(PREF_LICENSED, false);
            }
            final boolean r = result;
            p.edit().putBoolean(PREF_LICENSED, r).putLong(PREF_LAST_CHECK, now).apply();
            new Handler(Looper.getMainLooper()).post(() -> cb.onResult(r));
        }).start();
    }
}
