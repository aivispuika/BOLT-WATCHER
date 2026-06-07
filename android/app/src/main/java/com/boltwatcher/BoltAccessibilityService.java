package com.boltwatcher;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;



import io.flutter.plugin.common.EventChannel;


public class BoltAccessibilityService extends AccessibilityService {

    private static final String TAG = "BoltWatcher";
    private static final String BOLT_PACKAGE = "ee.mtakso.driver";

    // Flutter kanāli
    public static final String EVENT_CHANNEL_NAME  = "com.boltwatcher/alert_events";
    public static final String METHOD_CHANNEL_NAME = "com.boltwatcher/alerts";

    // Brīdinājumu tipi
    public static final String TYPE_WAIT_SAVE    = "wait_and_save";
    public static final String TYPE_OUTSIDE      = "outside_city";
    public static final String TYPE_LOW_VALUE    = "low_value";
    public static final String TYPE_RESERVED_NEW = "reserved_new";
    public static final String TYPE_KLONDAIKA    = "klondaika";

    // Stāvokļi
    private String lastWaitSaveContent  = "";
    private String lastOutsideContent   = "";
    private String lastLowValueContent  = "";
    static String acknowledgedWaitSave  = "";
    static String acknowledgedOutside   = "";
    static String acknowledgedLowValue  = "";
    static String acknowledgedKlondaika = "";
    static int    acknowledgedReservedCount = -1;
    static boolean alertIsShowing = false;
    static int lastReservedCountPublic = -1;

    private boolean reservedAvailableWasSeen = false;
    private int lastReservedCount = -1;

    // Regex
    private static final Pattern PRICE_PATTERN =
        Pattern.compile("(\\d+)[,\\.](\\d+)\\s*€");
    private static final Pattern DISTANCE_PATTERN =
        Pattern.compile("(\\d+)[,\\.](\\d+)\\s*km", Pattern.CASE_INSENSITIVE);
    private static final Pattern WAIT_SAVE_PATTERN =
        Pattern.compile("wait.{0,8}save", Pattern.CASE_INSENSITIVE);
    private static final Pattern INDEX_PATTERN =
        Pattern.compile("lv[\\s\\-](\\d{4})(?!\\d)", Pattern.CASE_INSENSITIVE);

    private static final int LIEPAJA_MIN = 3401, LIEPAJA_MAX = 3416;
    private static final int RIGA_MIN = 1001, RIGA_MAX = 1109;
    private static final double RESERVED_HIGH_PRICE = 15.0;

    private static final Set<String> LIEPAJA_SAFE_NAMES = new HashSet<>(Arrays.asList(
        "liepāja", "liepaja"
    ));
    private static final Set<String> LIEPAJA_OUTSIDE_NAMES = new HashSet<>(Arrays.asList(
        "grobiņa", "grobina", "aizpute", "kuldīga", "kuldiga",
        "skrunda", "saldus", "ventspils", "talsi", "tukums",
        "jelgava", "jūrmala", "jurmala", "rīga", "riga",
        "daugavpils", "rēzekne", "rezekne", "valmiera",
        "jēkabpils", "jekabpils", "dobele", "bauska", "ogre",
        "sigulda", "cēsis", "cesis", "limbaži", "limbazi",
        "nīca", "nica", "durbe", "pāvilosta", "pavilosta",
        "priekule", "vaiņode", "rucava", "bārta", "barta"
    ));
    private static final Set<String> RIGA_SAFE_NAMES = new HashSet<>(Arrays.asList(
        "rīga", "riga", "jūrmala", "jurmala",
        "ādaži", "adazi", "babīte", "babite", "baldone",
        "carnikava", "garkalne", "ikšķile", "ikskile",
        "inčukalns", "incukalns", "ķekava", "kekava",
        "mārupe", "marupe", "olaine", "ozolnieki",
        "ropaži", "ropazi", "salaspils", "saulkrasti",
        "stopiņi", "stopini", "ulbroka"
    ));
    private static final Set<String> RIGA_OUTSIDE_NAMES = new HashSet<>(Arrays.asList(
        "liepāja", "liepaja", "ventspils", "jelgava",
        "jēkabpils", "jekabpils", "valmiera", "daugavpils",
        "rēzekne", "rezekne", "aizpute", "kuldīga", "kuldiga",
        "skrunda", "saldus", "talsi", "tukums", "dobele",
        "bauska", "ogre", "cēsis", "cesis", "limbaži", "limbazi"
    ));

    private static final List<String> ORDER_CTX = Arrays.asList(
        "iela", "gatve", "bulvāris", "bulvaris", "prospekts",
        "šoseja", "soseja", "ceļš", "cels", "aleja", "laukums", "mols"
    );
    private static final int MIN_LINE_LENGTH = 5;

    // Flutter EventChannel sink — sūta brīdinājumus uz Flutter UI
    private static EventChannel.EventSink eventSink;

    public static void setEventSink(EventChannel.EventSink sink) {
        eventSink = sink;
    }

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        Log.d(TAG, "BoltAccessibilityService connected");


    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        String pkg = event.getPackageName() != null ? event.getPackageName().toString() : "";
        if (!pkg.equals(BOLT_PACKAGE)) return;


        int t = event.getEventType();
        if (t != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED &&
            t != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;

        List<List<String>> allWindows = collectAllWindows();
        if (allWindows.isEmpty()) return;

        long now = System.currentTimeMillis();
        boolean isLiepaja = "liepaja".equals(getCity());

        // 1. Wait and Save (tikai Liepājā)
        if (isLiepaja) {
            boolean wsFound = false;
            for (List<String> wl : allWindows) {
                for (String line : wl) {
                    if (WAIT_SAVE_PATTERN.matcher(line).find()) { wsFound = true; break; }
                }
                if (wsFound) break;
            }
            if (wsFound) {
                if (!lastWaitSaveContent.equals("wait_and_save")
                        && !acknowledgedWaitSave.equals("wait_and_save")) {
                    lastWaitSaveContent = "wait_and_save";
                    triggerAlert(TYPE_WAIT_SAVE, "");
                    return;
                }
            } else {
                lastWaitSaveContent = "";
            }
        }

        // 2. Ārpus pilsētas
        String cityLabel   = isLiepaja ? "Liepājas" : "Rīgas";
        Set<String> safe   = isLiepaja ? LIEPAJA_SAFE_NAMES    : RIGA_SAFE_NAMES;
        Set<String> outside = isLiepaja ? LIEPAJA_OUTSIDE_NAMES : RIGA_OUTSIDE_NAMES;
        String outsideResult = null;
        for (List<String> wl : allWindows) {
            outsideResult = checkWindowForOutside(wl, isLiepaja, cityLabel, safe, outside);
            if (outsideResult != null) break;
        }
        if (outsideResult != null) {
            if (!lastOutsideContent.equals(outsideResult)
                    && !acknowledgedOutside.equals(outsideResult)) {
                lastOutsideContent = outsideResult;
                triggerAlert(TYPE_OUTSIDE, outsideResult);
                return;
            }
        } else {
            lastOutsideContent = "";
            acknowledgedOutside = "";
        }

        // 3. Rezervēts — jauns pasūtījums (tikai Liepājā)
        if (isLiepaja && isReservedListOpen(allWindows)) {
            int cur = countReservedOrders(allWindows);
            if (lastReservedCount >= 0 && cur > lastReservedCount
                    && cur != acknowledgedReservedCount) {
                lastReservedCount = cur;
                String price = extractReservedPrice(allWindows);
                triggerAlert(TYPE_RESERVED_NEW, price);
                return;
            }
            if (cur >= 0) { lastReservedCount = cur; lastReservedCountPublic = cur; }
        } else {
            lastReservedCount = -1;
            acknowledgedReservedCount = -1;
        }

        // 4. Klondaika (tikai Liepājā, 00:00–12:00)
        if (isLiepaja && isKlondaikaTime()) {
            for (List<String> wl : allWindows) {
                String kl = checkWindowForKlondaika(wl);
                if (kl != null && !acknowledgedKlondaika.equals(kl)) {
                    acknowledgedKlondaika = kl;
                    triggerAlert(TYPE_KLONDAIKA, "");
                    return;
                } else if (kl == null) {
                    acknowledgedKlondaika = "";
                }
            }
        }

        // 5. Liels attālums
        if (isStandbyMode(allWindows)) return;
        String lowResult = null;
        for (List<String> wl : allWindows) {
            lowResult = checkWindowForLowValue(wl, isLiepaja);
            if (lowResult != null) break;
        }
        if (lowResult != null) {
            if (!lastLowValueContent.equals(lowResult)
                    && !acknowledgedLowValue.equals(lowResult)) {
                lastLowValueContent = lowResult;
                triggerAlert(TYPE_LOW_VALUE, lowResult);
                return;
            }
        } else {
            lastLowValueContent = "";
            acknowledgedLowValue = "";
        }
    }

    // ── Brīdinājuma aktivizēšana ─────────────────────────────────────
    private void triggerAlert(String type, String extra) {
        if (alertIsShowing) return;
        playAlarm();
        vibrate();
        alertIsShowing = true;

        // Sūta uz Flutter UI caur EventChannel
        if (eventSink != null) {
            Map<String, String> data = new HashMap<>();
            data.put("type", type);
            data.put("extra", extra != null ? extra : "");
            new Handler(Looper.getMainLooper()).post(() -> {
                if (eventSink != null) eventSink.success(data);
            });
        }
    }

    // ── Logu teksta savākšana ────────────────────────────────────────
    private List<List<String>> collectAllWindows() {
        List<List<String>> result = new ArrayList<>();
        try {
            List<AccessibilityWindowInfo> windows = getWindows();
            if (windows != null) {
                for (AccessibilityWindowInfo window : windows) {
                    AccessibilityNodeInfo root = window.getRoot();
                    if (root == null) continue;
                    CharSequence pkg = root.getPackageName();
                    if (pkg == null || !BOLT_PACKAGE.equals(pkg.toString())) {
                        root.recycle(); continue;
                    }
                    List<String> lines = new ArrayList<>();
                    collectTexts(root, lines);
                    root.recycle();
                    if (!lines.isEmpty()) result.add(lines);
                }
            }
        } catch (Exception e) { Log.e(TAG, "collectAllWindows: " + e.getMessage()); }
        if (result.isEmpty()) {
            try {
                AccessibilityNodeInfo root = getRootInActiveWindow();
                if (root != null) {
                    CharSequence pkg = root.getPackageName();
                    if (pkg != null && BOLT_PACKAGE.equals(pkg.toString())) {
                        List<String> lines = new ArrayList<>();
                        collectTexts(root, lines);
                        if (!lines.isEmpty()) result.add(lines);
                    }
                    root.recycle();
                }
            } catch (Exception e) { Log.e(TAG, "fallback: " + e.getMessage()); }
        }
        return result;
    }

    private void collectTexts(AccessibilityNodeInfo node, List<String> result) {
        if (node == null) return;
        if (node.getText() != null && node.getText().length() > 0)
            result.add(node.getText().toString());
        if (node.getContentDescription() != null && node.getContentDescription().length() > 0)
            result.add(node.getContentDescription().toString());
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) { collectTexts(child, result); child.recycle(); }
        }
    }

    // ── Pārbaudes loģika ─────────────────────────────────────────────
    private String checkWindowForOutside(List<String> lines, boolean isLiepaja,
            String cityLabel, Set<String> safe, Set<String> outside) {
        for (String line : lines) {
            if (line.length() < MIN_LINE_LENGTH) continue;
            String low = line.toLowerCase().trim();
            if (!looksLikeAddress(low)) continue;
            Integer idx = extractCityIndex(low);
            if (idx != null) {
                boolean inCity = isLiepaja
                    ? (idx >= LIEPAJA_MIN && idx <= LIEPAJA_MAX)
                    : (idx >= RIGA_MIN && idx <= RIGA_MAX);
                if (!inCity) return "LV-" + idx + "|" + cityLabel;
            }
        }
        for (String line : lines) {
            if (line.length() < MIN_LINE_LENGTH) continue;
            String low = line.toLowerCase().trim();
            if (low.contains("noraidīt") || low.contains("apstiprināt") ||
                low.contains("šodien") || low.contains("brauciens") ||
                low.contains("bolt") || low.matches("\\d+[,.]\\d+\\s*€.*")) continue;
            String res = findOutsideName(low, safe, outside);
            if (res != null) return res + "|" + cityLabel;
        }
        return null;
    }

    private String checkWindowForLowValue(List<String> lines, boolean isLiepaja) {
        if (!isLiepaja) return null;
        String allText = String.join(" ", lines);
        Double distance = null;
        String distStr = null;
        Matcher dm = DISTANCE_PATTERN.matcher(allText);
        if (dm.find()) {
            try {
                distance = Double.parseDouble(dm.group(1) + "." + dm.group(2));
                distStr = dm.group(1) + "," + dm.group(2) + " km";
            } catch (NumberFormatException e) {}
        }
        if (distance == null) return null;
        float maxKm = getSharedPreferences("boltwatcher", MODE_PRIVATE)
                      .getFloat("max_km", 3.0f);
        if (distance <= maxKm) return null;

        String priceStr = "";
        Matcher pm = PRICE_PATTERN.matcher(allText);
        if (pm.find()) priceStr = pm.group(1) + "," + pm.group(2) + " €";
        String dest = extractDestAddress(lines);
        return distStr + "|" + priceStr + "|" + dest;
    }

    private String extractDestAddress(List<String> lines) {
        int apstIdx = -1;
        for (int i = 0; i < lines.size(); i++) {
            String low = lines.get(i).toLowerCase().trim();
            if (low.equals("apstiprināt") || low.equals("accept") || low.equals("pieņemt")) {
                apstIdx = i; break;
            }
        }
        if (apstIdx > 0) {
            for (int i = apstIdx - 1; i >= 0; i--) {
                String line = lines.get(i).trim();
                String low = line.toLowerCase();
                if (line.length() < 4) continue;
                if (low.contains("latvija") || low.contains("tuvumā") ||
                    low.matches("lv-\\d+.*") || low.matches("\\d{4}.*") ||
                    low.contains("noraidīt") || low.contains("apstiprināt")) continue;
                return line;
            }
        }
        return "";
    }

    private String extractReservedPrice(List<List<String>> allWindows) {
        for (List<String> wl : allWindows) {
            String text = String.join(" ", wl);
            Matcher pm = PRICE_PATTERN.matcher(text);
            while (pm.find()) {
                try {
                    double price = Double.parseDouble(pm.group(1) + "." + pm.group(2));
                    if (price > RESERVED_HIGH_PRICE)
                        return pm.group(1) + "," + pm.group(2) + " €";
                } catch (NumberFormatException e) {}
            }
        }
        return "";
    }

    private boolean isReservedListOpen(List<List<String>> allWindows) {
        for (List<String> wl : allWindows)
            for (String line : wl) {
                String low = line.toLowerCase().trim();
                if (low.contains("rezervētu braucienu") || low.contains("pieprasījumi") ||
                    low.contains("pieņemtie")) return true;
            }
        return false;
    }

    private int countReservedOrders(List<List<String>> allWindows) {
        int count = 0;
        Pattern p = Pattern.compile(
            "\\d+[,.]\\d+\\s*€.*\\d{1,2}:\\d{2}|\\d{1,2}:\\d{2}.*\\d+[,.]\\d+\\s*€");
        for (List<String> wl : allWindows) {
            Matcher m = p.matcher(String.join(" ", wl));
            while (m.find()) count++;
        }
        return count > 0 ? count : -1;
    }

    private boolean isKlondaikaTime() {
        int h = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY);
        return h >= 0 && h < 12;
    }

    private String checkWindowForKlondaika(List<String> lines) {
        for (String line : lines) {
            String low = line.toLowerCase().trim();
            if (low.contains("klondaika")) return "klondaika";
            if (low.contains("stendera") && low.matches(".*\\b3\\b.*")) return "stendera3";
        }
        for (int i = 0; i < lines.size() - 1; i++) {
            String l1 = lines.get(i).toLowerCase().trim();
            String l2 = lines.get(i + 1).toLowerCase().trim();
            if (l1.contains("stendera") && (l2.contains(" 3") || l2.startsWith("3")))
                return "stendera3";
        }
        return null;
    }

    private boolean isStandbyMode(List<List<String>> allWindows) {
        for (List<String> wl : allWindows)
            for (String line : wl) {
                String low = line.toLowerCase().trim();
                if (low.contains("iziet no tie") || low.contains("iet tie") ||
                    low.contains("go online") || low.contains("go offline") ||
                    low.contains("rezervētu braucienu") || low.contains("pieprasījumi") ||
                    low.contains("pieņemtie") || low.contains("precīza adrese ir slēpta") ||
                    low.contains("bolt punkti")) return true;
            }
        return false;
    }

    private boolean looksLikeAddress(String low) {
        for (String kw : ORDER_CTX) if (low.contains(kw)) return true;
        return low.matches(".*\\d+.*[a-zāčēģīķļņšūž].*") ||
               low.matches(".*[a-zāčēģīķļņšūž].*\\d+.*");
    }

    private Integer extractCityIndex(String low) {
        Matcher m = INDEX_PATTERN.matcher(low);
        while (m.find()) {
            int code = Integer.parseInt(m.group(1));
            if (code >= 1001 && code <= 9999) return code;
        }
        return null;
    }

    private String findOutsideName(String low, Set<String> safe, Set<String> outside) {
        for (String n : safe) if (wordInText(low, n)) return null;
        for (String n : outside) if (wordInText(low, n))
            return Character.toUpperCase(n.charAt(0)) + n.substring(1);
        return null;
    }

    private boolean wordInText(String text, String word) {
        String lv = "a-zāčēģīķļņšūž";
        String regex = "(?<![" + lv + "])" + Pattern.quote(word) + "(?![" + lv + "])";
        return Pattern.compile(regex, Pattern.CASE_INSENSITIVE).matcher(text).find();
    }

    private String getCity() {
        return getSharedPreferences("boltwatcher", MODE_PRIVATE)
               .getString("selected_city", "liepaja");
    }

    private void playAlarm() {
        new Thread(() -> {
            try {
                ToneGenerator tg = new ToneGenerator(AudioManager.STREAM_ALARM, 100);
                for (int i = 0; i < 5; i++) {
                    tg.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 400);
                    Thread.sleep(600);
                }
                tg.release();
            } catch (Exception e) { Log.e(TAG, "playAlarm: " + e.getMessage()); }
        }).start();
    }

    private void vibrate() {
        try {
            Vibrator v = (Vibrator) getSystemService(VIBRATOR_SERVICE);
            if (v == null) return;
            long[] p = {0, 500, 200, 500, 200, 500, 200, 1000};
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                v.vibrate(VibrationEffect.createWaveform(p, -1));
            else v.vibrate(p, -1);
        } catch (Exception e) { Log.e(TAG, "vibrate: " + e.getMessage()); }
    }

    @Override public void onInterrupt() {}
    @Override public void onDestroy() { super.onDestroy(); }
}
