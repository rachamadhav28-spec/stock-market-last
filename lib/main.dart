import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PennyTraderApp());
}

class PennyTraderApp extends StatefulWidget {
  const PennyTraderApp({super.key});

  @override
  State<PennyTraderApp> createState() => _PennyTraderAppState();
}

class _PennyTraderAppState extends State<PennyTraderApp> {
  bool _isDarkMode = true;
  String _language = 'EN';
  String _geminiApiKey = '';
  String _customAnalystPrompt = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? true;
      _language = prefs.getString('app_lang') ?? 'EN';
      _geminiApiKey = prefs.getString('gemini_api_key') ?? '';
      _customAnalystPrompt = prefs.getString('custom_analyst_prompt') ?? '';
    });
  }

  Future<void> _updateTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _updateLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    setState(() {
      _language = lang;
    });
  }

  Future<void> _saveSecrets(String apiKey, String customPrompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey.trim());
    await prefs.setString('custom_analyst_prompt', customPrompt.trim());
    setState(() {
      _geminiApiKey = apiKey.trim();
      _customAnalystPrompt = customPrompt.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penny Stock Trader',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: Stage3Screen(
        isDarkMode: _isDarkMode,
        language: _language,
        geminiApiKey: _geminiApiKey,
        customAnalystPrompt: _customAnalystPrompt,
        onThemeChanged: _updateTheme,
        onLanguageChanged: _updateLanguage,
        onSecretsSaved: _saveSecrets,
      ),
    );
  }
}

// Bilingual UI Dictionary (English & Telugu)
class AppStrings {
  static String get(String lang, String key) {
    const Map<String, Map<String, String>> dict = {
      'EN': {
        'app_title': 'Penny Trader - Stage 3',
        'market_open': 'NSE Market OPEN (9:15-3:30 IST) • 10s Live Update',
        'market_closed': 'Market CLOSED • Showing Last Session Snapshot',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'Last Traded Price (NSE)',
        'trade_time': 'Exchange Trade Time (IST)',
        'fetch_time': 'Phone Fetch Time (IST)',
        'chart_line': 'Line Graph',
        'chart_candle': 'Candlestick',
        'no_candles': 'No intraday candles available',
        'settings': 'Settings & Local Phone Secrets',
        'theme_title': 'Dark Theme',
        'theme_sub': 'Switch between Dark and Light screen mode',
        'lang_title': 'App & AI Language',
        'lang_sub': 'Choose English or Telugu (తెలుగు)',
        'key_label': 'Gemini API Key (Saved only on this phone)',
        'key_hint': 'Paste your Google AI Studio key here',
        'prompt_label': 'Private Analyst Prompt (Optional Override)',
        'prompt_hint': 'Leave blank for built-in rules, or paste your custom role prompt',
        'save_close': 'Save & Close',
        'verify_title': 'Same-Minute Google Finance Test:',
        'candles_count': '5-Min Bars:',
        'run_analyst': 'Analyze Stock (AI Action Card)',
        'analyzing': 'Evaluating <data> tags, VWAP, RSI & Penny Rules...',
        'missing_key': 'Tap Settings (gear icon) and save your Gemini API Key first.',
        'rate_limit': 'HTTP 429: Free AI quota paused — please wait 60 seconds and retry.',
        'card_header': 'AI INTRADAY ACTION CARD',
        'freshness_label': '1. Data Freshness:',
        'confidence_label': '3. Confidence:',
        'trade_plan_label': '4. Position & Risk Plan (Max Loss Rs 100):',
        'entry_label': 'Entry Price',
        'shares_label': 'Max Shares',
        'sl_label': 'Stop-Loss',
        'target_label': 'Target (Min 1:2)',
        'rr_label': 'Risk : Reward',
        'why_label': '5. Why (1 Line Each):',
        'tech_label': 'Technical',
        'fund_label': 'Fundamental',
        'news_label': 'News',
        'wrong_label': '6. What Would Prove This Wrong:',
        'gaps_label': '7. Data Gaps:',
        'disclaimer': 'Educational analysis, not financial advice. Paper trading only.',
      },
      'TE': {
        'app_title': 'పెన్నీ ట్రేడర్ - దశ 3',
        'market_open': 'NSE మార్కెట్ తెరిచి ఉంది (9:15-3:30 IST) • 10s లైవ్',
        'market_closed': 'మార్కెట్ మూసివేయబడింది • చివరి సెషన్ డేటా',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'చివరి ట్రేడ్ ధర (NSE)',
        'trade_time': 'ఎక్స్ఛేంజ్ ట్రేడ్ సమయం (IST)',
        'fetch_time': 'ఫోన్ సేకరించిన సమయం (IST)',
        'chart_line': 'లైన్ గ్రాఫ్',
        'chart_candle': 'కాండిల్ స్టిక్',
        'no_candles': 'ఇంట్రాడే కాండిల్ డేటా అందుబాటులో లేదు',
        'settings': 'సెట్టింగ్‌లు & ఫోన్ సీక్రెట్స్',
        'theme_title': 'డార్క్ థీమ్ (Dark Theme)',
        'theme_sub': 'డార్క్ లేదా లైట్ స్క్రీన్ మోడ్ మార్చండి',
        'lang_title': 'భాష (Language)',
        'lang_sub': 'ఇంగ్లీష్ లేదా తెలుగు ఎంచుకోండి',
        'key_label': 'Gemini API కీ (మీ ఫోన్‌లో మాత్రమే సేవ్ చేయబడుతుంది)',
        'key_hint': 'మీ Google AI Studio కీని ఇక్కడ పేస్ట్ చేయండి',
        'prompt_label': 'ప్రైవేట్ అనలిస్ట్ ప్రాంప్ట్ (ఐచ్ఛికం)',
        'prompt_hint': 'ఖాళీగా ఉంచండి లేదా మీ ప్రాంప్ట్‌ను పేస్ట్ చేయండి',
        'save_close': 'సేవ్ చేసి మూసివేయి',
        'verify_title': 'గూగుల్ ఫైనాన్స్ ధర తనిఖీ:',
        'candles_count': '5-నిమిషాల కాండిల్స్:',
        'run_analyst': 'AI యాక్షన్ కార్డ్ రూపొందించండి',
        'analyzing': '<data> ట్యాగ్‌లు, VWAP, RSI మరియు పెన్నీ నియమాలను విశ్లేషిస్తోంది...',
        'missing_key': 'దయచేసి ముందుగా సెట్టింగ్‌లలో (Gear Icon) మీ Gemini API కీని సేవ్ చేయండి.',
        'rate_limit': 'HTTP 429: ఉచిత AI పరిమితి చేరుకుంది — 60 సెకన్లు ఆగి మళ్లీ ప్రయత్నించండి.',
        'card_header': 'AI ఇంట్రాడే యాక్షన్ కార్డ్',
        'freshness_label': '1. డేటా తాజాదనం (Data Freshness):',
        'confidence_label': '3. నమ్మకం స్థాయి (Confidence):',
        'trade_plan_label': '4. ట్రేడ్ ప్లాన్ (గరిష్ట నష్టం Rs 100):',
        'entry_label': 'ఎంట్రీ ధర',
        'shares_label': 'షేర్ల సంఖ్య',
        'sl_label': 'స్టాప్-లాస్ (SL)',
        'target_label': 'టార్గెట్ (కనీసం 1:2)',
        'rr_label': 'రిస్క్ : రివార్డ్',
        'why_label': '5. కారణాలు (Why):',
        'tech_label': 'టెక్నికల్',
        'fund_label': 'ఫండమెంటల్',
        'news_label': 'వార్తలు (News)',
        'wrong_label': '6. ఇది తప్పు అని ఏది నిరూపిస్తుంది:',
        'gaps_label': '7. డేటా లోపాలు (Data Gaps):',
        'disclaimer': 'Educational analysis, not financial advice. Paper trading only.',
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

// Structured 7-Point Action Card Model matching your exact analyst specification
class ActionCardData {
  final String dataFreshness;
  final String action; // Strictly BUY, SELL, WAIT, or AVOID
  final String confidence; // Low, Medium, High
  final String confidenceReason;
  final double entryPrice;
  final int sharesForMaxLoss100;
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

  ActionCardData({
    required this.dataFreshness,
    required this.action,
    required this.confidence,
    required this.confidenceReason,
    required this.entryPrice,
    required this.sharesForMaxLoss100,
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
  });
}

class StockQuote {
  final double price;
  final double previousClose;
  final double dayHigh;
  final double dayLow;
  final int totalDayVolume;
  final double vwap;
  final double rsi14;
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
    required this.rsi14,
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
    final double rsi14 = _calculateRsi14(parsedBars);

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
      rsi14: rsi14,
      tradeTimeIst: tradeTimeIst,
      fetchTimeIst: nowIst,
      delayMinutes: diffMinutes < 0 ? 0 : diffMinutes,
      isDelayedOver5Min: diffMinutes > 5,
      bars: recentBars,
    );
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
}

class StockItem {
  final String symbol;
  final String name;
  StockQuote? quote;
  ActionCardData? actionCard;
  bool isLoading;
  bool isAiLoading;
  String errorMessage;
  String aiErrorMessage;

  StockItem({
    required this.symbol,
    required this.name,
    this.quote,
    this.actionCard,
    this.isLoading = true,
    this.isAiLoading = false,
    this.errorMessage = '',
    this.aiErrorMessage = '',
  });
}

class Stage3Screen extends StatefulWidget {
  final bool isDarkMode;
  final String language;
  final String geminiApiKey;
  final String customAnalystPrompt;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final Future<void> Function(String apiKey, String customPrompt) onSecretsSaved;

  const Stage3Screen({
    super.key,
    required this.isDarkMode,
    required this.language,
    required this.geminiApiKey,
    required this.customAnalystPrompt,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onSecretsSaved,
  });

  @override
  State<Stage3Screen> createState() => _Stage3ScreenState();
}

class _Stage3ScreenState extends State<Stage3Screen> {
  final MarketDataProvider _dataProvider = YahooDataProvider();

  final List<StockItem> _stocks = [
    StockItem(symbol: 'IDEA.NS', name: 'Vodafone Idea Ltd'),
    StockItem(symbol: 'YESBANK.NS', name: 'Yes Bank Ltd'),
    StockItem(symbol: 'JPPOWER.NS', name: 'Jaiprakash Power Ventures'),
    StockItem(symbol: 'RPOWER.NS', name: 'Reliance Power Ltd'),
    StockItem(symbol: 'GTLINFRA.NS', name: 'GTL Infrastructure Ltd'),
  ];

  int _selectedIndex = 0;
  bool _isMarketOpen = false;
  bool _showCandlestick = true;
  Timer? _activeStockTimer;

  @override
  void initState() {
    super.initState();
    _initializeAndStartPolling();
  }

  @override
  void dispose() {
    _activeStockTimer?.cancel();
    super.dispose();
  }

  bool _checkMarketHoursNow() {
    final nowIst =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    if (nowIst.weekday == DateTime.saturday ||
        nowIst.weekday == DateTime.sunday) {
      return false;
    }
    final totalMinutes = nowIst.hour * 60 + nowIst.minute;
    const marketOpen = 9 * 60 + 15;
    const marketClose = 15 * 60 + 30;
    return totalMinutes >= marketOpen && totalMinutes <= marketClose;
  }

  Future<void> _initializeAndStartPolling() async {
    setState(() {
      _isMarketOpen = _checkMarketHoursNow();
    });

    for (final stock in _stocks) {
      await _fetchSingleStock(stock, showSpinner: true);
    }

    _activeStockTimer?.cancel();
    _activeStockTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final openNow = _checkMarketHoursNow();
      if (openNow != _isMarketOpen) {
        setState(() {
          _isMarketOpen = openNow;
        });
      }
      if (_isMarketOpen) {
        _fetchSingleStock(_stocks[_selectedIndex], showSpinner: false);
      }
    });
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
      final quote = await _dataProvider.fetchQuoteAndChart(stock.symbol);
      if (!mounted) return;
      setState(() {
        stock.quote = quote;
        stock.isLoading = false;
        stock.errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        stock.errorMessage = 'Could not load price ($e)';
        stock.isLoading = false;
      });
    }
  }

  // Builds the strict <data> XML block for your Intraday Analyst Agent
  String _buildDataXmlTag(StockItem stock, StockQuote quote) {
    final recent5 = quote.bars.length > 5
        ? quote.bars.sublist(quote.bars.length - 5)
        : quote.bars;
    final candlesText = recent5
        .map((b) =>
            '${DateFormat("HH:mm").format(b.timeIst)}: O=${b.open.toStringAsFixed(2)} H=${b.high.toStringAsFixed(2)} L=${b.low.toStringAsFixed(2)} C=${b.close.toStringAsFixed(2)} V=${b.volume}')
        .join(' | ');

    final changePct = quote.previousClose > 0
        ? (((quote.price - quote.previousClose) / quote.previousClose) * 100)
            .toStringAsFixed(2)
        : '0.00';

    return '''
<data>
  symbol: ${stock.symbol} (${stock.name})
  exchange_segment: NSE EQ (User must verify ASM/GSM surveillance status on nseindia.com)
  current_price_inr: ${quote.price.toStringAsFixed(2)}
  previous_close_inr: ${quote.previousClose.toStringAsFixed(2)}
  day_change_percent: $changePct%
  day_high_inr: ${quote.dayHigh.toStringAsFixed(2)}
  day_low_inr: ${quote.dayLow.toStringAsFixed(2)}
  intraday_total_volume: ${quote.totalDayVolume} shares
  min_safe_volume_rule: 500000 shares/day
  indicators:
    vwap_inr: ${quote.vwap.toStringAsFixed(2)}
    rsi_14_5m: ${quote.rsi14.toStringAsFixed(1)}
    last_5_candles_5m: $candlesText
  fundamentals: MISSING (Yahoo free chart feed does not include P/E, debt, or quarterly earnings)
  news: MISSING (Yahoo free chart feed does not include verified live NSE corporate announcements)
  trade_timestamp_ist: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(quote.tradeTimeIst)} IST
  phone_fetch_timestamp_ist: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(quote.fetchTimeIst)} IST
  data_age_minutes: ${quote.delayMinutes}
  is_older_than_5_minutes: ${quote.isDelayedOver5Min}
</data>''';
  }

  Future<void> _runIntradayAnalyst(StockItem stock) async {
    final quote = stock.quote;
    if (quote == null) return;

    if (widget.geminiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get(widget.language, 'missing_key')),
        ),
      );
      _openSettingsSheet();
      return;
    }

    setState(() {
      stock.isAiLoading = true;
      stock.aiErrorMessage = '';
    });

    final langName =
        widget.language == 'TE' ? 'Telugu (తెలుగు script)' : 'English';
    final dataXml = _buildDataXmlTag(stock, quote);

    // Uses your custom prompt from phone storage if provided, plus enforces strict JSON keys
    final roleRules = widget.customAnalystPrompt.isNotEmpty
        ? widget.customAnalystPrompt
        : '''
ROLE: Disciplined intraday analyst for Indian penny stocks (NSE/BSE).
Use ONLY the data inside <data> tags; if something is missing, say so.
PENNY STOCK RULES:
- Low volume (<5,00,000 daily shares) or wide spread: AVOID.
- Near a price limit, under exchange surveillance, or in a segment without intraday trading: AVOID.
- Sudden spike with no news: flag possible manipulation; do not chase.
- Default to WAIT or AVOID unless technicals, fundamentals AND news agree.
- Max loss per trade is strictly Rs 100. Target must be minimum 1:2 risk-reward, else AVOID.
- Never claim certainty.''';

    final fullPrompt = '''
$roleRules

LANGUAGE = $langName.
Reply in $langName (use Telugu script if Telugu), but keep stock symbols, numbers, and the exact action word (BUY / SELL / WAIT / AVOID) in English.

INPUT:
$dataXml

Respond ONLY with a valid JSON object matching these exact keys:
{
  "data_freshness": "If is_older_than_5_minutes is true, MUST start with 'PRACTICE ONLY - DELAYED DATA' and treat signal as practice, otherwise state LIVE DATA",
  "action": "BUY or SELL or WAIT or AVOID",
  "confidence": "Low or Medium or High",
  "confidence_reason": "One plain sentence reason in $langName",
  "entry_price": ${quote.price.toStringAsFixed(2)},
  "stop_loss": 0.0,
  "target_price": 0.0,
  "technical_why": "One plain line on price vs VWAP, RSI, and volume in $langName",
  "fundamental_why": "One plain line (explicitly state if missing in <data>) in $langName",
  "news_why": "One plain line (explicitly state if missing in <data>) in $langName",
  "what_proves_wrong": "One plain line on what price or volume action invalidates this view in $langName",
  "data_gaps": "List every missing item from <data> (e.g. fundamentals, live news, order book spread, ASM/GSM list) in $langName"
}''';

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${widget.geminiApiKey}');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': fullPrompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'responseMimeType': 'application/json',
              }
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (response.statusCode == 429) {
        setState(() {
          stock.aiErrorMessage = AppStrings.get(widget.language, 'rate_limit');
          stock.isAiLoading = false;
        });
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          stock.aiErrorMessage =
              'Gemini API Error (${response.statusCode}): Please verify your API Key in Settings.';
          stock.isAiLoading = false;
        });
        return;
      }

      final body = jsonDecode(response.body);
      final rawText =
          body['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      final cleaned =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> j = jsonDecode(cleaned);

      String action = (j['action'] ?? 'AVOID').toString().toUpperCase().trim();
      if (!['BUY', 'SELL', 'WAIT', 'AVOID'].contains(action)) {
        action = 'AVOID';
      }

      final double entry =
          (j['entry_price'] as num?)?.toDouble() ?? quote.price;
      double sl = (j['stop_loss'] as num?)?.toDouble() ?? 0.0;
      double target = (j['target_price'] as num?)?.toDouble() ?? 0.0;

      //Deterministic Safety Math: Verify Position Size for Rs 100 Max Loss & 1:2 Risk-Reward
      int shares = 0;
      String rrString = 'N/A';

      if (action == 'BUY' || action == 'SELL') {
        final double riskPerShare = (entry - sl).abs();
        final double rewardPerShare = (target - entry).abs();

        if (riskPerShare <= 0.01) {
          action = 'AVOID';
        } else {
          final double rr = rewardPerShare / riskPerShare;
          rrString = '1 : ${rr.toStringAsFixed(1)}';
          // Enforce strict 1:2 minimum risk-reward rule
          if (rr < 1.95) {
            action = 'AVOID';
          } else {
            shares = (100.0 / riskPerShare).floor();
            if (shares < 1) {
              action = 'AVOID';
            }
          }
        }
      }

      final String freshnessText = quote.isDelayedOver5Min
          ? 'PRACTICE ONLY - DELAYED DATA (${quote.delayMinutes} min delay)'
          : (j['data_freshness'] ?? 'LIVE DATA (<5 min delay)').toString();

      final card = ActionCardData(
        dataFreshness: freshnessText,
        action: action,
        confidence: (j['confidence'] ?? 'Low').toString(),
        confidenceReason: (j['confidence_reason'] ?? '').toString(),
        entryPrice: entry,
        sharesForMaxLoss100: shares,
        stopLoss: sl,
        targetPrice: target,
        riskRewardRatio: rrString,
        squareOffNote: 'Square off before market close (3:20 PM IST)',
        technicalWhy: (j['technical_why'] ?? '').toString(),
        fundamentalWhy: (j['fundamental_why'] ?? '').toString(),
        newsWhy: (j['news_why'] ?? '').toString(),
        whatProvesWrong: (j['what_proves_wrong'] ?? '').toString(),
        dataGaps: (j['data_gaps'] ?? '').toString(),
        footerDisclaimer:
            'Educational analysis, not financial advice. Paper trading only.',
      );

      setState(() {
        stock.actionCard = card;
        stock.isAiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        stock.aiErrorMessage = 'AI parsing error ($e)';
        stock.isAiLoading = false;
      });
    }
  }

  void _openSettingsSheet() {
    final keyCtrl = TextEditingController(text: widget.geminiApiKey);
    final promptCtrl = TextEditingController(text: widget.customAnalystPrompt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final lang = widget.language;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                          widget.onLanguageChanged(newSet.first);
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: keyCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.get(lang, 'key_label'),
                        hintText: AppStrings.get(lang, 'key_hint'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: promptCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: AppStrings.get(lang, 'prompt_label'),
                        hintText: AppStrings.get(lang, 'prompt_hint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await widget.onSecretsSaved(
                              keyCtrl.text, promptCtrl.text);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save),
                        label: Text(AppStrings.get(lang, 'save_close')),
                      ),
                    ),
                  ],
                ),
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

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final selectedStock = _stocks[_selectedIndex];
    final quote = selectedStock.quote;
    final card = selectedStock.actionCard;
    final timeFormatter = DateFormat('dd MMM, hh:mm:ss a');
    final googleSymbol = selectedStock.symbol.replaceAll('.NS', ':NSE');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(lang, 'app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                _fetchSingleStock(selectedStock, showSpinner: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Market Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: _isMarketOpen
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            child: Text(
              _isMarketOpen
                  ? AppStrings.get(lang, 'market_open')
                  : AppStrings.get(lang, 'market_closed'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: _isMarketOpen ? Colors.green : Colors.orange,
              ),
            ),
          ),

          // 2. 5 Starter Stocks Tabs
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedIndex;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(_stocks[index].symbol.replaceAll('.NS', '')),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 3. Scrollable Main Content: Chart Card + AI Action Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Price & Switchable Chart Card
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
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                    'VWAP: Rs ${quote.vwap.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text('RSI(14): ${quote.rsi14.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text('Vol: ${quote.totalDayVolume}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
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
                              height: 190,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (selectedStock.errorMessage.isNotEmpty)
                            SizedBox(
                              height: 190,
                              child: Center(
                                child: Text(
                                  selectedStock.errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          else if (quote != null && quote.bars.isNotEmpty)
                            Container(
                              height: 190,
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.3)),
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
                              height: 190,
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
                            Text(
                              '${AppStrings.get(lang, 'fetch_time')}: ${timeFormatter.format(quote.fetchTimeIst)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            '${AppStrings.get(lang, 'verify_title')} google.com/finance/quote/$googleSymbol',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Button to Trigger AI Intraday Analyst
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: (quote == null || selectedStock.isAiLoading)
                        ? null
                        : () => _runIntradayAnalyst(selectedStock),
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(
                      AppStrings.get(lang, 'run_analyst'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // AI Loading / Error / 7-Point Action Card Output
                  if (selectedStock.isAiLoading)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.get(lang, 'analyzing'),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (selectedStock.aiErrorMessage.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          selectedStock.aiErrorMessage,
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (card != null)
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
                            // Header + 2. ACTION Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.get(lang, 'card_header'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey),
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

                            // 1. Data Freshness
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
                                color: card.dataFreshness
                                        .contains('PRACTICE ONLY')
                                    ? Colors.redAccent
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 3. Confidence + 1-line reason
                            Text(
                              '${AppStrings.get(lang, 'confidence_label')} ${card.confidence}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(card.confidenceReason,
                                style: const TextStyle(fontSize: 13)),

                            const Divider(height: 20),

                            // 4. If BUY or SELL: Entry, Shares for Rs 100 max loss, SL, Target, Square Off
                            if (card.action == 'BUY' ||
                                card.action == 'SELL') ...[
                              Text(
                                AppStrings.get(lang, 'trade_plan_label'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  Text(
                                      '${AppStrings.get(lang, 'entry_label')}: Rs ${card.entryPrice.toStringAsFixed(2)}'),
                                  Text(
                                      '${AppStrings.get(lang, 'shares_label')}: ${card.sharesForMaxLoss100}'),
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
                              const Divider(height: 20),
                            ],

                            // 5. Why (1 line each: Technical, Fundamental, News)
                            Text(
                              AppStrings.get(lang, 'why_label'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                '• ${AppStrings.get(lang, 'tech_label')}: ${card.technicalWhy}',
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                                '• ${AppStrings.get(lang, 'fund_label')}: ${card.fundamentalWhy}',
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                                '• ${AppStrings.get(lang, 'news_label')}: ${card.newsWhy}',
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 10),

                            // 6. What would prove this wrong
                            Text(
                              AppStrings.get(lang, 'wrong_label'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(card.whatProvesWrong,
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 10),

                            // 7. Data gaps
                            Text(
                              AppStrings.get(lang, 'gaps_label'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(card.dataGaps,
                                style: const TextStyle(fontSize: 13)),

                            const Divider(height: 20),
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
      ),
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
      ..color = Colors.grey.withOpacity(0.25)
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
        oldDelegate.isDark != isDark;
  }
}
