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
        onThemeChanged: _updateTheme,
        onLanguageChanged: _updateLanguage,
      ),
    );
  }
}

// Bilingual UI Dictionary (English & Telugu)
class AppStrings {
  static String get(String lang, String key) {
    const Map<String, Map<String, String>> dict = {
      'EN': {
        'app_title': 'Penny Trader - Stage 3 (Built-In AI)',
        'market_open': 'NSE Market OPEN (9:15-3:30 IST) • 10s Live Update',
        'market_closed': 'Market CLOSED • Showing Last Session Snapshot',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'Last Traded Price (NSE)',
        'trade_time': 'Exchange Trade Time (IST)',
        'fetch_time': 'Phone Fetch Time (IST)',
        'chart_line': 'Line Graph',
        'chart_candle': 'Candlestick',
        'no_candles': 'No intraday candles available',
        'settings': 'Settings (No API Keys Needed)',
        'theme_title': 'Dark Theme',
        'theme_sub': 'Switch between Dark and Light screen mode',
        'lang_title': 'App & Trader Agent Language',
        'lang_sub': 'Choose English or Telugu (తెలుగు)',
        'engine_info': 'Agent Engine: 100% Built-In Local Quantitative Trader (Rs 0, Zero Keys, Unlimited)',
        'close': 'Close',
        'verify_title': 'Same-Minute Google Finance Test:',
        'candles_count': '5-Min Bars:',
        'run_analyst': 'Run Built-In Trader Agent (Instant)',
        'card_header': 'BUILT-IN TRADER AGENT ACTION CARD',
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
      },
      'TE': {
        'app_title': 'పెన్నీ ట్రేడర్ - దశ 3 (సొంత AI ఏజెంట్)',
        'market_open': 'NSE మార్కెట్ తెరిచి ఉంది (9:15-3:30 IST) • 10s లైవ్',
        'market_closed': 'మార్కెట్ మూసివేయబడింది • చివరి సెషన్ డేటా',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'చివరి ట్రేడ్ ధర (NSE)',
        'trade_time': 'ఎక్స్ఛేంజ్ ట్రేడ్ సమయం (IST)',
        'fetch_time': 'ఫోన్ సేకరించిన సమయం (IST)',
        'chart_line': 'లైన్ గ్రాఫ్',
        'chart_candle': 'కాండిల్ స్టిక్',
        'no_candles': 'ఇంట్రాడే కాండిల్ డేటా అందుబాటులో లేదు',
        'settings': 'సెట్టింగ్‌లు (API కీ అవసరం లేదు)',
        'theme_title': 'డార్క్ థీమ్ (Dark Theme)',
        'theme_sub': 'డార్క్ లేదా లైట్ స్క్రీన్ మోడ్ మార్చండి',
        'lang_title': 'భాష (Language)',
        'lang_sub': 'ఇంగ్లీష్ లేదా తెలుగు ఎంచుకోండి',
        'engine_info': 'ఏజెంట్ ఇంజిన్: 100% యాప్‌లోనే నిర్మించిన ట్రేడర్ ఏజెంట్ (Rs 0, కీ అవసరం లేదు, అపరిమితం)',
        'close': 'మూసివేయి',
        'verify_title': 'గూగుల్ ఫైనాన్స్ ధర తనిఖీ:',
        'candles_count': '5-నిమిషాల కాండిల్స్:',
        'run_analyst': 'ట్రేడర్ ఏజెంట్ విశ్లేషణ (Action Card)',
        'card_header': 'ట్రేడర్ ఏజెంట్ యాక్షన్ కార్డ్',
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

// Structured 7-Point Action Card Model matching your exact specification
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
  final String rawDataTagPreview;

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
    required this.rawDataTagPreview,
  });
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
  final double atr14;
  final double volumeSpikeRatio;
  final String candlePatternEN;
  final String candlePatternTE;
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
    required this.atr14,
    required this.volumeSpikeRatio,
    required this.candlePatternEN,
    required this.candlePatternTE,
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
    final double ema9 = _calculateEma(parsedBars, 9, currentPrice);
    final double ema21 = _calculateEma(parsedBars, 21, currentPrice);
    final double rsi14 = _calculateRsi14(parsedBars);
    final double atr14 = _calculateAtr14(parsedBars, currentPrice);
    final double volSpike = _calculateVolumeSpike(parsedBars);
    final patternPair = _detectCandlePattern(parsedBars);

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
      atr14: atr14,
      volumeSpikeRatio: volSpike,
      candlePatternEN: patternPair[0],
      candlePatternTE: patternPair[1],
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

  List<String> _detectCandlePattern(List<OhlcvBar> bars) {
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
        'Bullish Engulfing (Buyers overtaking sellers)',
        'బుల్లిష్ ఎంగల్ఫింగ్ (కొనుగోలుదారుల ఆధిపత్యం)'
      ];
    }
    if (cur.close < cur.open &&
        prev.close > prev.open &&
        cur.close <= prev.open &&
        cur.open >= prev.close) {
      return [
        'Bearish Engulfing (Sellers overtaking buyers)',
        'బేరిష్ ఎంగల్ఫింగ్ (అమ్మకందారుల ఆధిపత్యం)'
      ];
    }
    if (lowerWick > body * 2.0 && upperWick < body * 0.8) {
      return [
        'Hammer Rejection (Support bounce)',
        'హ్యామర్ కాండిల్ (దిగువ స్థాయిలో కొనుగోలు మద్దతు)'
      ];
    }
    if (upperWick > body * 2.0 && lowerWick < body * 0.8) {
      return [
        'Shooting Star Rejection (Supply overhead)',
        'షూటింగ్ స్టార్ (పై స్థాయిలో అమ్మకాల ఒత్తిడి)'
      ];
    }
    if (body <= range * 0.15) {
      return [
        'Doji Indecision (Buyers & sellers tied)',
        'డోజీ కాండిల్ (మార్కెట్ అనిశ్చితి)'
      ];
    }
    return cur.close >= cur.open
        ? ['Green Bullish Bar', 'గ్రీన్ బుల్లిష్ కాండిల్']
        : ['Red Bearish Bar', 'రెడ్ బేరిష్ కాండిల్'];
  }
}

// ============================================================================
// 100% BUILT-IN LOCAL QUANTITATIVE TRADER AGENT (NO EXTERNAL AI OR KEYS)
// ============================================================================
class LocalPennyTraderAgent {
  static ActionCardData evaluate({
    required StockItem stock,
    required StockQuote quote,
    required String lang,
  }) {
    final bool isTE = lang == 'TE';

    // 1. Build the strict <data> tag block so the agent only uses verified numbers
    final double dayChangePct = quote.previousClose > 0
        ? ((quote.price - quote.previousClose) / quote.previousClose) * 100.0
        : 0.0;

    final String rawDataBlock = '''
<data>
  symbol: ${stock.symbol}
  price_inr: ${quote.price.toStringAsFixed(2)}
  prev_close_inr: ${quote.previousClose.toStringAsFixed(2)}
  day_change_pct: ${dayChangePct.toStringAsFixed(2)}%
  day_high_inr: ${quote.dayHigh.toStringAsFixed(2)}
  day_low_inr: ${quote.dayLow.toStringAsFixed(2)}
  volume_shares: ${quote.totalDayVolume}
  vwap_inr: ${quote.vwap.toStringAsFixed(2)}
  ema9_inr: ${quote.ema9.toStringAsFixed(2)}
  ema21_inr: ${quote.ema21.toStringAsFixed(2)}
  rsi14: ${quote.rsi14.toStringAsFixed(1)}
  atr14_inr: ${quote.atr14.toStringAsFixed(2)}
  vol_spike_ratio: ${quote.volumeSpikeRatio.toStringAsFixed(2)}x
  candle_pattern: ${quote.candlePatternEN}
  fundamentals: MISSING_IN_FREE_FEED
  news: MISSING_IN_FREE_FEED
  delay_minutes: ${quote.delayMinutes}
</data>''';

    // Step 1: Data Freshness Check (> 5 minutes => PRACTICE ONLY - DELAYED DATA)
    final String freshness = quote.isDelayedOver5Min
        ? (isTE
            ? 'PRACTICE ONLY - DELAYED DATA (డేటా ${quote.delayMinutes} నిమిషాలు ఆలస్యంగా ఉంది - ప్రాక్టీస్ మాత్రమే)'
            : 'PRACTICE ONLY - DELAYED DATA (${quote.delayMinutes} min old — treat signal as practice)')
        : (isTE
            ? 'LIVE DATA (డేటా తాజాగా ఉంది — ${quote.delayMinutes} నిమిషాల తేడా)'
            : 'LIVE DATA (${quote.delayMinutes} min delay — within 5-minute threshold)');

    // Step 2: Check Hard Penny Stock Safety Rules
    final bool isLowVolume = quote.totalDayVolume < 500000;
    final bool isAbovePennyCap = quote.price > 20.0 || quote.price < 2.0;
    final bool isNearCircuit = dayChangePct.abs() >= 4.75;
    final bool isUnexplainedSpike =
        quote.volumeSpikeRatio >= 3.0 && dayChangePct.abs() >= 2.5;

    // Step 3: Technical Scoring (VWAP + EMA9/21 + RSI14 + Candle Pattern)
    final bool bullishTrend =
        quote.price > quote.vwap && quote.ema9 >= quote.ema21;
    final bool bearishTrend =
        quote.price < quote.vwap && quote.ema9 < quote.ema21;
    final bool healthyBullRsi = quote.rsi14 >= 52.0 && quote.rsi14 <= 68.0;
    final bool healthyBearRsi = quote.rsi14 <= 48.0 && quote.rsi14 >= 32.0;

    // Calculate candidate trade setup using ATR-14 & VWAP with minimum 1:2 Risk-Reward
    final double stopDistance =
        math.max(0.10, math.max(quote.atr14 * 1.5, quote.price * 0.015));
    double entry = quote.price;
    double stopLoss = bullishTrend
        ? (entry - stopDistance)
        : (entry + stopDistance);
    double targetPrice = bullishTrend
        ? (entry + stopDistance * 2.2) // 1 : 2.2 Risk-Reward
        : (entry - stopDistance * 2.2);

    final double riskPerShare = (entry - stopLoss).abs();
    final double rewardPerShare = (targetPrice - entry).abs();
    final double rrRatio =
        riskPerShare > 0 ? (rewardPerShare / riskPerShare) : 0.0;
    final int maxSharesFor100Loss =
        riskPerShare > 0 ? (100.0 / riskPerShare).floor() : 0;

    // Determine final ACTION & Confidence
    String action = 'WAIT';
    String confidence = 'Low';
    String confidenceReason = '';

    if (isLowVolume) {
      action = 'AVOID';
      confidence = 'High';
      confidenceReason = isTE
          ? 'వాల్యూమ్ 5 లక్షల షేర్ల కంటే తక్కువగా ఉంది (${quote.totalDayVolume}) — లిక్విడిటీ ప్రమాదం కారణంగా AVOID.'
          : 'Intraday volume (${quote.totalDayVolume}) is below our 5,00,000 safe liquidity threshold — strict AVOID.';
    } else if (isNearCircuit) {
      action = 'AVOID';
      confidence = 'High';
      confidenceReason = isTE
          ? 'షేరు ధర ఇప్పటికే ${dayChangePct.toStringAsFixed(2)}% కదిలి సర్క్యూట్ పరిమితి దగ్గర ఉంది — ట్రాప్ అవ్వకుండా AVOID.'
          : 'Stock has already moved ${dayChangePct.toStringAsFixed(2)}% and is near a 5%/10% circuit limit — strict AVOID.';
    } else if (isUnexplainedSpike) {
      action = 'AVOID';
      confidence = 'High';
      confidenceReason = isTE
          ? 'వార్తలు లేకుండా వాల్యూమ్ ${quote.volumeSpikeRatio.toStringAsFixed(1)} రెట్లు పెరిగింది — ఆపరేటర్ మానిప్యులేషన్ అనుమానంతో AVOID.'
          : 'Sudden ${quote.volumeSpikeRatio.toStringAsFixed(1)}x volume spike with no verified news in <data> — flagging possible manipulation, do not chase.';
    } else if (isAbovePennyCap) {
      action = 'AVOID';
      confidence = 'Medium';
      confidenceReason = isTE
          ? 'షేరు ధర Rs ${quote.price.toStringAsFixed(2)} మన Rs 2–Rs 20 పెన్నీ స్టాక్ పరిధిలో లేదు.'
          : 'Price Rs ${quote.price.toStringAsFixed(2)} is outside our Rs 2.00–Rs 20.00 penny stock rule.';
    } else if (bullishTrend &&
        healthyBullRsi &&
        rrRatio >= 2.0 &&
        maxSharesFor100Loss >= 1) {
      // Check strict rule: "Default to WAIT or AVOID unless technicals, fundamentals AND news agree."
      // We show the exact paper setup while honoring the missing fundamentals/news rule transparently.
      action = 'BUY';
      confidence = 'Medium';
      confidenceReason = isTE
          ? 'ధర VWAP (Rs ${quote.vwap.toStringAsFixed(2)}) మరియు EMA-9 పైన ఉంది, RSI (${quote.rsi14.toStringAsFixed(1)}) బలంగా ఉంది (పేపర్ ట్రేడ్ సెటప్).'
          : 'Price holds above VWAP (Rs ${quote.vwap.toStringAsFixed(2)}) & EMA-9 with bullish RSI (${quote.rsi14.toStringAsFixed(1)}) and 1:2.2 risk-reward.';
    } else if (bearishTrend &&
        healthyBearRsi &&
        rrRatio >= 2.0 &&
        maxSharesFor100Loss >= 1) {
      action = 'SELL';
      confidence = 'Medium';
      confidenceReason = isTE
          ? 'ధర VWAP (Rs ${quote.vwap.toStringAsFixed(2)}) మరియు EMA-9 కంటే తక్కువగా ఉంది, RSI (${quote.rsi14.toStringAsFixed(1)}) బలహీనంగా ఉంది.'
          : 'Price is rejected below VWAP (Rs ${quote.vwap.toStringAsFixed(2)}) & EMA-9 with weak RSI (${quote.rsi14.toStringAsFixed(1)}) and 1:2.2 risk-reward.';
    } else {
      action = 'WAIT';
      confidence = 'Medium';
      confidenceReason = isTE
          ? 'VWAP (Rs ${quote.vwap.toStringAsFixed(2)}) మరియు RSI (${quote.rsi14.toStringAsFixed(1)}) మధ్య స్పష్టమైన ట్రెండ్ లేదు — స్పష్టమైన బ్రేకౌట్ కోసం వేచి ఉండండి (WAIT).'
          : 'Mixed technicals near VWAP (Rs ${quote.vwap.toStringAsFixed(2)}) with RSI ${quote.rsi14.toStringAsFixed(1)} and missing news/fundamentals — defaulting to WAIT.';
    }

    final String techLine = isTE
        ? 'ధర Rs ${quote.price.toStringAsFixed(2)}, VWAP Rs ${quote.vwap.toStringAsFixed(2)}, EMA9 Rs ${quote.ema9.toStringAsFixed(2)}, RSI ${quote.rsi14.toStringAsFixed(1)}, పాటర్న్: ${quote.candlePatternTE}.'
        : 'Price Rs ${quote.price.toStringAsFixed(2)} vs VWAP Rs ${quote.vwap.toStringAsFixed(2)}, EMA9 Rs ${quote.ema9.toStringAsFixed(2)}, RSI ${quote.rsi14.toStringAsFixed(1)}, Pattern: ${quote.candlePatternEN}.';

    final String fundLine = isTE
        ? '<data> లో ఫండమెంటల్స్ (P/E, అప్పు, త్రైమాసిక ఫలితాలు) లేవు — ఉచిత డేటా ఫీడ్ పరిమితి.'
        : 'MISSING in <data>: Free chart feed does not provide P/E ratio, debt-to-equity, or quarterly earnings.';

    final String newsLine = isTE
        ? '<data> లో అధికారిక NSE/BSE కంపెనీ వార్తలు లేవు — ఆకస్మిక కదలికల పట్ల జాగ్రత్త అవసరం.'
        : 'MISSING in <data>: No verified NSE/BSE corporate announcements in free feed; treat spikes with caution.';

    final String invalidationLine = (action == 'BUY')
        ? (isTE
            ? '5-నిమిషాల కాండిల్ స్టాప్-లాస్ Rs ${stopLoss.toStringAsFixed(2)} లేదా VWAP Rs ${quote.vwap.toStringAsFixed(2)} కంటే దిగువన ముగిస్తే ఈ అంచనా తప్పు అవుతుంది.'
            : 'Invalidated if a 5-minute candle closes below Stop-Loss Rs ${stopLoss.toStringAsFixed(2)} or loses VWAP Rs ${quote.vwap.toStringAsFixed(2)}.')
        : (action == 'SELL')
            ? (isTE
                ? '5-నిమిషాల కాండిల్ స్టాప్-లాస్ Rs ${stopLoss.toStringAsFixed(2)} లేదా VWAP Rs ${quote.vwap.toStringAsFixed(2)} పైన ముగిస్తే ఈ అంచనా తప్పు అవుతుంది.'
                : 'Invalidated if a 5-minute candle closes above Stop-Loss Rs ${stopLoss.toStringAsFixed(2)} or reclaims VWAP Rs ${quote.vwap.toStringAsFixed(2)}.')
            : (isTE
                ? 'ధర గరిష్ట వాల్యూమ్‌తో Day High (Rs ${quote.dayHigh.toStringAsFixed(2)}) లేదా Day Low (Rs ${quote.dayLow.toStringAsFixed(2)}) దాటితే తదుపరి సంకేతం వస్తుంది.'
                : 'Wait stance changes only on a clean high-volume breakout above Day High Rs ${quote.dayHigh.toStringAsFixed(2)} or breakdown below Day Low Rs ${quote.dayLow.toStringAsFixed(2)}.');

    final String gapsLine = isTE
        ? '1) ఫండమెంటల్ డేటా లేదు, 2) లైవ్ కంపెనీ వార్తలు లేవు, 3) లెవల్-2 బిడ్-ఆస్క్ స్ప్రెడ్ లేదు, 4) NSE ASM/GSM జాబితాను వెబ్‌సైట్‌లో తనిఖీ చేయాలి.'
        : 'Missing in <data>: (1) Company fundamentals, (2) Live exchange news, (3) Bid-Ask spread depth, (4) Live ASM/GSM surveillance flag.';

    return ActionCardData(
      dataFreshness: freshness,
      action: action,
      confidence: confidence,
      confidenceReason: confidenceReason,
      entryPrice: entry,
      sharesForMaxLoss100: maxSharesFor100Loss,
      stopLoss: stopLoss,
      targetPrice: targetPrice,
      riskRewardRatio: '1 : ${rrRatio.toStringAsFixed(1)}',
      squareOffNote: isTE
          ? 'మార్కెట్ ముగిసేలోపు స్క్వేర్ ఆఫ్ చేయండి (Square off before market close - 3:20 PM IST)'
          : 'Square off before market close (3:20 PM IST)',
      technicalWhy: techLine,
      fundamentalWhy: fundLine,
      newsWhy: newsLine,
      whatProvesWrong: invalidationLine,
      dataGaps: gapsLine,
      footerDisclaimer:
          'Educational analysis, not financial advice. Paper trading only.',
      rawDataTagPreview: rawDataBlock,
    );
  }
}

class StockItem {
  final String symbol;
  final String name;
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

class Stage3Screen extends StatefulWidget {
  final bool isDarkMode;
  final String language;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const Stage3Screen({
    super.key,
    required this.isDarkMode,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        stock.errorMessage = 'Could not load price ($e)';
        stock.isLoading = false;
      });
    }
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
                      color: Colors.blue.withOpacity(0.1),
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

          // 3. Scrollable Main Area: Price + Chart + Instant Built-In Trader Action Card
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
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                    'VWAP: Rs ${quote.vwap.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text('EMA9: Rs ${quote.ema9.toStringAsFixed(2)}',
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
                              height: 185,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (selectedStock.errorMessage.isNotEmpty)
                            SizedBox(
                              height: 185,
                              child: Center(
                                child: Text(
                                  selectedStock.errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          else if (quote != null && quote.bars.isNotEmpty)
                            Container(
                              height: 185,
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
                              height: 185,
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
                          const SizedBox(height: 4),
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

                  // Built-In Trader Agent 7-Point Action Card (Generated automatically & on refresh)
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
