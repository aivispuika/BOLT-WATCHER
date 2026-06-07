package com.boltwatcher;

import android.content.Intent;

import android.provider.Settings;
import android.view.accessibility.AccessibilityManager;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import android.accessibilityservice.AccessibilityServiceInfo;

public class MainActivity extends FlutterActivity {

    private static final String METHOD_CHANNEL = "com.boltwatcher/alerts";
    private static final String EVENT_CHANNEL  = "com.boltwatcher/alert_events";
    private static final String ACCESS_CHANNEL = "com.boltwatcher/accessibility";

    private EventChannel.EventSink alertEventSink;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // ── EventChannel — sūta brīdinājumus no AccessibilityService uz Flutter ──
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
            .setStreamHandler(new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object args, EventChannel.EventSink sink) {
                    alertEventSink = sink;
                    BoltAccessibilityService.setEventSink(sink);
                }
                @Override
                public void onCancel(Object args) {
                    alertEventSink = null;
                    BoltAccessibilityService.setEventSink(null);
                }
            });

        // ── MethodChannel — Flutter izsauc native metodes ──
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("acknowledgeAlert".equals(call.method)) {
                    String type  = call.argument("type");
                    String extra = call.argument("extra");
                    if (extra == null) extra = "";
                    handleAcknowledge(type, extra);
                    result.success(null);
                } else if ("getStatus".equals(call.method)) {
                    Map<String, Object> status = new HashMap<>();
                    status.put("alertIsShowing", BoltAccessibilityService.alertIsShowing);
                    result.success(status);
                } else {
                    result.notImplemented();
                }
            });

        // ── AccessibilityChannel — pārbauda vai serviss ir iespējots ──
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ACCESS_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("isEnabled".equals(call.method)) {
                    result.success(isAccessibilityEnabled());
                } else if ("openSettings".equals(call.method)) {
                    startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            });
    }

    private void handleAcknowledge(String type, String extra) {
        if (type == null) return;
        switch (type) {
            case BoltAccessibilityService.TYPE_WAIT_SAVE:
                BoltAccessibilityService.acknowledgedWaitSave = "wait_and_save"; break;
            case BoltAccessibilityService.TYPE_OUTSIDE:
                BoltAccessibilityService.acknowledgedOutside = extra; break;
            case BoltAccessibilityService.TYPE_LOW_VALUE:
                BoltAccessibilityService.acknowledgedLowValue = extra; break;
            case BoltAccessibilityService.TYPE_RESERVED_NEW:
                BoltAccessibilityService.acknowledgedReservedCount =
                    BoltAccessibilityService.lastReservedCountPublic; break;
            case BoltAccessibilityService.TYPE_KLONDAIKA:
                break; // atiestatās automātiski
        }
        BoltAccessibilityService.alertIsShowing = false;
    }

    private boolean isAccessibilityEnabled() {
        AccessibilityManager am = (AccessibilityManager) getSystemService(ACCESSIBILITY_SERVICE);
        if (am == null) return false;
        List<AccessibilityServiceInfo> svcs =
            am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK);
        for (AccessibilityServiceInfo s : svcs) {
            String id = s.getId();
            if (id != null && (id.contains("boltwatcher") || id.contains("com.boltwatcher")))
                return true;
        }
        return false;
    }
}
