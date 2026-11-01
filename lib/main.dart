import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trader_agent.dart';

// ============================================================================
// === EASY CUSTOMIZATION CONFIG (Modify here or give to Claude) ===
// ============================================================================
const double kVirtualCapital = 10000.0;
const double kMaxRiskPerTrade = 100.0;
const double kMaxTotalOpenRisk = 300.0;
const double kMinSafeVolume = 500000;
const double kMinPennyPrice = 2.0;
const double kMaxPennyPrice = 70.0;
// Background scanner: full watchlist sweep interval, and live refresh of the
// stock currently open on screen.
const int kSweepIntervalSeconds = 180;
const int kSelectedRefreshSeconds = 2;
const String kSignalChannelId = 'signals_high_conf';
const String kServiceChannelId = 'scanner_fg';

// 94 stocks. Symbols are Yahoo Finance tickers; any ticker that fails to load
// is auto-resolved by company name at runtime (see ScanEngine.fetchWithFallback).
final List<Map<String, String>> kDefaultWatchlist = [
  {'symbol': '3IINFOTECH.NS', 'name': '3i Infotech'},
  {'symbol': 'ADDSHOP.NS', 'name': 'Add-Shop E-Retail'},
  {'symbol': 'ALMONDZ.NS', 'name': 'Almondz Global Securities'},
  {'symbol': 'ANLON.NS', 'name': 'Anlon Healthcare'},
  {'symbol': 'ARDEE.NS', 'name': 'Ardee Industries'},
  {'symbol': 'ARSHIYA.NS', 'name': 'Arshiya'},
  {'symbol': 'AVANCE.NS', 'name': 'Avance Technologies'},
  {'symbol': 'BLUECLOUDS.NS', 'name': 'Blue Cloud Softech'},
  {'symbol': 'BCG.NS', 'name': 'Brightcom Group'},
  {'symbol': 'CELEBRITY.NS', 'name': 'Celebrity Fashions'},
  {'symbol': 'CENTRALBK.NS', 'name': 'Central Bank of India'},
  {'symbol': 'DCW.NS', 'name': 'DCW'},
  {'symbol': 'DIPNA.NS', 'name': 'Dipna Pharmachem'},
  {'symbol': 'DOLPHIN.NS', 'name': 'Dolphin Kitchen Utensils'},
  {'symbol': 'DRCSYSTEMS.NS', 'name': 'DRC Systems'},
  {'symbol': 'ECONO.NS', 'name': 'Econo Trade India'},
  {'symbol': 'ELITECON.NS', 'name': 'Elitecon International'},
  {'symbol': 'FILATFASH.NS', 'name': 'Filatex Fashions'},
  {'symbol': 'FCL.NS', 'name': 'Fineotex Chem'},
  {'symbol': 'FISCHER.NS', 'name': 'Fischer Medical'},
  {'symbol': 'GAJANAND.NS', 'name': 'Gajanand International'},
  {'symbol': 'GDL.NS', 'name': 'Gateway Distriparks'},
  {'symbol': 'GEEKAYWIRE.NS', 'name': 'Geekay Wires'},
  {'symbol': 'GEMSTONE.NS', 'name': 'Gemstone Investments'},
  {'symbol': 'GEOJITFSL.NS', 'name': 'Geojit Financial Services'},
  {'symbol': 'GSS.NS', 'name': 'GSS Infotech'},
  {'symbol': 'GUJLEASE.NS', 'name': 'Gujarat Lease Financing'},
  {'symbol': 'GUJTLRM.NS', 'name': 'Gujarat Toolroom'},
  {'symbol': 'HCC.NS', 'name': 'Hindustan Construction'},
  {'symbol': 'HMAAGRO.NS', 'name': 'HMA Agro Industries'},
  {'symbol': 'HORIZON.NS', 'name': 'Horizon Industrial Parks'},
  {'symbol': 'HPAL.NS', 'name': 'HP Adhesives'},
  {'symbol': 'IOB.NS', 'name': 'Indian Overseas Bank'},
  {'symbol': 'EMBDL.NS', 'name': 'Indiabulls Real Estate'},
  {'symbol': 'INDOTHAI.NS', 'name': 'Indo Thai Securities'},
  {'symbol': 'INOXWIND.NS', 'name': 'Inox Wind'},
  {'symbol': 'IRB.NS', 'name': 'IRB Infrastructure'},
  {'symbol': 'JAIBALAJI.NS', 'name': 'Jai Balaji Industries'},
  {'symbol': 'JPPOWER.NS', 'name': 'Jaiprakash Power'},
  {'symbol': 'JETFREIGHT.NS', 'name': 'Jet Freight Logistics'},
  {'symbol': 'JONJUA.NS', 'name': 'Jonjua Overseas'},
  {'symbol': 'LLOYDSENT.NS', 'name': 'Lloyds Enterprises'},
  {'symbol': 'MCLOUD.NS', 'name': 'Magellanic Cloud'},
  {'symbol': 'MISHTANN.NS', 'name': 'Mishtann Foods'},
  {'symbol': 'MSUMI.NS', 'name': 'Motherson Wiring'},
  {'symbol': 'MOTISONS.NS', 'name': 'Motisons Jewellers'},
  {'symbol': 'NAVKARURB.NS', 'name': 'Navkar Urbanstructure'},
  {'symbol': 'NEIL.NS', 'name': 'Neil Industries'},
  {'symbol': 'NILASPACES.NS', 'name': 'Nila Spaces'},
  {'symbol': 'NURTUREWELL.NS', 'name': 'Nurture Well Industries'},
  {'symbol': 'GREENPOWER.NS', 'name': 'Orient Green Power'},
  {'symbol': 'OSIAHYPER.NS', 'name': 'Osia Hyper Retail'},
  {'symbol': 'PARLE.NS', 'name': 'Parle Industries'},
  {'symbol': 'PATELENG.NS', 'name': 'Patel Engineering'},
  {'symbol': 'PCJEWELLER.NS', 'name': 'PC Jeweller'},
  {'symbol': 'PRAXIS.NS', 'name': 'Praxis Home Retail'},
  {'symbol': 'PFS.NS', 'name': 'PTC India Fin'},
  {'symbol': 'PSB.NS', 'name': 'Punjab & Sind Bank'},
  {'symbol': 'RAJOOENG.NS', 'name': 'Rajoo Engineers'},
  {'symbol': 'RELINFRA.NS', 'name': 'Reliance Infrastructure'},
  {'symbol': 'RPOWER.NS', 'name': 'Reliance Power'},
  {'symbol': 'REMEDIUM.NS', 'name': 'Remedium Life'},
  {'symbol': 'RHETAN.NS', 'name': 'Rhetan TMT'},
  {'symbol': 'ROTOPUMP.NS', 'name': 'Roto Pumps'},
  {'symbol': 'SABAR.NS', 'name': 'Sabar Flex India'},
  {'symbol': 'SAGILITY.NS', 'name': 'Sagility'},
  {'symbol': 'SAMEERA.NS', 'name': 'Sameera Agro'},
  {'symbol': 'SARASWATI.NS', 'name': 'Saraswati Saree Depot'},
  {'symbol': 'SBC.NS', 'name': 'SBC Exports'},
  {'symbol': 'SHANGAR.NS', 'name': 'Shangar Decor'},
  {'symbol': 'SHREERAMA.NS', 'name': 'Shree Rama Multi-Tech'},
  {'symbol': 'SIGMASOLVE.NS', 'name': 'Sigma Solve'},
  {'symbol': 'SRMENERGY.NS', 'name': 'SRM Energy'},
  {'symbol': 'STANCAP.NS', 'name': 'Standard Capital Markets'},
  {'symbol': 'STEELXIND.NS', 'name': 'Steel Exchange'},
  {'symbol': 'SUZLON.NS', 'name': 'Suzlon Energy'},
  {'symbol': 'SYLPH.NS', 'name': 'Sylph Industries'},
  {'symbol': 'SYNCOMF.NS', 'name': 'Syncom Formulations'},
  {'symbol': 'TTML.NS', 'name': 'Tata Tele. Maharashtra'},
  {'symbol': 'THINKINK.NS', 'name': 'Thinkink Picture'},
  {'symbol': 'TIJARIA.NS', 'name': 'Tijaria Polypipes'},
  {'symbol': 'TRIDENT.NS', 'name': 'Trident'},
  {'symbol': 'UCOBANK.NS', 'name': 'UCO Bank'},
  {'symbol': 'UNISON.NS', 'name': 'Unison Metals'},
  {'symbol': 'UVDHL.NS', 'name': 'United Van Der Horst'},
  {'symbol': 'VBIND.NS', 'name': 'V B Industries'},
  {'symbol': 'VEDANTAPOWER.NS', 'name': 'Vedanta Power'},
  {'symbol': 'VINNY.NS', 'name': 'Vinny Overseas'},
  {'symbol': 'IDEA.NS', 'name': 'Vodafone Idea'},
  {'symbol': 'WEBELSOLAR.NS', 'name': 'Websol Energy System'},
  {'symbol': 'WHITEORG.NS', 'name': 'White Organic'},
  {'symbol': 'XTGLOBAL.NS', 'name': 'XTGlobal Infotech'},
  {'symbol': 'YESBANK.NS', 'name': 'Yes Bank'},
  {'symbol': 'ZODIAC.NS', 'name': 'Zodiac Ventures'},
];
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.init(requestPermission: true);
    await configureScannerService();
  } catch (_) {
    // Notifications / background service are optional; the app still runs.
  }
  runApp(const PennyTraderApp());
}

// ============================================================================
// === MARKET HOURS (IST) ===
// ============================================================================
DateTime nowIst() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

bool isIndianMarketOpenNow() {
  final t = nowIst();
  if (t.weekday == DateTime.saturday || t.weekday == DateTime.sunday) {
    return false;
  }
  final minutes = t.hour * 60 + t.minute;
  return minutes >= 9 * 60 + 15 && minutes <= 15 * 60 + 30;
}

/// True once today's session is over (or it is a weekend) - the background
/// service uses this to shut itself down.
bool isPastMarketCloseOrWeekend() {
  final t = nowIst();
  if (t.weekday == DateTime.saturday || t.weekday == DateTime.sunday) {
    return true;
  }
  return t.hour * 60 + t.minute > 15 * 60 + 30;
}

// ============================================================================
// === LOCAL NOTIFICATIONS ===
// ============================================================================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init({bool requestPermission = false}) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (!_ready) {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(initSettings);
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kSignalChannelId,
          'High-confidence signals',
          description: 'Alerts when a stock hits a High-Confidence BUY or SELL',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kServiceChannelId,
          'Scanner service',
          description: 'Background watchlist scanner status',
          importance: Importance.low,
        ),
      );
      _ready = true;
    }
    if (requestPermission) {
      await android?.requestNotificationsPermission();
    }
  }

  /// Sends a notification when [card] is a High-Confidence BUY or SELL, during
  /// market hours, at most once per stock per action per day.
  static Future<void> maybeNotify(StockItem stock, ActionCardData card) async {
    final bool isActionable = card.action == 'BUY' || card.action == 'SELL';
    if (!isActionable || card.confidence != 'High') return;
    if (!isIndianMarketOpenNow()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final today = DateFormat('yyyy-MM-dd').format(nowIst());
    final marker = '$today|${card.action}';
    final key = 'notified_${stock.name}';
    if (prefs.getString(key) == marker) return;
    await prefs.setString(key, marker);

    await init();
    final body =
        'High-confidence ${card.action} at Rs ${card.entryPrice.toStringAsFixed(2)}'
        ' | Stop Rs ${card.stopLoss.toStringAsFixed(2)}'
        ' | Target Rs ${card.targetPrice.toStringAsFixed(2)}'
        ' | R:R ${card.riskRewardRatio}';
    await _plugin.show(
      stock.name.hashCode & 0x7fffffff,
      '${card.action}: ${stock.name}',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kSignalChannelId,
          'High-confidence signals',
          channelDescription:
              'Alerts when a stock hits a High-Confidence BUY or SELL',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }
}

// ============================================================================
// === SCAN ENGINE (shared by the in-app timer and the background service) ===
// ============================================================================
class ScanEngine {
  /// Fetches a quote; if the ticker fails, looks the company up by name once,
  /// switches to the ticker it finds, and retries.
  static Future<StockQuote> fetchWithFallback(
      YahooDataProvider provider, StockItem stock) async {
    try {
      return await provider.fetchQuoteAndChart(stock.symbol);
    } catch (_) {
      if (stock.symbolResolveTried) rethrow;
      stock.symbolResolveTried = true;
      final alt = await provider.resolveSymbol(stock.name);
      if (alt == null || alt == stock.symbol) rethrow;
      final quote = await provider.fetchQuoteAndChart(alt);
      stock.symbol = alt;
      return quote;
    }
  }

  /// Fetch + evaluate one stock and store the result on it.
  static Future<ActionCardData> scanOne(
      YahooDataProvider provider, StockItem stock, String lang) async {
    final quote = await fetchWithFallback(provider, stock);
    final card =
        LocalPennyTraderAgent.evaluate(stock: stock, quote: quote, lang: lang);
    stock.quote = quote;
    stock.actionCard = card;
    return card;
  }

  /// Runs [task] over every stock in small parallel batches so a full sweep of
  /// the watchlist stays well inside the 3-minute window.
  static Future<void> runInBatches(
    List<StockItem> stocks,
    Future<void> Function(StockItem stock) task, {
    int batchSize = 6,
  }) async {
    for (var i = 0; i < stocks.length; i += batchSize) {
      final end = math.min(i + batchSize, stocks.length);
      await Future.wait(stocks.sublist(i, end).map((s) => task(s)));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}

// ============================================================================
// === BACKGROUND SERVICE (keeps scanning when the app is not on screen) ===
// ============================================================================
Future<void> configureScannerService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onScannerServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: kServiceChannelId,
      initialNotificationTitle: 'Penny Trader scanner',
      initialNotificationContent:
          'Scanning your watchlist every 3 minutes during market hours',
      foregroundServiceNotificationId: 8801,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

@pragma('vm:entry-point')
Future<void> onScannerServiceStart(ServiceInstance service) async {
  ui.DartPluginRegistrant.ensureInitialized();
  await NotificationService.init();

  final provider = YahooDataProvider();
  final stocks = kDefaultWatchlist
      .map((w) => StockItem(symbol: w['symbol']!, name: w['name']!))
      .toList();
  bool busy = false;

  service.on('stopService').listen((_) => service.stopSelf());

  Future<void> cycle() async {
    if (isPastMarketCloseOrWeekend()) {
      service.stopSelf();
      return;
    }
    if (busy || !isIndianMarketOpenNow()) return;
    busy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final lang = prefs.getString('app_lang') ?? 'EN';
      await ScanEngine.runInBatches(stocks, (stock) async {
        try {
          final card = await ScanEngine.scanOne(provider, stock, lang);
          await NotificationService.maybeNotify(stock, card);
        } catch (_) {
          // One bad ticker must not stop the sweep.
        }
      });
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Penny Trader scanner',
          content:
              'Last full scan ${DateFormat('hh:mm a').format(nowIst())} IST - ${stocks.length} stocks',
        );
      }
    } finally {
      busy = false;
    }
  }

  await cycle();
  Timer.periodic(const Duration(seconds: kSweepIntervalSeconds), (_) {
    cycle();
  });
}

// ============================================================================
// === APP THEME: clean, flat, white-and-green trading-app look ===
// ============================================================================
class AppTheme {
  static const Color brandGreen = Color(0xFF00A97F);
  static const Color gain = Color(0xFF00A97F);
  static const Color loss = Color(0xFFE5484D);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF0E1116) : Colors.white;
    final Color surface =
        isDark ? const Color(0xFF1A1E26) : const Color(0xFFF5F6F8);
    final Color line =
        isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE9EBEE);
    final Color text =
        isDark ? const Color(0xFFEDEFF2) : const Color(0xFF1C1F26);

    final scheme = ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: brightness,
    ).copyWith(
      primary: brandGreen,
      surface: bg,
      onSurface: text,
      error: loss,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: brandGreen.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? brandGreen : text.withValues(alpha: 0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? brandGreen : text.withValues(alpha: 0.6),
          );
        }),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: line),
        backgroundColor: bg,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: line),
          minimumSize: const Size(0, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class PennyTraderApp extends StatefulWidget {
  const PennyTraderApp({super.key});

  @override
  State<PennyTraderApp> createState() => _PennyTraderAppState();
}

class _PennyTraderAppState extends State<PennyTraderApp>
    with WidgetsBindingObserver {
  // null = follow the phone's light/dark setting.
  bool? _darkOverride;
  String _language = 'EN';

  bool get _isDarkMode =>
      _darkOverride ??
      (WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_darkOverride == null) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkOverride = prefs.getBool('dark_mode');
      _language = prefs.getString('app_lang') ?? 'EN';
    });
  }

  Future<void> _updateTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    setState(() {
      _darkOverride = isDark;
    });
  }

  Future<void> _updateLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  builder: (context, child) => TraderAiOverlayWrapper(child: child!),
      title: 'Penny Stock Trader',
      debugShowCheckedModeBanner: false,
      themeMode: _darkOverride == null
          ? ThemeMode.system
          : (_darkOverride! ? ThemeMode.dark : ThemeMode.light),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Stage5Screen(
        isDarkMode: _isDarkMode,
        language: _language,
        onThemeChanged: _updateTheme,
        onLanguageChanged: _updateLanguage,
      ),
    );
  }
}

class AppStrings {
  static String get(String lang, String key) {
    const Map<String, Map<String, String>> dict = {
      'EN': {
        'app_title': 'Penny Trader',
        'market_open': 'NSE Market OPEN (9:15-3:30 IST) • 2s Live',
        'market_closed': 'Market CLOSED • Last Session Snapshot',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'Last Traded Price (NSE)',
        'trade_time': 'Exchange Trade Time (IST)',
        'fetch_time': 'Phone Fetch Time (IST)',
        'chart_line': 'Line Graph',
        'chart_candle': 'Candlestick',
        'no_candles': 'No intraday candles available',
        'settings': 'Settings & Config',
        'theme_title': 'Dark Theme',
        'theme_sub': 'Switch between Dark and Light mode',
        'lang_title': 'Language',
        'lang_sub': 'Choose English or Telugu (తెలుగు)',
        'engine_info': '15-Skill Engine + AI Tutor (Rs 0, Zero Keys).',
        'close': 'Close',
        'verify_title': 'Google Finance Test:',
        'candles_count': '5-Min Bars:',
        'card_header': '15-SKILL TRADER ACTION CARD',
        'freshness_label': '1. Data Freshness:',
        'confidence_label': '3. Confidence:',
        'trade_plan_label': '4. Position Plan (Rs 10k Cap / Rs 100 Risk):',
        'entry_label': 'Entry',
        'shares_label': 'Shares',
        'sl_label': 'Stop-Loss',
        'target_label': 'Target',
        'rr_label': 'R : R',
        'cost_label': 'Cost',
        'why_label': '5. Why:',
        'tech_label': 'Technical',
        'fund_label': 'Fundamental',
        'news_label': 'News',
        'wrong_label': '6. Invalidation:',
        'gaps_label': '7. Gaps:',
        'skills_panel_title': 'View All 15 Skills Analysis',
        'nav_live': 'Live & Signals',
        'nav_results': 'Results Log',
        'nav_chat': 'AI Tutor Chat',
        'log_signal_btn': 'Log Signal as Paper Trade',
        'sim_trade_btn': 'Practice Log: Simulate BUY',
        'results_title': 'Paper Trading Portfolio (Base: Rs 10,000)',
        'total_equity': 'Current Equity',
        'total_pnl': 'Total P&L',
        'win_rate': 'Win Rate',
        'avg_win': 'Avg Win',
        'avg_loss': 'Avg Loss',
        'open_risk': 'Open Risk',
        'reset_btn': 'Reset',
        'no_trades': 'No paper trades logged yet.',
        'close_at_ltp': 'Square Off @ LTP',
        'sim_target': 'Test Target (+Rs)',
        'sim_sl': 'Test SL (-Rs 100)',
        'chat_title': 'Friendly Market Assistant (AI Tutor)',
        'chat_hint': 'Ask about this stock, VWAP, or Stop-Loss...',
        'chat_welcome': 'Hello Madhav! Ask me anything about your active stock, stop-loss calculations, or trading rules in English or Telugu.',
      },
      'TE': {
        'app_title': 'పెన్నీ ట్రేడర్ - దశ 5',
        'market_open': 'NSE మార్కెట్ తెరిచి ఉంది (9:15-3:30 IST)',
        'market_closed': 'మార్కెట్ మూసివేయబడింది',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'చివరి ట్రేడ్ ధర (NSE)',
        'trade_time': 'ఎక్స్ఛేంజ్ ట్రేడ్ సమయం (IST)',
        'fetch_time': 'ఫోన్ సమయం (IST)',
        'chart_line': 'లైన్ గ్రాఫ్',
        'chart_candle': 'కాండిల్ స్టిక్',
        'no_candles': 'కాండిల్ డేటా లేదు',
        'settings': 'సెట్టింగ్‌లు',
        'theme_title': 'డార్క్ థీమ్',
        'theme_sub': 'డార్క్/లైట్ మోడ్ మార్చండి',
        'lang_title': 'భాష',
        'lang_sub': 'ఇంగ్లీష్ లేదా తెలుగు',
        'engine_info': '15-నైపుణ్యాల ఇంజిన్ + AI ట్యుటార్ చాట్.',
        'close': 'మూసివేయి',
        'verify_title': 'గూగుల్ ఫైనాన్స్ తనిఖీ:',
        'candles_count': 'కాండిల్స్:',
        'card_header': 'ట్రేడర్ యాక్షన్ కార్డ్',
        'freshness_label': '1. డేటా తాజాదనం:',
        'confidence_label': '3. నమ్మకం:',
        'trade_plan_label': '4. ట్రేడ్ ప్లాన్ (రిస్క్ Rs 100):',
        'entry_label': 'ఎంట్రీ',
        'shares_label': 'షేర్లు',
        'sl_label': 'స్టాప్-లాస్',
        'target_label': 'టార్గెట్',
        'rr_label': 'రిస్క్:రివార్డ్',
        'cost_label': 'ఖర్చు',
        'why_label': '5. కారణాలు:',
        'tech_label': 'టెక్నికల్',
        'fund_label': 'ఫండమెంటల్',
        'news_label': 'వార్తలు',
        'wrong_label': '6. తప్పు అని నిరూపించుట:',
        'gaps_label': '7. లోపాలు:',
        'skills_panel_title': '15 నైపుణ్యాల విశ్లేషణ చూడండి',
        'nav_live': 'లైవ్',
        'nav_results': 'ఫలితాలు',
        'nav_chat': 'AI చాట్',
        'log_signal_btn': 'పేపర్ ట్రేడ్‌గా నమోదు చేయి',
        'sim_trade_btn': 'ప్రాక్టీస్ ట్రేడ్',
        'results_title': 'పేపర్ ట్రేడింగ్ ఫలితాలు (Rs 10,000)',
        'total_equity': 'మొత్తం విలువ',
        'total_pnl': 'లాభం / నష్టం',
        'win_rate': 'గెలుపు రేటు',
        'avg_win': 'సగటు లాభం',
        'avg_loss': 'సగటు నష్టం',
        'open_risk': 'ఓపెన్ రిస్క్',
        'reset_btn': 'రీసెట్',
        'no_trades': 'ట్రేడ్స్ లేవు.',
        'close_at_ltp': 'ముగించు',
        'sim_target': 'టార్గెట్ హిట్',
        'sim_sl': 'SL హిట్',
        'chat_title': 'ఫ్రెండ్లీ మార్కెట్ అసిస్టెంట్ (AI ట్యుటార్)',
        'chat_hint': 'సందేహాలు అడగండి...',
        'chat_welcome': 'నమస్తే మాధవ్! ఏ సందేహమైనా నన్ను అడగండి.',
      },
    };
    return dict[lang]?[key] ?? dict['EN']![key]!;
  }
}

class OhlcvBar {
  final DateTime timeIst;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  OhlcvBar({
    required this.timeIst,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class SkillCheckItem {
  final int number;
  final String title;
  final String finding;
  final bool isPositive;

  SkillCheckItem({
    required this.number,
    required this.title,
    required this.finding,
    required this.isPositive,
  });
}

class ActionCardData {
  final String dataFreshness;
  final String action;
  final String confidence;
  final String confidenceReason;
  final double entryPrice;
  final int sharesForMaxLoss100;
  final double estimatedCapitalUsed;
  final double stopLoss;
  final double targetPrice;
  final String riskRewardRatio;
  final String squareOffNote;
  final String technicalWhy;
  final String fundamentalWhy;
  final String newsWhy;
  final String whatProvesWrong;
  final String dataGaps;
  final String footerDisclaimer;
  final List<SkillCheckItem> fifteenSkillsReport;

  ActionCardData({
    required this.dataFreshness,
    required this.action,
    required this.confidence,
    required this.confidenceReason,
    required this.entryPrice,
    required this.sharesForMaxLoss100,
    required this.estimatedCapitalUsed,
    required this.stopLoss,
    required this.targetPrice,
    required this.riskRewardRatio,
    required this.squareOffNote,
    required this.technicalWhy,
    required this.fundamentalWhy,
    required this.newsWhy,
    required this.whatProvesWrong,
    required this.dataGaps,
    required this.footerDisclaimer,
    required this.fifteenSkillsReport,
  });
}

class PaperTradeRecord {
  final String id;
  final String symbol;
  final String action;
  final String confidence;
  final bool isDelayedPractice;
  final double entryPrice;
  final int shares;
  final double stopLoss;
  final double targetPrice;
  final double plannedMaxLoss;
  final String entryTimeIst;
  String status;
  double? exitPrice;
  String? exitTimeIst;
  double realizedPnl;

  PaperTradeRecord({
    required this.id,
    required this.symbol,
    required this.action,
    required this.confidence,
    required this.isDelayedPractice,
    required this.entryPrice,
    required this.shares,
    required this.stopLoss,
    required this.targetPrice,
    required this.plannedMaxLoss,
    required this.entryTimeIst,
    this.status = 'OPEN',
    this.exitPrice,
    this.exitTimeIst,
    this.realizedPnl = 0.0,
  });

  double currentUnrealizedPnl(double currentLtp) {
    if (status != 'OPEN') return realizedPnl;
    final rawPnl = action == 'BUY'
        ? (currentLtp - entryPrice) * shares
        : (entryPrice - currentLtp) * shares;
    return math.max(-kMaxRiskPerTrade, rawPnl);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'action': action,
        'confidence': confidence,
        'isDelayedPractice': isDelayedPractice,
        'entryPrice': entryPrice,
        'shares': shares,
        'stopLoss': stopLoss,
        'targetPrice': targetPrice,
        'plannedMaxLoss': plannedMaxLoss,
        'entryTimeIst': entryTimeIst,
        'status': status,
        'exitPrice': exitPrice,
        'exitTimeIst': exitTimeIst,
        'realizedPnl': realizedPnl,
      };

  factory PaperTradeRecord.fromJson(Map<String, dynamic> j) {
    return PaperTradeRecord(
      id: (j['id'] ?? '').toString(),
      symbol: (j['symbol'] ?? 'IDEA.NS').toString(),
      action: (j['action'] ?? 'BUY').toString(),
      confidence: (j['confidence'] ?? 'Medium').toString(),
      isDelayedPractice: j['isDelayedPractice'] == true,
      entryPrice: (j['entryPrice'] as num?)?.toDouble() ?? 0.0,
      shares: (j['shares'] as num?)?.toInt() ?? 1,
      stopLoss: (j['stopLoss'] as num?)?.toDouble() ?? 0.0,
      targetPrice: (j['targetPrice'] as num?)?.toDouble() ?? 0.0,
      plannedMaxLoss: (j['plannedMaxLoss'] as num?)?.toDouble() ?? 100.0,
      entryTimeIst: (j['entryTimeIst'] ?? '').toString(),
      status: (j['status'] ?? 'OPEN').toString(),
      exitPrice: (j['exitPrice'] as num?)?.toDouble(),
      exitTimeIst: j['exitTimeIst']?.toString(),
      realizedPnl: (j['realizedPnl'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final String time;

  ChatMessage({required this.sender, required this.text, required this.time});
}

class StockQuote {
  final double price;
  final double previousClose;
  final double dayHigh;
  final double dayLow;
  final int totalDayVolume;
  final double vwap;
  final double ema9;
  final double ema21;
  final double rsi14;
  final double macdLine;
  final double macdSignal;
  final double macdHist;
  final double atr14;
  final double supportLevel;
  final double resistanceLevel;
  final String marketStructureEN;
  final String marketStructureTE;
  final String priceActionEN;
  final String priceActionTE;
  final double volumeSpikeRatio;
  final String candlePatternEN;
  final String candlePatternTE;
  final int backtestSampleCount;
  final double backtestWinRate;
  final DateTime tradeTimeIst;
  final DateTime fetchTimeIst;
  final int delayMinutes;
  final bool isDelayedOver5Min;
  final List<OhlcvBar> bars;

  StockQuote({
    required this.price,
    required this.previousClose,
    required this.dayHigh,
    required this.dayLow,
    required this.totalDayVolume,
    required this.vwap,
    required this.ema9,
    required this.ema21,
    required this.rsi14,
    required this.macdLine,
    required this.macdSignal,
    required this.macdHist,
    required this.atr14,
    required this.supportLevel,
    required this.resistanceLevel,
    required this.marketStructureEN,
    required this.marketStructureTE,
    required this.priceActionEN,
    required this.priceActionTE,
    required this.volumeSpikeRatio,
    required this.candlePatternEN,
    required this.candlePatternTE,
    required this.backtestSampleCount,
    required this.backtestWinRate,
    required this.tradeTimeIst,
    required this.fetchTimeIst,
    required this.delayMinutes,
    required this.isDelayedOver5Min,
    required this.bars,
  });
}

abstract class MarketDataProvider {
  String get providerName;
  Future<StockQuote> fetchQuoteAndChart(String symbol);
}

class YahooDataProvider implements MarketDataProvider {
  @override
  String get providerName => 'Yahoo Finance JSON (5m Intraday)';

  /// Looks a company up by name and returns its NSE (.NS) or BSE (.BO) ticker.
  /// The match is only accepted if Yahoo's company name contains the first word
  /// of ours, so a wrong company is not silently picked up.
  Future<String?> resolveSymbol(String companyName) async {
    final url = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=${Uri.encodeQueryComponent(companyName)}&quotesCount=10&newsCount=0');
    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
      },
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final quotes = decoded['quotes'];
    if (quotes is! List) return null;

    final firstWord = companyName.toLowerCase().split(' ').first;
    for (final suffix in const ['.NS', '.BO']) {
      for (final q in quotes) {
        if (q is! Map) continue;
        final sym = (q['symbol'] ?? '').toString();
        final type = (q['quoteType'] ?? '').toString();
        final label =
            (q['shortname'] ?? q['longname'] ?? '').toString().toLowerCase();
        if (type == 'EQUITY' &&
            sym.endsWith(suffix) &&
            label.contains(firstWord)) {
          return sym;
        }
      }
    }
    return null;
  }

  @override
  Future<StockQuote> fetchQuoteAndChart(String symbol) async {
    final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=5m&range=1d');

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP Error ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final result = data['chart']['result'][0];
    final meta = result['meta'];

    final double currentPrice = (meta['regularMarketPrice'] ?? 0.0).toDouble();
    final double prevClose =
        (meta['chartPreviousClose'] ?? meta['previousClose'] ?? currentPrice)
            .toDouble();
    final int timestampSec = meta['regularMarketTime'] ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    final tradeTimeIst =
        DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000, isUtc: true)
            .add(const Duration(hours: 5, minutes: 30));

    final nowIst =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final diffMinutes = nowIst.difference(tradeTimeIst).inMinutes;

    final List<OhlcvBar> parsedBars = [];
    final List<dynamic>? timestamps = result['timestamp'];
    final indicators = result['indicators']?['quote']?[0];

    double dayHigh = currentPrice;
    double dayLow = currentPrice;
    int totalVol = 0;
    double cumulativeTypicalPriceVolume = 0.0;

    if (timestamps != null && indicators != null) {
      final List<dynamic>? opens = indicators['open'];
      final List<dynamic>? highs = indicators['high'];
      final List<dynamic>? lows = indicators['low'];
      final List<dynamic>? closes = indicators['close'];
      final List<dynamic>? volumes = indicators['volume'];

      for (int i = 0; i < timestamps.length; i++) {
        final o = opens?[i];
        final h = highs?[i];
        final l = lows?[i];
        final c = closes?[i];
        if (o != null && h != null && l != null && c != null) {
          final double openVal = (o as num).toDouble();
          final double highVal = (h as num).toDouble();
          final double lowVal = (l as num).toDouble();
          final double closeVal = (c as num).toDouble();
          final int volVal = (volumes?[i] as num?)?.toInt() ?? 0;

          if (parsedBars.isEmpty || highVal > dayHigh) dayHigh = highVal;
          if (parsedBars.isEmpty || lowVal < dayLow) dayLow = lowVal;
          totalVol += volVal;
          final typicalPrice = (highVal + lowVal + closeVal) / 3.0;
          cumulativeTypicalPriceVolume += typicalPrice * volVal;

          final barTime = DateTime.fromMillisecondsSinceEpoch(
                  (timestamps[i] as int) * 1000,
                  isUtc: true)
              .add(const Duration(hours: 5, minutes: 30));
          parsedBars.add(
            OhlcvBar(
              timeIst: barTime,
              open: openVal,
              high: highVal,
              low: lowVal,
              close: closeVal,
              volume: volVal,
            ),
          );
        }
      }
    }

    final double vwap = totalVol > 0
        ? (cumulativeTypicalPriceVolume / totalVol)
        : currentPrice;
    final double ema9 = _calculateEma(parsedBars, 9, currentPrice);
    final double ema21 = _calculateEma(parsedBars, 21, currentPrice);
    final double rsi14 = _calculateRsi14(parsedBars);
    final List<double> macdVals = _calculateMacd(parsedBars);
    final double atr14 = _calculateAtr14(parsedBars, currentPrice);
    final List<double> srLevels =
        _calculateSupportResistance(parsedBars, dayLow, dayHigh);
    final List<String> structurePair = _analyzeMarketStructure(parsedBars);
    final List<String> paPair = _analyzePriceAction(
        parsedBars, currentPrice, srLevels[0], srLevels[1], vwap);
    final double volSpike = _calculateVolumeSpike(parsedBars);
    final List<String> patternPair =
        _detectCandlePattern(parsedBars, srLevels[0], srLevels[1]);
    final List<num> btStats = _runIntradayBacktest(parsedBars);

    final recentBars = parsedBars.length > 40
        ? parsedBars.sublist(parsedBars.length - 40)
        : parsedBars;

    return StockQuote(
      price: currentPrice,
      previousClose: prevClose,
      dayHigh: dayHigh,
      dayLow: dayLow,
      totalDayVolume: totalVol,
      vwap: vwap,
      ema9: ema9,
      ema21: ema21,
      rsi14: rsi14,
      macdLine: macdVals[0],
      macdSignal: macdVals[1],
      macdHist: macdVals[2],
      atr14: atr14,
      supportLevel: srLevels[0],
      resistanceLevel: srLevels[1],
      marketStructureEN: structurePair[0],
      marketStructureTE: structurePair[1],
      priceActionEN: paPair[0],
      priceActionTE: paPair[1],
      volumeSpikeRatio: volSpike,
      candlePatternEN: patternPair[0],
      candlePatternTE: patternPair[1],
      backtestSampleCount: btStats[0].toInt(),
      backtestWinRate: btStats[1].toDouble(),
      tradeTimeIst: tradeTimeIst,
      fetchTimeIst: nowIst,
      delayMinutes: diffMinutes < 0 ? 0 : diffMinutes,
      isDelayedOver5Min: diffMinutes > 5,
      bars: recentBars,
    );
  }

  double _calculateEma(List<OhlcvBar> bars, int period, double fallback) {
    if (bars.isEmpty) return fallback;
    final double k = 2.0 / (period + 1);
    double ema = bars.first.close;
    for (int i = 1; i < bars.length; i++) {
      ema = (bars[i].close * k) + (ema * (1.0 - k));
    }
    return ema;
  }

  List<double> _calculateMacd(List<OhlcvBar> bars) {
    if (bars.length < 5) return [0.0, 0.0, 0.0];
    const double k12 = 2.0 / 13.0;
    const double k26 = 2.0 / 27.0;
    const double k9 = 2.0 / 10.0;

    double ema12 = bars.first.close;
    double ema26 = bars.first.close;
    double signal = 0.0;
    double macd = 0.0;

    for (int i = 1; i < bars.length; i++) {
      final c = bars[i].close;
      ema12 = (c * k12) + (ema12 * (1.0 - k12));
      ema26 = (c * k26) + (ema26 * (1.0 - k26));
      macd = ema12 - ema26;
      if (i == 1) {
        signal = macd;
      } else {
        signal = (macd * k9) + (signal * (1.0 - k9));
      }
    }
    return [macd, signal, macd - signal];
  }

  double _calculateRsi14(List<OhlcvBar> bars) {
    if (bars.length < 15) return 50.0;
    double gains = 0.0;
    double losses = 0.0;
    for (int i = bars.length - 14; i < bars.length; i++) {
      final diff = bars[i].close - bars[i - 1].close;
      if (diff >= 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }
    if (losses == 0) return 100.0;
    final rs = (gains / 14.0) / (losses / 14.0);
    return 100.0 - (100.0 / (1.0 + rs));
  }

  double _calculateAtr14(List<OhlcvBar> bars, double fallbackPrice) {
    if (bars.length < 2) return math.max(0.05, fallbackPrice * 0.01);
    final int start = math.max(1, bars.length - 14);
    double sumTr = 0.0;
    int count = 0;
    for (int i = start; i < bars.length; i++) {
      final cur = bars[i];
      final prevClose = bars[i - 1].close;
      final tr1 = cur.high - cur.low;
      final tr2 = (cur.high - prevClose).abs();
      final tr3 = (cur.low - prevClose).abs();
      final tr = math.max(tr1, math.max(tr2, tr3));
      sumTr += tr;
      count++;
    }
    final avg = count > 0 ? (sumTr / count) : (fallbackPrice * 0.01);
    return math.max(0.05, avg);
  }

  List<double> _calculateSupportResistance(
      List<OhlcvBar> bars, double dayLow, double dayHigh) {
    if (bars.length < 5) return [dayLow, dayHigh];
    final int start = math.max(0, bars.length - 20);
    double sup = bars[start].low;
    double res = bars[start].high;
    for (int i = start; i < bars.length; i++) {
      if (bars[i].low < sup) sup = bars[i].low;
      if (bars[i].high > res) res = bars[i].high;
    }
    return [sup, res];
  }

  List<String> _analyzeMarketStructure(List<OhlcvBar> bars) {
    if (bars.length < 12) {
      return [
        'Sideways / Early Session Range',
        'సైడ్‌వేస్ రేంజ్ (ప్రారంభ సెషన్)'
      ];
    }
    final int n = bars.length;
    final half1 = bars.sublist(n - 12, n - 6);
    final half2 = bars.sublist(n - 6, n);

    double h1 = half1.first.high;
    double l1 = half1.first.low;
    for (final b in half1) {
      if (b.high > h1) h1 = b.high;
      if (b.low < l1) l1 = b.low;
    }

    double h2 = half2.first.high;
    double l2 = half2.first.low;
    for (final b in half2) {
      if (b.high > h2) h2 = b.high;
      if (b.low < l2) l2 = b.low;
    }

    if (h2 > h1 && l2 >= l1) {
      return [
        'Higher Highs & Higher Lows (Uptrend Structure)',
        'హయ్యర్ హైస్ & హయ్యర్ లోస్ (అప్‌ట్రెండ్ నిర్మాణం)'
      ];
    } else if (h2 <= h1 && l2 < l1) {
      return [
        'Lower Highs & Lower Lows (Downtrend Structure)',
        'లోయర్ హైస్ & లోయర్ లోస్ (డౌన్‌ట్రెండ్ నిర్మాణం)'
      ];
    } else {
      return [
        'Sideways Consolidation Range',
        'సైడ్‌వేస్ కన్సాలిడేషన్ రేంజ్ (స్థూల పరిధి)'
      ];
    }
  }

  List<String> _analyzePriceAction(List<OhlcvBar> bars, double price,
      double support, double resistance, double vwap) {
    if (bars.isEmpty) {
      return ['Waiting for price action', 'ప్రైస్ యాక్షన్ కోసం వేచి ఉంది'];
    }
    final double range = math.max(0.05, resistance - support);
    if (price >= resistance - (range * 0.10)) {
      return [
        'Testing Resistance Zone (Rs ${resistance.toStringAsFixed(2)}) — watch for breakout or rejection',
        'రెసిస్టెన్స్ జోన్ (Rs ${resistance.toStringAsFixed(2)}) వద్ద ఉంది — బ్రేకౌట్ కోసం చూడండి'
      ];
    } else if (price <= support + (range * 0.10)) {
      return [
        'Testing Support Zone (Rs ${support.toStringAsFixed(2)}) — watch for buyer bounce or breakdown',
        'సపోర్ట్ జోన్ (Rs ${support.toStringAsFixed(2)}) వద్ద ఉంది — కొనుగోలు మద్దతు కోసం చూడండి'
      ];
    } else if ((price - vwap).abs() <= (price * 0.004)) {
      return [
        'Pullback to VWAP equilibrium (Rs ${vwap.toStringAsFixed(2)})',
        'VWAP (Rs ${vwap.toStringAsFixed(2)}) వద్ద పుల్‌బ్యాక్ జరుగుతోంది'
      ];
    }
    return price > vwap
        ? [
            'Trading above VWAP after buyer impulse',
            'కొనుగోలుదారుల మద్దతుతో VWAP పైన ట్రేడ్ అవుతోంది'
          ]
        : [
            'Trading below VWAP under seller pressure',
            'అమ్మకందారుల ఒత్తిడితో VWAP దిగువన ట్రేడ్ అవుతోంది'
          ];
  }

  double _calculateVolumeSpike(List<OhlcvBar> bars) {
    if (bars.length < 6) return 1.0;
    final latestVol = bars.last.volume.toDouble();
    final int start = math.max(0, bars.length - 11);
    double sumPrev = 0.0;
    int count = 0;
    for (int i = start; i < bars.length - 1; i++) {
      sumPrev += bars[i].volume;
      count++;
    }
    final avgPrev = count > 0 ? (sumPrev / count) : 1.0;
    if (avgPrev <= 0) return 1.0;
    return latestVol / avgPrev;
  }

  List<String> _detectCandlePattern(
      List<OhlcvBar> bars, double support, double resistance) {
    if (bars.length < 2) {
      return ['Neutral Candle', 'సాధారణ కాండిల్ (Neutral)'];
    }
    final cur = bars.last;
    final prev = bars[bars.length - 2];
    final body = (cur.close - cur.open).abs();
    final range = math.max(0.001, cur.high - cur.low);
    final upperWick = cur.high - math.max(cur.open, cur.close);
    final lowerWick = math.min(cur.open, cur.close) - cur.low;

    if (cur.close > cur.open &&
        prev.close < prev.open &&
        cur.close >= prev.open &&
        cur.open <= prev.close) {
      return [
        'Bullish Engulfing (Strong buying pressure overtaking sellers)',
        'బుల్లిష్ ఎంగల్ఫింగ్ (కొనుగోలుదారుల బలమైన ఆధిపత్యం)'
      ];
    }
    if (cur.close < cur.open &&
        prev.close > prev.open &&
        cur.close <= prev.open &&
        cur.open >= prev.close) {
      return [
        'Bearish Engulfing (Strong selling pressure overtaking buyers)',
        'బేరిష్ ఎంగల్ఫింగ్ (అమ్మకందారుల బలమైన ఆధిపత్యం)'
      ];
    }
    if (lowerWick > body * 2.0 && upperWick < body * 0.8) {
      return [
        'Hammer Rejection (Buyers defending lower levels)',
        'హ్యామర్ కాండిల్ (దిగువ స్థాయిలో కొనుగోలుదారుల మద్దతు)'
      ];
    }
    if (upperWick > body * 2.0 && lowerWick < body * 0.8) {
      return [
        'Shooting Star Rejection (Sellers rejecting higher prices)',
        'షూటింగ్ స్టార్ (పై స్థాయిలో అమ్మకాల ఒత్తిడి)'
      ];
    }
    if (body <= range * 0.15) {
      return [
        'Doji Indecision (Buyers and sellers in equilibrium)',
        'డోజీ కాండిల్ (మార్కెట్‌లో కొనుగోలు-అమ్మకాల అనిశ్చితి)'
      ];
    }
    return cur.close >= cur.open
        ? ['Bullish Green Bar', 'గ్రీన్ బుల్లిష్ కాండిల్']
        : ['Bearish Red Bar', 'రెడ్ బేరిష్ కాండిల్'];
  }

  List<num> _runIntradayBacktest(List<OhlcvBar> bars) {
    if (bars.length < 15) return [0, 0.0];
    int signals = 0;
    int wins = 0;

    for (int i = 10; i < bars.length - 3; i++) {
      final slice = bars.sublist(0, i + 1);
      final ema9 = _calculateEma(slice, 9, slice.last.close);
      final ema21 = _calculateEma(slice, 21, slice.last.close);
      final cur = slice.last;
      final prev = slice[slice.length - 2];

      if (ema9 > ema21 && cur.close > prev.high) {
        signals++;
        final double futureHigh = math.max(
            bars[i + 1].high, math.max(bars[i + 2].high, bars[i + 3].high));
        if (futureHigh > cur.close) wins++;
      } else if (ema9 < ema21 && cur.close < prev.low) {
        signals++;
        final double futureLow = math.min(
            bars[i + 1].low, math.min(bars[i + 2].low, bars[i + 3].low));
        if (futureLow < cur.close) wins++;
      }
    }
    final double winRate = signals > 0 ? (wins / signals) * 100.0 : 0.0;
    return [signals, winRate];
  }
}

class LocalPennyTraderAgent {
  static ActionCardData evaluate({
    required StockItem stock,
    required StockQuote quote,
    required String lang,
  }) {
    final bool isTE = lang == 'TE';

    final double dayChangePct = quote.previousClose > 0
        ? ((quote.price - quote.previousClose) / quote.previousClose) * 100.0
        : 0.0;

    final String freshness = quote.isDelayedOver5Min
        ? (isTE
            ? 'PRACTICE ONLY - DELAYED DATA (డేటా ${quote.delayMinutes} నిమిషాలు ఆలస్యంగా ఉంది)'
            : 'PRACTICE ONLY - DELAYED DATA (${quote.delayMinutes} min old — practice only)')
        : (isTE
            ? 'LIVE DATA (డేటా తాజాగా ఉంది — ${quote.delayMinutes} నిమిషాలు)'
            : 'LIVE DATA (${quote.delayMinutes} min delay — within threshold)');

    final bool isLiquid = quote.totalDayVolume >= kMinSafeVolume;
    final bool isPennyRange =
        quote.price >= kMinPennyPrice && quote.price <= kMaxPennyPrice;
    final bool isNearCircuit = dayChangePct.abs() >= 4.75;
    final bool isUnexplainedSpike =
        quote.volumeSpikeRatio >= 3.0 && dayChangePct.abs() >= 2.5;

    final bool bullishIndicators = quote.price > quote.vwap &&
        quote.ema9 >= quote.ema21 &&
        quote.macdHist >= 0 &&
        quote.rsi14 >= 52.0 &&
        quote.rsi14 <= 68.0;

    final bool bearishIndicators = quote.price < quote.vwap &&
        quote.ema9 < quote.ema21 &&
        quote.macdHist < 0 &&
        quote.rsi14 <= 48.0 &&
        quote.rsi14 >= 32.0;

    final double stopDistance =
        math.max(0.10, math.max(quote.atr14 * 1.5, quote.price * 0.015));

    final double entry = quote.price;
    final bool leanBull = quote.price >= quote.vwap;
    final double stopLoss =
        leanBull ? (entry - stopDistance) : (entry + stopDistance);
    final double targetPrice =
        leanBull ? (entry + stopDistance * 2.2) : (entry - stopDistance * 2.2);

    final double riskPerShare = (entry - stopLoss).abs();
    final double rewardPerShare = (targetPrice - entry).abs();
    final double rrRatio =
        riskPerShare > 0 ? (rewardPerShare / riskPerShare) : 0.0;

    int sharesByRisk =
        riskPerShare > 0 ? (kMaxRiskPerTrade / riskPerShare).floor() : 1;
    final int maxSharesByCapital =
        entry > 0 ? (kVirtualCapital / entry).floor() : 1;
    final int finalShares =
        math.max(1, math.min(sharesByRisk, maxSharesByCapital));
    final double estimatedCost = finalShares * entry;

    String action = 'WAIT';
    String confidence = 'Low';
    String confidenceReason = '';

    if (!isLiquid) {
      action = 'AVOID';
      confidence = 'High';
      confidenceReason = isTE
          ? 'వాల్యూమ్ (${quote.totalDayVolume}) 5 లక్షల కంటే తక్కువగా ఉంది — AVOID.'
          : 'Volume (${quote.totalDayVolume}) is below 5L safe liquidity rule — strict AVOID.';
    } else if (isNearCircuit) {
      action = 'AVOID';
      confidence = 'High';
      confidenceReason = isTE
          ? 'ధర సర్క్యూట్ పరిమితి దగ్గర ఉంది — AVOID.'
          : 'Stock is near a circuit limit — strict AVOID.';
    } else if (isUnexplainedSpike) {
      action = 'AVOID';
      confidence = 'High';
      confidenceReason = isTE
          ? 'వార్తలు లేకుండా వాల్యూమ్ స్పైక్ — మానిప్యులేషన్ అనుమానంతో AVOID.'
          : 'Sudden volume spike without news — do not chase.';
    } else if (!isPennyRange) {
      action = 'AVOID';
      confidence = 'Medium';
      confidenceReason = isTE
          ? 'ధర Rs ${quote.price.toStringAsFixed(2)} పెన్నీ స్టాక్ పరిధిలో లేదు.'
          : 'Price Rs ${quote.price.toStringAsFixed(2)} is outside Rs ${kMinPennyPrice.toStringAsFixed(0)}–Rs ${kMaxPennyPrice.toStringAsFixed(0)} penny range.';
    } else if (bullishIndicators && rrRatio >= 2.0 && finalShares >= 1) {
      action = 'BUY';
      confidence = quote.volumeSpikeRatio >= 1.2 ? 'High' : 'Medium';
      confidenceReason = isTE
          ? 'టెక్నికల్స్ బుల్లిష్‌గా ఉన్నాయి; 1:${rrRatio.toStringAsFixed(1)} రిస్క్-రివార్డ్.'
          : 'Bullish confluence across indicators with 1:${rrRatio.toStringAsFixed(1)} risk-reward.';
    } else if (bearishIndicators && rrRatio >= 2.0 && finalShares >= 1) {
      action = 'SELL';
      confidence = quote.volumeSpikeRatio >= 1.2 ? 'High' : 'Medium';
      confidenceReason = isTE
          ? 'టెక్నికల్స్ బేరిష్‌గా ఉన్నాయి; 1:${rrRatio.toStringAsFixed(1)} రిస్క్-రివార్డ్.'
          : 'Bearish confluence across indicators with 1:${rrRatio.toStringAsFixed(1)} risk-reward.';
    } else {
      action = 'WAIT';
      confidence = 'Medium';
      confidenceReason = isTE
          ? 'స్పష్టమైన ట్రెండ్ లేదు — వేచి ఉండండి (WAIT).'
          : 'Indicators are mixed near VWAP — wait for a confirmed setup.';
    }

    final List<SkillCheckItem> skillsReport = [
      SkillCheckItem(
        number: 1,
        title: isTE ? '1. టెక్నికల్ అనాలిసిస్' : '1. Technical Analysis',
        finding: 'Price Rs ${quote.price.toStringAsFixed(2)} | Range Rs ${quote.dayLow.toStringAsFixed(2)}–Rs ${quote.dayHigh.toStringAsFixed(2)}',
        isPositive: bullishIndicators || bearishIndicators,
      ),
      SkillCheckItem(
        number: 2,
        title: isTE ? '2. కాండిల్ స్టిక్' : '2. Candlestick Analysis',
        finding: isTE ? quote.candlePatternTE : quote.candlePatternEN,
        isPositive: !quote.candlePatternEN.contains('Doji'),
      ),
      SkillCheckItem(
        number: 3,
        title: isTE ? '3. రిస్క్ మేనేజ్‌మెంట్' : '3. Risk Management',
        finding: 'Max risk per trade = Rs ${kMaxRiskPerTrade.toInt()} (1%). SL: Rs ${stopLoss.toStringAsFixed(2)}',
        isPositive: rrRatio >= 2.0,
      ),
      SkillCheckItem(
        number: 4,
        title: isTE ? '4. ట్రేడింగ్ సైకాలజీ' : '4. Trading Psychology',
        finding: 'Controlled emotional discipline; no FOMO chasing.',
        isPositive: !isUnexplainedSpike,
      ),
      SkillCheckItem(
        number: 5,
        title: isTE ? '5. ఫండమెంటల్స్' : '5. Fundamental Analysis',
        finding: 'Missing in free chart feed (flagged transparently).',
        isPositive: false,
      ),
      SkillCheckItem(
        number: 6,
        title: isTE ? '6. ఇండికేటర్స్' : '6. Indicator Analysis',
        finding: 'VWAP: ${quote.vwap.toStringAsFixed(2)} | RSI: ${quote.rsi14.toStringAsFixed(1)} | MACD: ${quote.macdHist.toStringAsFixed(3)}',
        isPositive: bullishIndicators || bearishIndicators,
      ),
      SkillCheckItem(
        number: 7,
        title: isTE ? '7. ప్రైస్ యాక్షన్' : '7. Price Action Trading',
        finding: isTE ? quote.priceActionTE : quote.priceActionEN,
        isPositive: true,
      ),
      SkillCheckItem(
        number: 8,
        title: isTE ? '8. సపోర్ట్ & రెసిస్టెన్స్' : '8. Support & Resistance',
        finding: 'Support: ${quote.supportLevel.toStringAsFixed(2)} | Resistance: ${quote.resistanceLevel.toStringAsFixed(2)}',
        isPositive: true,
      ),
      SkillCheckItem(
        number: 9,
        title: isTE ? '9. మార్కెట్ నిర్మాణం' : '9. Market Structure',
        finding: isTE ? quote.marketStructureTE : quote.marketStructureEN,
        isPositive: !quote.marketStructureEN.contains('Sideways'),
      ),
      SkillCheckItem(
        number: 10,
        title: isTE ? '10. వాల్యూమ్' : '10. Volume Analysis',
        finding: 'Volume: ${quote.totalDayVolume} | Spike: ${quote.volumeSpikeRatio.toStringAsFixed(2)}x',
        isPositive: isLiquid && !isUnexplainedSpike,
      ),
      SkillCheckItem(
        number: 11,
        title: isTE ? '11. స్టాక్ స్క్రీనింగ్' : '11. Stock Screening',
        finding: 'Penny Range & Liquidity verified.',
        isPositive: isPennyRange && isLiquid,
      ),
      SkillCheckItem(
        number: 12,
        title: isTE ? '12. ఎంట్రీ & ఎగ్జిట్' : '12. Entry & Exit Strategy',
        finding: 'Entry: ${entry.toStringAsFixed(2)} | Target: ${targetPrice.toStringAsFixed(2)} | Exit 3:20 PM',
        isPositive: action == 'BUY' || action == 'SELL',
      ),
      SkillCheckItem(
        number: 13,
        title: isTE ? '13. పొజిషన్ సైజింగ్' : '13. Position Sizing',
        finding: '$finalShares shares calculated for Rs ${kMaxRiskPerTrade.toInt()} max risk.',
        isPositive: finalShares >= 1,
      ),
      SkillCheckItem(
        number: 14,
        title: isTE ? '14. బ్యాక్‌టెస్టింగ్' : '14. Backtesting',
        finding: 'Today Win Rate: ${quote.backtestWinRate.toStringAsFixed(0)}% across ${quote.backtestSampleCount} setups.',
        isPositive: quote.backtestWinRate >= 50.0,
      ),
      SkillCheckItem(
        number: 15,
        title: isTE ? '15. ట్రేడింగ్ క్రమశిక్షణ' : '15. Trading Discipline',
        finding: 'Strict adherence to risk rules.',
        isPositive: true,
      ),
    ];

    return ActionCardData(
      dataFreshness: freshness,
      action: action,
      confidence: confidence,
      confidenceReason: confidenceReason,
      entryPrice: entry,
      sharesForMaxLoss100: finalShares,
      estimatedCapitalUsed: estimatedCost,
      stopLoss: stopLoss,
      targetPrice: targetPrice,
      riskRewardRatio: '1 : ${rrRatio.toStringAsFixed(1)}',
      squareOffNote: 'Square off before market close (3:20 PM IST)',
      technicalWhy: isTE ? quote.marketStructureTE : quote.marketStructureEN,
      fundamentalWhy: 'Free feed: Fundamentals missing',
      newsWhy: 'Free feed: News missing',
      whatProvesWrong: 'Invalidated if price breaches stop-loss or VWAP',
      dataGaps: 'Missing: Fundamentals, News, Bid-Ask Spread',
      footerDisclaimer: 'Educational analysis, not financial advice. Paper trading only.',
      fifteenSkillsReport: skillsReport,
    );
  }
}

class StockItem {
  String symbol;
  final String name;
  bool symbolResolveTried = false;
  StockQuote? quote;
  ActionCardData? actionCard;
  bool isLoading;
  String errorMessage;

  StockItem({
    required this.symbol,
    required this.name,
    this.quote,
    this.actionCard,
    this.isLoading = true,
    this.errorMessage = '',
  });
}

class Stage5Screen extends StatefulWidget {
  final bool isDarkMode;
  final String language;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const Stage5Screen({
    super.key,
    required this.isDarkMode,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<Stage5Screen> createState() => _Stage5ScreenState();
}

class _Stage5ScreenState extends State<Stage5Screen>
    with WidgetsBindingObserver {
  final YahooDataProvider _dataProvider = YahooDataProvider();
  late final List<StockItem> _stocks;

  int _selectedIndex = 0;
  int _bottomTabIndex = 0;
  bool _showStockDetail = false;
  bool _isMarketOpen = false;
  bool _showCandlestick = true;
  Timer? _activeStockTimer;
  Timer? _sweepTimer;
  bool _sweepRunning = false;
  bool _selectedFetching = false;

  List<PaperTradeRecord> _paperTrades = [];
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stocks = kDefaultWatchlist
        .map((w) => StockItem(symbol: w['symbol']!, name: w['name']!))
        .toList();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedData();
    _initializeAndStartPolling();
  }

  // App on screen -> in-app timers scan. App in background -> the foreground
  // service takes over so alerts keep arriving with the screen off.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final service = FlutterBackgroundService();
    if (state == AppLifecycleState.paused) {
      if (!isPastMarketCloseOrWeekend()) {
        service.startService().catchError((_) => false);
      }
    } else if (state == AppLifecycleState.resumed) {
      service.invoke('stopService');
      if (_isMarketOpen) {
        _sweepAll(showSpinner: false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeStockTimer?.cancel();
    _sweepTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('paper_trades_v5') ?? [];
    final loaded = <PaperTradeRecord>[];
    for (final item in rawList) {
      try {
        loaded.add(PaperTradeRecord.fromJson(jsonDecode(item)));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _paperTrades = loaded;
      if (_chatMessages.isEmpty) {
        final nowStr = DateFormat('hh:mm a').format(DateTime.now());
        _chatMessages.add(ChatMessage(
          sender: 'tutor',
          text: AppStrings.get(widget.language, 'chat_welcome'),
          time: nowStr,
        ));
      }
    });
  }

  Future<void> _savePaperTrades() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _paperTrades.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList('paper_trades_v5', rawList);
  }

  bool _checkMarketHoursNow() => isIndianMarketOpenNow();

  Future<void> _initializeAndStartPolling() async {
    setState(() {
      _isMarketOpen = _checkMarketHoursNow();
    });

    _activeStockTimer?.cancel();
    _sweepTimer?.cancel();

    // The stock open on screen refreshes every few seconds.
    _activeStockTimer =
        Timer.periodic(const Duration(seconds: kSelectedRefreshSeconds), (_) async {
      final openNow = _checkMarketHoursNow();
      if (openNow != _isMarketOpen) {
        setState(() {
          _isMarketOpen = openNow;
        });
      }
      if (_isMarketOpen && _showStockDetail && !_selectedFetching) {
        _selectedFetching = true;
        try {
          await _fetchSingleStock(_stocks[_selectedIndex], showSpinner: false);
        } finally {
          _selectedFetching = false;
        }
      }
    });

    // The whole watchlist is rotated through once every 3 minutes.
    _sweepTimer =
        Timer.periodic(const Duration(seconds: kSweepIntervalSeconds), (_) {
      if (_isMarketOpen) {
        _sweepAll(showSpinner: false);
      }
    });

    await _sweepAll(showSpinner: true);
  }

  Future<void> _sweepAll({required bool showSpinner}) async {
    if (_sweepRunning) return;
    _sweepRunning = true;
    try {
      await ScanEngine.runInBatches(
        _stocks,
        (stock) => _fetchSingleStock(stock, showSpinner: showSpinner),
      );
    } finally {
      _sweepRunning = false;
    }
  }

  Future<void> _fetchSingleStock(StockItem stock,
      {required bool showSpinner}) async {
    if (showSpinner) {
      setState(() {
        stock.isLoading = true;
        stock.errorMessage = '';
      });
    }

    try {
      final quote = await ScanEngine.fetchWithFallback(_dataProvider, stock);
      if (!mounted) return;
      final card = LocalPennyTraderAgent.evaluate(
        stock: stock,
        quote: quote,
        lang: widget.language,
      );
      setState(() {
        stock.quote = quote;
        stock.actionCard = card;
        stock.isLoading = false;
        stock.errorMessage = '';
      });
      _checkOpenPaperTradesAgainstPrice(stock.symbol, quote.price);
      await NotificationService.maybeNotify(stock, card);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        stock.errorMessage = 'Could not load price ($e)';
        stock.isLoading = false;
      });
    }
  }

  void _checkOpenPaperTradesAgainstPrice(String symbol, double latestPrice) {
    bool changed = false;
    final nowIst =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final timeStr = DateFormat('dd MMM, hh:mm:ss a').format(nowIst);

    for (final t in _paperTrades) {
      if (t.status != 'OPEN' || t.symbol != symbol) continue;

      if (t.action == 'BUY') {
        if (latestPrice >= t.targetPrice) {
          t.status = 'TARGET_HIT';
          t.exitPrice = t.targetPrice;
          t.exitTimeIst = timeStr;
          t.realizedPnl = (t.targetPrice - t.entryPrice) * t.shares;
          changed = true;
        } else if (latestPrice <= t.stopLoss) {
          t.status = 'SL_HIT';
          t.exitPrice = t.stopLoss;
          t.exitTimeIst = timeStr;
          t.realizedPnl =
              math.max(-kMaxRiskPerTrade, (t.stopLoss - t.entryPrice) * t.shares);
          changed = true;
        }
      } else if (t.action == 'SELL') {
        if (latestPrice <= t.targetPrice) {
          t.status = 'TARGET_HIT';
          t.exitPrice = t.targetPrice;
          t.exitTimeIst = timeStr;
          t.realizedPnl = (t.entryPrice - t.targetPrice) * t.shares;
          changed = true;
        } else if (latestPrice >= t.stopLoss) {
          t.status = 'SL_HIT';
          t.exitPrice = t.stopLoss;
          t.exitTimeIst = timeStr;
          t.realizedPnl =
              math.max(-kMaxRiskPerTrade, (t.entryPrice - t.stopLoss) * t.shares);
          changed = true;
        }
      }
    }

    if (changed) {
      setState(() {});
      _savePaperTrades();
    }
  }

  void _logPaperTrade(StockItem stock, {required bool forcePracticeBuy}) {
    final quote = stock.quote;
    final card = stock.actionCard;
    if (quote == null || card == null) return;

    final openTrades =
        _paperTrades.where((t) => t.status == 'OPEN').toList();
    final double currentOpenRisk = openTrades.length * kMaxRiskPerTrade;

    if (openTrades.length >= 3 || currentOpenRisk >= kMaxTotalOpenRisk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Max risk limit reached (3 open paper trades).')),
      );
      return;
    }

    final String tradeAction = forcePracticeBuy
        ? 'BUY'
        : ((card.action == 'BUY' || card.action == 'SELL')
            ? card.action
            : 'BUY');

    final double entry = card.entryPrice;
    final double slDist = (entry - card.stopLoss).abs();
    final double safeDist = slDist > 0.02 ? slDist : math.max(0.10, entry * 0.015);
    final double sl =
        tradeAction == 'BUY' ? (entry - safeDist) : (entry + safeDist);
    final double target = tradeAction == 'BUY'
        ? (entry + safeDist * 2.2)
        : (entry - safeDist * 2.2);
    final int shares = math.max(
        1,
        math.min((kMaxRiskPerTrade / safeDist).floor(),
            (kVirtualCapital / entry).floor()));

    final nowIst =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

    final record = PaperTradeRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: stock.symbol,
      action: tradeAction,
      confidence: card.confidence,
      isDelayedPractice: quote.isDelayedOver5Min || forcePracticeBuy,
      entryPrice: entry,
      shares: shares,
      stopLoss: sl,
      targetPrice: target,
      plannedMaxLoss: kMaxRiskPerTrade,
      entryTimeIst: DateFormat('dd MMM, hh:mm:ss a').format(nowIst),
    );

    setState(() {
      _paperTrades.insert(0, record);
      _bottomTabIndex = 1;
    });
    _savePaperTrades();
  }

  void _closePaperTradeManually(PaperTradeRecord trade, String outcomeType) {
    final nowIst =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final timeStr = DateFormat('dd MMM, hh:mm:ss a').format(nowIst);

    double ltp = trade.entryPrice;
    for (final s in _stocks) {
      if (s.symbol == trade.symbol && s.quote != null) {
        ltp = s.quote!.price;
        break;
      }
    }

    setState(() {
      if (outcomeType == 'TARGET') {
        trade.status = 'TARGET_HIT';
        trade.exitPrice = trade.targetPrice;
        trade.realizedPnl =
            (trade.targetPrice - trade.entryPrice).abs() * trade.shares;
      } else if (outcomeType == 'SL') {
        trade.status = 'SL_HIT';
        trade.exitPrice = trade.stopLoss;
        trade.realizedPnl = -kMaxRiskPerTrade;
      } else {
        trade.status = 'SQUARED_OFF';
        trade.exitPrice = ltp;
        final raw = trade.action == 'BUY'
            ? (ltp - trade.entryPrice) * trade.shares
            : (trade.entryPrice - ltp) * trade.shares;
        trade.realizedPnl = math.max(-kMaxRiskPerTrade, raw);
      }
      trade.exitTimeIst = timeStr;
    });
    _savePaperTrades();
  }

  Future<void> _resetPaperAccount() async {
    setState(() {
      _paperTrades.clear();
    });
    await _savePaperTrades();
  }

  void _sendChatMessage(String userQuery) {
    if (userQuery.trim().isEmpty) return;
    final nowStr = DateFormat('hh:mm a').format(DateTime.now());
    final stock = _stocks[_selectedIndex];
    final quote = stock.quote;

    setState(() {
      _chatMessages.add(ChatMessage(sender: 'user', text: userQuery, time: nowStr));
      _chatController.clear();
    });

    Timer(const Duration(milliseconds: 300), () {
      String reply = '';
      final q = userQuery.toLowerCase();
      final isTE = widget.language == 'TE';

      if (q.contains('stop') || q.contains('loss') || q.contains('స్టాప్')) {
        reply = isTE
            ? 'స్టాప్-లాస్ అంటే మీ నష్టాన్ని పరిమితం చేసే భద్రతా వలయం. మా యాప్‌లో ప్రతి ట్రేడ్‌కు గరిష్ట నష్టం Rs 100 గా సెట్ చేయబడింది.'
            : 'Stop-Loss is your pre-defined safety exit. In this app, your risk per trade is strictly capped at Rs 100 (1% of Rs 10,000 capital).';
      } else if (q.contains('vwap') || q.contains('rsi')) {
        reply = isTE
            ? 'VWAP అంటే వాల్యూమ్-వెయిటెడ్ వరేజ్ ధర (Rs ${quote?.vwap.toStringAsFixed(2)}). RSI అనేది మొమెంటం (ప్రస్తుత RSI: ${quote?.rsi14.toStringAsFixed(1)}).'
            : 'VWAP is Volume Weighted Average Price (Rs ${quote?.vwap.toStringAsFixed(2)}). RSI measures momentum (current RSI: ${quote?.rsi14.toStringAsFixed(1)}).';
      } else if (q.contains('profit') || q.contains('win') || q.contains('లాభం')) {
        reply = isTE
            ? 'పేపర్ ట్రేడింగ్‌లో మీరు వర్చువల్ రూపీస్‌తో లాభాలను పరీక్షిస్తున్నారు. ఇది నిజమైన డబ్బు కాదు, కేవలం అభ్యాసం మాత్రమే!'
            : 'Paper trading lets you test strategies with virtual money (Rs 10,000 base). Zero financial risk!';
      } else {
        reply = isTE
            ? '${stock.symbol} ప్రస్తుత ధర Rs ${quote?.price.toStringAsFixed(2)}. 15-నైపుణ్యాల ఏజెంట్ సిగ్నల్ ప్రకారం ${stock.actionCard?.action} చేయమని సూచిస్తోంది.'
            : 'For ${stock.symbol} (LTP Rs ${quote?.price.toStringAsFixed(2)}), our 15-skill agent recommends ${stock.actionCard?.action}. Check the Live tab for exact position sizing!';
      }

      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
              sender: 'tutor', text: reply, time: DateFormat('hh:mm a').format(DateTime.now())));
        });
      }
    });
  }

  void _reEvaluateAllCardsForLanguage(String newLang) {
    for (final s in _stocks) {
      if (s.quote != null) {
        s.actionCard = LocalPennyTraderAgent.evaluate(
          stock: s,
          quote: s.quote!,
          lang: newLang,
        );
      }
    }
    setState(() {});
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final lang = widget.language;
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(lang, 'settings'),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.get(lang, 'theme_title')),
                    subtitle: Text(AppStrings.get(lang, 'theme_sub')),
                    value: widget.isDarkMode,
                    onChanged: (val) {
                      widget.onThemeChanged(val);
                      setModalState(() {});
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.get(lang, 'lang_title')),
                    subtitle: Text(AppStrings.get(lang, 'lang_sub')),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'EN', label: Text('English')),
                        ButtonSegment(value: 'TE', label: Text('తెలుగు')),
                      ],
                      selected: {widget.language},
                      onSelectionChanged: (newSet) {
                        final chosen = newSet.first;
                        widget.onLanguageChanged(chosen);
                        _reEvaluateAllCardsForLanguage(chosen);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppStrings.get(lang, 'engine_info'),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppStrings.get(lang, 'close')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _badgeColorForAction(String action) {
    switch (action) {
      case 'BUY':
        return Colors.green.shade700;
      case 'SELL':
        return Colors.red.shade700;
      case 'WAIT':
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  // ---------------------------------------------------------------------------
  // Starting screen: every stock, strongest signals first
  // ---------------------------------------------------------------------------
  int _signalTier(StockItem s) {
    final c = s.actionCard;
    if (c == null) return 4;
    final bool actionable = c.action == 'BUY' || c.action == 'SELL';
    if (actionable && c.confidence == 'High') return 0;
    if (actionable) return 1;
    if (c.action == 'WAIT') return 2;
    return 3;
  }

  List<int> _rankedIndices() {
    final idx = List<int>.generate(_stocks.length, (i) => i);
    idx.sort((a, b) {
      final ta = _signalTier(_stocks[a]);
      final tb = _signalTier(_stocks[b]);
      if (ta != tb) return ta.compareTo(tb);
      final va = _stocks[a].quote?.volumeSpikeRatio ?? 0.0;
      final vb = _stocks[b].quote?.volumeSpikeRatio ?? 0.0;
      final byVolume = vb.compareTo(va);
      if (byVolume != 0) return byVolume;
      return _stocks[a].name.compareTo(_stocks[b].name);
    });
    return idx;
  }

  Color _signalColor(String action) {
    switch (action) {
      case 'BUY':
        return Colors.green;
      case 'SELL':
        return Colors.red;
      case 'WAIT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _openStock(int index) {
    setState(() {
      _selectedIndex = index;
      _bottomTabIndex = 0;
      _showStockDetail = true;
    });
    _fetchSingleStock(_stocks[index], showSpinner: false);
  }

  Future<void> _openSearch() async {
    final picked = await showSearch<int?>(
      context: context,
      delegate: _StockSearchDelegate(_stocks),
    );
    if (picked == null || !mounted) return;
    _openStock(picked);
  }

  Widget _marketStatusStrip(String lang) {
    final Color c = _isMarketOpen ? AppTheme.gain : Colors.orange;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isMarketOpen
                  ? AppStrings.get(lang, 'market_open')
                  : AppStrings.get(lang, 'market_closed'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankedHomeTab(String lang) {
    final ranked = _rankedIndices();
    final strongCount =
        ranked.where((i) => _signalTier(_stocks[i]) == 0).length;
    final scanned = _stocks.where((s) => s.actionCard != null).length;

    return Column(
      children: [
        _marketStatusStrip(lang),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Watchlist',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.gain.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$strongCount strong signals',
                  style: const TextStyle(
                    color: AppTheme.gain,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ranked by signal strength  •  $scanned/${_stocks.length} scanned',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.separated(
            itemCount: ranked.length,
            separatorBuilder: (context, i) => const Divider(),
            itemBuilder: (context, pos) {
              final index = ranked[pos];
              final stock = _stocks[index];
              final card = stock.actionCard;
              final quote = stock.quote;
              final tier = _signalTier(stock);
              final bool actionable = tier <= 1;
              final muted = Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6);

              double change = 0.0;
              if (quote != null && quote.previousClose > 0) {
                change = ((quote.price - quote.previousClose) /
                        quote.previousClose) *
                    100.0;
              }
              final Color moveColor =
                  change >= 0 ? AppTheme.gain : AppTheme.loss;
              final Color signalColor =
                  card == null ? Colors.grey : _signalColor(card.action);

              Widget right;
              if (quote != null) {
                right = Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs ${quote.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: moveColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, color: moveColor),
                    ),
                  ],
                );
              } else if (stock.isLoading) {
                right = const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              } else {
                right = Text('No data',
                    style: TextStyle(fontSize: 12, color: muted));
              }

              return InkWell(
                onTap: () => _openStock(index),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              '${pos + 1}',
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stock.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (card != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: signalColor.withValues(
                                              alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          card.action,
                                          style: TextStyle(
                                            color: signalColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    if (card != null && actionable) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '${card.confidence} confidence',
                                        style: TextStyle(
                                            fontSize: 11, color: muted),
                                      ),
                                    ] else if (card == null)
                                      Text(
                                        stock.symbol
                                            .replaceAll('.NS', '')
                                            .replaceAll('.BO', ''),
                                        style: TextStyle(
                                            fontSize: 11, color: muted),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          right,
                        ],
                      ),
                      if (card != null && actionable)
                        Padding(
                          padding: const EdgeInsets.only(left: 26, top: 8),
                          child: Text(
                            '${card.action == 'BUY' ? 'Buy' : 'Sell'} near Rs ${card.entryPrice.toStringAsFixed(2)}   Stop Rs ${card.stopLoss.toStringAsFixed(2)}   Target Rs ${card.targetPrice.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveAndSignalsTab(String lang) {
    final selectedStock = _stocks[_selectedIndex];
    final quote = selectedStock.quote;
    final card = selectedStock.actionCard;
    final timeFormatter = DateFormat('dd MMM, hh:mm:ss a');
    final googleSymbol = selectedStock.symbol
        .replaceAll('.NS', ':NSE')
        .replaceAll('.BO', ':BOM');

    return Column(
      children: [
        _marketStatusStrip(lang),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedStock.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                selectedStock.symbol
                    .replaceAll('.NS', '')
                    .replaceAll('.BO', ''),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              if (quote != null) ...[
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final double ch = quote.previousClose > 0
                      ? ((quote.price - quote.previousClose) /
                              quote.previousClose) *
                          100.0
                      : 0.0;
                  final Color mc = ch >= 0 ? AppTheme.gain : AppTheme.loss;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs ${quote.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: mc,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (quote != null && quote.isDelayedOver5Min)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${AppStrings.get(lang, 'delayed_badge')} (${quote.delayMinutes}m)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedStock.symbol,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  selectedStock.name,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (quote != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppStrings.get(lang, 'ltp'),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    'Rs ${quote.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (quote != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text('VWAP: Rs ${quote.vwap.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              Text('RSI: ${quote.rsi14.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              Text('MACD: ${quote.macdHist.toStringAsFixed(3)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  'S/R: Rs ${quote.supportLevel.toStringAsFixed(2)} / Rs ${quote.resistanceLevel.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              quote != null
                                  ? '${AppStrings.get(lang, 'candles_count')} ${quote.bars.length}'
                                  : '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                  value: false,
                                  label: Text(
                                      AppStrings.get(lang, 'chart_line'),
                                      style: const TextStyle(fontSize: 12)),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text(
                                      AppStrings.get(lang, 'chart_candle'),
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                              selected: {_showCandlestick},
                              onSelectionChanged: (val) {
                                setState(() {
                                  _showCandlestick = val.first;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (selectedStock.isLoading)
                          const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (selectedStock.errorMessage.isNotEmpty)
                          SizedBox(
                            height: 180,
                            child: Center(
                              child: Text(
                                selectedStock.errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          )
                        else if (quote != null && quote.bars.isNotEmpty)
                          Container(
                            height: 180,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomPaint(
                              painter: StockChartPainter(
                                bars: quote.bars,
                                isCandlestick: _showCandlestick,
                                isDark: widget.isDarkMode,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 180,
                            child: Center(
                              child: Text(AppStrings.get(lang, 'no_candles')),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (quote != null) ...[
                          Text(
                            '${AppStrings.get(lang, 'trade_time')}: ${timeFormatter.format(quote.tradeTimeIst)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.get(lang, 'verify_title')} google.com/finance/quote/$googleSymbol',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (card != null)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _badgeColorForAction(card.action),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  AppStrings.get(lang, 'card_header'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _badgeColorForAction(card.action),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '2. ACTION: ${card.action}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.get(lang, 'freshness_label'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            card.dataFreshness,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color:
                                  card.dataFreshness.contains('PRACTICE ONLY')
                                      ? Colors.redAccent
                                      : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${AppStrings.get(lang, 'confidence_label')} ${card.confidence}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(card.confidenceReason,
                              style: const TextStyle(fontSize: 13)),
                          const Divider(height: 20),
                          Text(
                            AppStrings.get(lang, 'trade_plan_label'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              Text(
                                  '${AppStrings.get(lang, 'entry_label')}: Rs ${card.entryPrice.toStringAsFixed(2)}'),
                              Text(
                                  '${AppStrings.get(lang, 'shares_label')}: ${card.sharesForMaxLoss100} shares'),
                              Text(
                                  '${AppStrings.get(lang, 'cost_label')}: Rs ${card.estimatedCapitalUsed.toStringAsFixed(0)}'),
                              Text(
                                  '${AppStrings.get(lang, 'sl_label')}: Rs ${card.stopLoss.toStringAsFixed(2)}'),
                              Text(
                                  '${AppStrings.get(lang, 'target_label')}: Rs ${card.targetPrice.toStringAsFixed(2)}'),
                              Text(
                                  '${AppStrings.get(lang, 'rr_label')}: ${card.riskRewardRatio}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.squareOffNote,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (card.action == 'BUY' || card.action == 'SELL')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _logPaperTrade(selectedStock,
                                    forcePracticeBuy: false),
                                icon: const Icon(Icons.assignment_turned_in),
                                label:
                                    Text(AppStrings.get(lang, 'log_signal_btn')),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _logPaperTrade(selectedStock,
                                    forcePracticeBuy: true),
                                icon: const Icon(Icons.science_outlined),
                                label:
                                    Text(AppStrings.get(lang, 'sim_trade_btn')),
                              ),
                            ),
                          const Divider(height: 20),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              AppStrings.get(lang, 'skills_panel_title'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            children: card.fifteenSkillsReport.map((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      item.isPositive
                                          ? Icons.check_circle_outline
                                          : Icons.info_outline,
                                      size: 16,
                                      color: item.isPositive
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.isDarkMode
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '${item.title}: ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(text: item.finding),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(height: 16),
                          Text(
                            card.footerDisclaimer,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTab(String lang) {
    final openTrades =
        _paperTrades.where((t) => t.status == 'OPEN').toList();
    final closedTrades =
        _paperTrades.where((t) => t.status != 'OPEN').toList();

    double realizedPnl = 0.0;
    int wins = 0;
    int losses = 0;
    double sumWins = 0.0;
    double sumLosses = 0.0;

    for (final t in closedTrades) {
      realizedPnl += t.realizedPnl;
      if (t.realizedPnl > 0) {
        wins++;
        sumWins += t.realizedPnl;
      } else if (t.realizedPnl < 0) {
        losses++;
        sumLosses += t.realizedPnl.abs();
      }
    }

    double unrealizedPnl = 0.0;
    for (final t in openTrades) {
      double ltp = t.entryPrice;
      for (final s in _stocks) {
        if (s.symbol == t.symbol && s.quote != null) {
          ltp = s.quote!.price;
          break;
        }
      }
      unrealizedPnl += t.currentUnrealizedPnl(ltp);
    }

    final double totalProfit = realizedPnl + unrealizedPnl;
    final double totalEquity = kVirtualCapital + totalProfit;
    final double winRate =
        closedTrades.isNotEmpty ? (wins / closedTrades.length) * 100.0 : 0.0;
    final double avgWin = wins > 0 ? (sumWins / wins) : 0.0;
    final double avgLoss = losses > 0 ? (sumLosses / losses) : 0.0;
    final double openRisk = openTrades.length * kMaxRiskPerTrade;

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  AppStrings.get(lang, 'results_title'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _resetPaperAccount,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(AppStrings.get(lang, 'reset_btn'),
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get(lang, 'total_equity'),
                          style: const TextStyle(fontSize: 13)),
                      Text(
                        'Rs ${totalEquity.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get(lang, 'total_pnl'),
                          style: const TextStyle(fontSize: 13)),
                      Text(
                        '${totalProfit >= 0 ? "+" : ""}Rs ${totalProfit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: totalProfit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppStrings.get(lang, 'win_rate')}: ${winRate.toStringAsFixed(1)}% ($wins/${closedTrades.length})',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${AppStrings.get(lang, 'avg_win')}: +Rs ${avgWin.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.green),
                      ),
                      Text(
                        '${AppStrings.get(lang, 'avg_loss')}: -Rs ${avgLoss.toStringAsFixed(1)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      Text(
                        '${AppStrings.get(lang, 'open_risk')}: Rs ${openRisk.toStringAsFixed(0)} / Rs 300',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _paperTrades.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.get(lang, 'no_trades'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _paperTrades.length,
                    itemBuilder: (context, index) {
                      final t = _paperTrades[index];
                      double ltp = t.entryPrice;
                      for (final s in _stocks) {
                        if (s.symbol == t.symbol && s.quote != null) {
                          ltp = s.quote!.price;
                          break;
                        }
                      }
                      final pnl = t.status == 'OPEN'
                          ? t.currentUnrealizedPnl(ltp)
                          : t.realizedPnl;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${t.symbol} • ${t.action} (${t.shares} shares)',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    '${pnl >= 0 ? "+" : ""}Rs ${pnl.toStringAsFixed(2)} (${t.status})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: pnl >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              if (t.isDelayedPractice)
                                const Text(
                                  'PRACTICE ONLY - DELAYED / SIMULATED DATA',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Entry: Rs ${t.entryPrice.toStringAsFixed(2)} | SL: Rs ${t.stopLoss.toStringAsFixed(2)} | Target: Rs ${t.targetPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Logged: ${t.entryTimeIst}${t.exitTimeIst != null ? " • Closed: ${t.exitTimeIst}" : ""}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              if (t.status == 'OPEN') ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _closePaperTradeManually(t, 'LTP'),
                                      child: Text(
                                          AppStrings.get(lang, 'close_at_ltp'),
                                          style:
                                              const TextStyle(fontSize: 11)),
                                    ),
                                    OutlinedButton(
                                      onPressed: () =>
                                          _closePaperTradeManually(t, 'TARGET'),
                                      child: Text(
                                          AppStrings.get(lang, 'sim_target'),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.green)),
                                    ),
                                    OutlinedButton(
                                      onPressed: () =>
                                          _closePaperTradeManually(t, 'SL'),
                                      child: Text(
                                          AppStrings.get(lang, 'sim_sl'),
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiChatTab(String lang) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.get(lang, 'chat_title'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isUser = msg.sender == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade700
                          : (widget.isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.time,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: AppStrings.get(lang, 'chat_hint'),
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: _sendChatMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _sendChatMessage(_chatController.text),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final selectedStock = _stocks[_selectedIndex];

    final bool onDetail = _bottomTabIndex == 0 && _showStockDetail;

    return PopScope(
      canPop: !onDetail,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _showStockDetail = false);
        }
      },
      child: Scaffold(
  floatingActionButton: Builder(
    builder: (context) => FloatingActionButton.extended(
      backgroundColor: Colors.greenAccent,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.psychology),
      label: const Text(
        'Trader AI',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TraderAgentScreen()),
        );
      },
    ),
  ),
      appBar: AppBar(
        leading: onDetail
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showStockDetail = false),
              )
            : null,
        title: Text(AppStrings.get(lang, 'app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search stocks by name',
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_bottomTabIndex == 0 && !_showStockDetail) {
                _sweepAll(showSpinner: false);
              } else {
                _fetchSingleStock(selectedStock, showSpinner: true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsSheet,
          ),
        ],
      ),
      body: _bottomTabIndex == 0
          ? (_showStockDetail
              ? _buildLiveAndSignalsTab(lang)
              : _buildRankedHomeTab(lang))
          : (_bottomTabIndex == 1
              ? _buildResultsTab(lang)
              : _buildAiChatTab(lang)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomTabIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _bottomTabIndex = idx;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.candlestick_chart),
            label: AppStrings.get(lang, 'nav_live'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assessment_outlined),
            label: AppStrings.get(lang, 'nav_results'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            label: AppStrings.get(lang, 'nav_chat'),
          ),
        ],
      ),
    ),
    );
  }
}

/// Google-style name search: type "y" and every stock whose name starts with
/// "y" is listed; each extra letter narrows it further.
class _StockSearchDelegate extends SearchDelegate<int?> {
  final List<StockItem> stocks;

  _StockSearchDelegate(this.stocks)
      : super(searchFieldLabel: 'Search stocks by name');

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _matches(context);

  @override
  Widget buildSuggestions(BuildContext context) => _matches(context);

  Widget _matches(BuildContext context) {
    final q = query.trim().toLowerCase();
    final found = <int>[];
    for (var i = 0; i < stocks.length; i++) {
      if (q.isEmpty || stocks[i].name.toLowerCase().startsWith(q)) {
        found.add(i);
      }
    }
    found.sort((a, b) =>
        stocks[a].name.toLowerCase().compareTo(stocks[b].name.toLowerCase()));

    if (found.isEmpty) {
      return Center(child: Text('No stock name starts with "${query.trim()}"'));
    }
    return ListView.builder(
      itemCount: found.length,
      itemBuilder: (context, pos) {
        final i = found[pos];
        final stock = stocks[i];
        final card = stock.actionCard;
        final price = stock.quote == null
            ? ''
            : '  •  Rs ${stock.quote!.price.toStringAsFixed(2)}';
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(stock.name),
          subtitle: Text(
              '${stock.symbol.replaceAll('.NS', '').replaceAll('.BO', '')}$price'),
          trailing: card == null ? null : Text(card.action),
          onTap: () => close(context, i),
        );
      },
    );
  }
}

class StockChartPainter extends CustomPainter {
  final List<OhlcvBar> bars;
  final bool isCandlestick;
  final bool isDark;

  StockChartPainter({
    required this.bars,
    required this.isCandlestick,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    double minPrice = bars.first.low;
    double maxPrice = bars.first.high;
    for (final b in bars) {
      if (b.low < minPrice) minPrice = b.low;
      if (b.high > maxPrice) maxPrice = b.high;
    }
    if ((maxPrice - minPrice).abs() < 0.001) {
      maxPrice += 0.05;
      minPrice -= 0.05;
    }

    const double rightLabelWidth = 46.0;
    final double chartWidth = size.width - rightLabelWidth;
    final double chartHeight = size.height;

    double priceToY(double p) {
      final ratio = (p - minPrice) / (maxPrice - minPrice);
      return chartHeight - (ratio * (chartHeight - 16)) - 8;
    }

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    final levels = [maxPrice, (maxPrice + minPrice) / 2, minPrice];
    for (final priceLevel in levels) {
      final y = priceToY(priceLevel);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: priceLevel.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartWidth + 4, y - 6));
    }

    final int count = bars.length;
    final double slotWidth = chartWidth / math.max(count, 1);

    if (!isCandlestick) {
      final linePaint = Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < count; i++) {
        final x = (i + 0.5) * slotWidth;
        final y = priceToY(bars[i].close);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    } else {
      final double candleWidth = math.max(2.0, slotWidth * 0.65);

      for (int i = 0; i < count; i++) {
        final b = bars[i];
        final bool isBullish = b.close >= b.open;
        final Color color = isBullish ? Colors.green : Colors.red;

        final double centerX = (i + 0.5) * slotWidth;
        final double highY = priceToY(b.high);
        final double lowY = priceToY(b.low);
        final double openY = priceToY(b.open);
        final double closeY = priceToY(b.close);

        final wickPaint = Paint()
          ..color = color
          ..strokeWidth = 1.2;
        canvas.drawLine(
            Offset(centerX, highY), Offset(centerX, lowY), wickPaint);

        final double topY = math.min(openY, closeY);
        final double bottomY = math.max(openY, closeY);
        final double bodyHeight = math.max(2.0, bottomY - topY);

        final bodyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
              centerX - candleWidth / 2, topY, candleWidth, bodyHeight),
          bodyPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StockChartPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.isCandlestick != isCandlestick ||
        oldDelegate.isDark == isDark;
  }
}
