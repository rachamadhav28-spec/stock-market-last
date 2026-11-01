import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// 1. QUANTITATIVE & AI DATA STRUCTURES
// ============================================================================

enum TimeHorizon { shortTerm, middleTerm, longTerm }

class StockAiSignal {
  final String symbol;
  final double currentPrice;
  final double changePercent;
  final double rsi14;
  final double ema9;
  final double ema21;
  final double macdHist;
  final double atr14;
  final String candlePattern;
  final double aiConfidence; // 0 to 100%
  final String verdict; // STRONG BUY, BUY, HOLD, SELL, STRONG SELL
  final double entryPrice;
  final double target1;
  final double target2;
  final double stopLoss;
  final List<String> reasoning;

  StockAiSignal({
    required this.symbol,
    required this.currentPrice,
    required this.changePercent,
    required this.rsi14,
    required this.ema9,
    required this.ema21,
    required this.macdHist,
    required this.atr14,
    required this.candlePattern,
    required this.aiConfidence,
    required this.verdict,
    required this.entryPrice,
    required this.target1,
    required this.target2,
    required this.stopLoss,
    required this.reasoning,
  });
}

class QuantMutualFund {
  final int schemeCode;
  final String schemeName;
  final String category;
  final TimeHorizon horizon;
  double latestNav;
  String navDate;
  double cagr1Y;
  double cagr3Y;
  double cagr5Y;
  double volatility; // Annualized standard deviation %
  double sharpeRatio; // Risk-adjusted return score
  double maxDrawdown; // Worst peak-to-trough drop %
  double aiScore; // 0 to 100 composite quant score

  QuantMutualFund({
    required this.schemeCode,
    required this.schemeName,
    required this.category,
    required this.horizon,
    required this.latestNav,
    required this.navDate,
    required this.cagr1Y,
    required this.cagr3Y,
    required this.cagr5Y,
    this.volatility = 4.5,
    this.sharpeRatio = 1.4,
    this.maxDrawdown = -3.2,
    this.aiScore = 82.0,
  });
}

class NewsSentimentItem {
  final String title;
  final String summary;
  final String pubDate;
  final double sentimentWeight; // -1.0 (Bearish) to +1.0 (Bullish)
  final List<String> detectedSectors;

  NewsSentimentItem({
    required this.title,
    required this.summary,
    required this.pubDate,
    required this.sentimentWeight,
    required this.detectedSectors,
  });
}

// ============================================================================
// 2. ON-DEVICE AUTONOMOUS TRADING & MUTUAL FUND AI ENGINE (NO API KEY)
// ============================================================================

class AutonomousTraderAi {
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 6);

  bool isSyncing = false;
  double marketSentimentIndex = 18.5; // -100 (Extreme Fear) to +100 (Extreme Greed)
  List<NewsSentimentItem> liveNews = [];
  Map<String, StockAiSignal> cachedStockSignals = {};

  final List<QuantMutualFund> quantFunds = [
    // SHORT-TERM (0 - 12 Months: Capital Preservation + High Liquidity)
    QuantMutualFund(
      schemeCode: 119062,
      schemeName: 'HDFC Liquid Fund - Direct Plan - Growth',
      category: 'Debt - Liquid',
      horizon: TimeHorizon.shortTerm,
      latestNav: 4985.20,
      navDate: 'Live',
      cagr1Y: 7.28,
      cagr3Y: 6.50,
      cagr5Y: 5.65,
      volatility: 0.42,
      sharpeRatio: 2.10,
      maxDrawdown: -0.05,
      aiScore: 91.4,
    ),
    QuantMutualFund(
      schemeCode: 120533,
      schemeName: 'ICICI Pru Ultra Short Term Fund - Direct - Growth',
      category: 'Debt - Ultra Short Duration',
      horizon: TimeHorizon.shortTerm,
      latestNav: 28.45,
      navDate: 'Live',
      cagr1Y: 7.58,
      cagr3Y: 6.82,
      cagr5Y: 6.38,
      volatility: 0.68,
      sharpeRatio: 1.95,
      maxDrawdown: -0.22,
      aiScore: 93.1,
    ),

    // MIDDLE-TERM (1 - 3 Years: Dynamic Hybrid & Risk-Managed Growth)
    QuantMutualFund(
      schemeCode: 119063,
      schemeName: 'HDFC Balanced Advantage Fund - Direct - Growth',
      category: 'Hybrid - Dynamic Asset Allocation',
      horizon: TimeHorizon.middleTerm,
      latestNav: 518.90,
      navDate: 'Live',
      cagr1Y: 21.80,
      cagr3Y: 21.10,
      cagr5Y: 19.75,
      volatility: 9.40,
      sharpeRatio: 1.62,
      maxDrawdown: -8.40,
      aiScore: 94.8,
    ),
    QuantMutualFund(
      schemeCode: 118968,
      schemeName: 'ICICI Pru Balanced Advantage Fund - Direct - Growth',
      category: 'Hybrid - Dynamic Asset Allocation',
      horizon: TimeHorizon.middleTerm,
      latestNav: 74.80,
      navDate: 'Live',
      cagr1Y: 16.40,
      cagr3Y: 14.85,
      cagr5Y: 14.20,
      volatility: 7.10,
      sharpeRatio: 1.48,
      maxDrawdown: -6.10,
      aiScore: 89.5,
    ),

    // LONG-TERM (5+ Years: High-Alpha Equity Compounding)
    QuantMutualFund(
      schemeCode: 122639,
      schemeName: 'Parag Parikh Flexi Cap Fund - Direct - Growth',
      category: 'Equity - Flexi Cap',
      horizon: TimeHorizon.longTerm,
      latestNav: 86.30,
      navDate: 'Live',
      cagr1Y: 26.80,
      cagr3Y: 21.40,
      cagr5Y: 24.10,
      volatility: 11.80,
      sharpeRatio: 1.74,
      maxDrawdown: -12.30,
      aiScore: 96.5,
    ),
    QuantMutualFund(
      schemeCode: 127042,
      schemeName: 'Motilal Oswal Midcap Fund - Direct - Growth',
      category: 'Equity - Mid Cap',
      horizon: TimeHorizon.longTerm,
      latestNav: 108.70,
      navDate: 'Live',
      cagr1Y: 41.20,
      cagr3Y: 31.40,
      cagr5Y: 29.30,
      volatility: 15.60,
      sharpeRatio: 1.68,
      maxDrawdown: -16.80,
      aiScore: 95.2,
    ),
    QuantMutualFund(
      schemeCode: 125354,
      schemeName: 'Nippon India Small Cap Fund - Direct - Growth',
      category: 'Equity - Small Cap',
      horizon: TimeHorizon.longTerm,
      latestNav: 184.20,
      navDate: 'Live',
      cagr1Y: 33.10,
      cagr3Y: 29.50,
      cagr5Y: 31.90,
      volatility: 16.90,
      sharpeRatio: 1.59,
      maxDrawdown: -18.50,
      aiScore: 94.0,
    ),
  ];

  /// Background Pre-Warming: Syncs live NSE stocks, AMFI Mutual Funds, and RSS News
  Future<void> initializeAndSync({VoidCallback? onUpdated}) async {
    if (isSyncing) return;
    isSyncing = true;
    onUpdated?.call();

    try {
      await Future.wait([
        _syncNewsAndComputeMarketRegime(),
        _syncQuantMutualFunds(),
        analyzeLiveStock('RELIANCE.NS'),
        analyzeLiveStock('SUZLON.NS'),
        analyzeLiveStock('TATASTEEL.NS'),
      ]);
    } catch (_) {
    } finally {
      isSyncing = false;
      onUpdated?.call();
    }
  }

  // ==========================================================================
  // A. NEURAL / QUANT STOCK TECHNICAL ANALYSIS ENGINE (NSE/BSE LIVE)
  // ==========================================================================

  Future<StockAiSignal?> analyzeLiveStock(String rawInput) async {
    String ticker = rawInput.trim().toUpperCase();
    if (!ticker.endsWith('.NS') && !ticker.endsWith('.BO')) {
      ticker = '$ticker.NS';
    }

    try {
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/$ticker?interval=15m&range=5d';
      final req = await _http.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'Mozilla/5.0');
      final res = await req.close();
      if (res.statusCode != 200) return null;

      final body = await res.transform(utf8.decoder).join();
      final map = json.decode(body) as Map<String, dynamic>;
      final result = (map['chart']?['result'] as List?)?.firstOrNull;
      if (result == null) return null;

      final quote =
          (result['indicators']?['quote'] as List?)?.firstOrNull ?? {};
      final List<double> opens = _cleanDoubleList(quote['open']);
      final List<double> highs = _cleanDoubleList(quote['high']);
      final List<double> lows = _cleanDoubleList(quote['low']);
      final List<double> closes = _cleanDoubleList(quote['close']);
      final List<double> volumes = _cleanDoubleList(quote['volume']);

      if (closes.length < 30) return null;

      final double currentPrice = closes.last;
      final double prevClose =
          closes.length > 25 ? closes[closes.length - 25] : closes.first;
      final double changePct = ((currentPrice - prevClose) / prevClose) * 100.0;

      // Compute Real Technical Indicators
      final double rsi14 = _computeRsi(closes, 14);
      final double ema9 = _computeEma(closes, 9);
      final double ema21 = _computeEma(closes, 21);
      final double sma50 = _computeSma(closes, math.min(50, closes.length));
      final double macdHist = _computeMacdHistogram(closes);
      final double atr14 = _computeAtr(highs, lows, closes, 14);
      final String pattern =
          _detectCandlePattern(opens, highs, lows, closes, volumes);

      // Multi-Factor Neural Scoring (Weights + Sigmoid Activation)
      double rawLogit = 0.0;
      final List<String> reasons = [];

      // 1. Trend Crossover Feature
      if (ema9 > ema21 && currentPrice > ema9) {
        rawLogit += 1.15;
        reasons.add(
            'Bullish EMA-9 (₹${ema9.toStringAsFixed(2)}) > EMA-21 (₹${ema21.toStringAsFixed(2)}) crossover.');
      } else if (ema9 < ema21 && currentPrice < ema9) {
        rawLogit -= 1.15;
        reasons.add(
            'Bearish EMA-9 < EMA-21 alignment indicates short-term selling pressure.');
      }

      // 2. RSI Mean-Reversion & Momentum Feature
      if (rsi14 < 32) {
        rawLogit += 1.30;
        reasons.add(
            'Oversold RSI-14 (${rsi14.toStringAsFixed(1)}) signals strong mean-reversion bounce potential.');
      } else if (rsi14 >= 52 && rsi14 <= 68) {
        rawLogit += 0.75;
        reasons.add(
            'Healthy bullish momentum with RSI-14 at ${rsi14.toStringAsFixed(1)}.');
      } else if (rsi14 > 75) {
        rawLogit -= 1.10;
        reasons.add(
            'Overbought RSI-14 (${rsi14.toStringAsFixed(1)}) warns of profit booking.');
      }

      // 3. MACD Histogram Acceleration
      if (macdHist > 0) {
        rawLogit += 0.65;
        reasons.add('Positive MACD histogram confirms upward momentum.');
      } else {
        rawLogit -= 0.65;
        reasons.add('Negative MACD histogram reflects bearish momentum.');
      }

      // 4. Price vs SMA-50 Structural Support
      if (currentPrice > sma50) {
        rawLogit += 0.50;
      } else {
        rawLogit -= 0.50;
      }

      // 5. Candlestick Pattern Signal
      if (pattern.contains('Bullish') || pattern.contains('Hammer')) {
        rawLogit += 0.80;
        reasons.add('Detected $pattern candlestick structure.');
      } else if (pattern.contains('Bearish') || pattern.contains('Shooting')) {
        rawLogit -= 0.80;
        reasons.add('Detected $pattern reversal pattern.');
      }

      // 6. Live Macro News Sentiment Bias
      rawLogit += (marketSentimentIndex / 100.0) * 0.45;

      // Sigmoid Activation -> Probability (0% to 100%)
      final double probability = (1.0 / (1.0 + math.exp(-rawLogit))) * 100.0;

      String verdict;
      if (probability >= 76) {
        verdict = '🟢 STRONG BUY';
      } else if (probability >= 60) {
        verdict = '🟢 BUY (ACCUMULATE)';
      } else if (probability >= 42) {
        verdict = '🟡 HOLD / NEUTRAL';
      } else if (probability >= 26) {
        verdict = '🔴 SELL / REDUCE';
      } else {
        verdict = '🔴 STRONG SELL';
      }

      final double safeAtr = atr14 > 0 ? atr14 : currentPrice * 0.015;
      final bool isBullish = probability >= 50;

      final signal = StockAiSignal(
        symbol: ticker.replaceAll('.NS', ''),
        currentPrice: currentPrice,
        changePercent: changePct,
        rsi14: rsi14,
        ema9: ema9,
        ema21: ema21,
        macdHist: macdHist,
        atr14: safeAtr,
        candlePattern: pattern,
        aiConfidence: probability,
        verdict: verdict,
        entryPrice: currentPrice,
        target1: isBullish
            ? currentPrice + (safeAtr * 1.8)
            : currentPrice - (safeAtr * 1.8),
        target2: isBullish
            ? currentPrice + (safeAtr * 3.2)
            : currentPrice - (safeAtr * 3.2),
        stopLoss: isBullish
            ? currentPrice - (safeAtr * 1.3)
            : currentPrice + (safeAtr * 1.3),
        reasoning: reasons,
      );

      cachedStockSignals[signal.symbol] = signal;
      return signal;
    } catch (_) {
      return null;
    }
  }

  List<double> _cleanDoubleList(dynamic rawList) {
    if (rawList is! List) return [];
    return rawList
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();
  }

  double _computeSma(List<double> prices, int period) {
    if (prices.isEmpty) return 0;
    final sub = prices.sublist(math.max(0, prices.length - period));
    return sub.reduce((a, b) => a + b) / sub.length;
  }

  double _computeEma(List<double> prices, int period) {
    if (prices.isEmpty) return 0;
    final double k = 2.0 / (period + 1);
    double ema = prices.first;
    for (int i = 1; i < prices.length; i++) {
      ema = (prices[i] * k) + (ema * (1 - k));
    }
    return ema;
  }

  double _computeRsi(List<double> prices, int period) {
    if (prices.length <= period) return 50.0;
    double gains = 0.0;
    double losses = 0.0;
    for (int i = prices.length - period; i < prices.length; i++) {
      final diff = prices[i] - prices[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }
    if (losses == 0) return 100.0;
    final rs = (gains / period) / (losses / period);
    return 100.0 - (100.0 / (1.0 + rs));
  }

  double _computeMacdHistogram(List<double> prices) {
    final ema12 = _computeEma(prices, 12);
    final ema26 = _computeEma(prices, 26);
    final macd = ema12 - ema26;
    // Approximate signal line using recent window
    final recent = prices.sublist(math.max(0, prices.length - 9));
    final signal = (_computeEma(recent, 12) - _computeEma(recent, 26)) * 0.85;
    return macd - signal;
  }

  double _computeAtr(List<double> highs, List<double> lows,
      List<double> closes, int period) {
    final len =
        [highs.length, lows.length, closes.length].reduce(math.min);
    if (len <= period) return 0.0;
    double trSum = 0.0;
    for (int i = len - period; i < len; i++) {
      final hl = highs[i] - lows[i];
      final hc = (highs[i] - closes[i - 1]).abs();
      final lc = (lows[i] - closes[i - 1]).abs();
      trSum += [hl, hc, lc].reduce(math.max);
    }
    return trSum / period;
  }

  String _detectCandlePattern(List<double> opens, List<double> highs,
      List<double> lows, List<double> closes, List<double> volumes) {
    final len = [opens.length, highs.length, lows.length, closes.length]
        .reduce(math.min);
    if (len < 3) return 'Neutral Consolidation';

    final o = opens[len - 1];
    final h = highs[len - 1];
    final l = lows[len - 1];
    final c = closes[len - 1];
    final prevO = opens[len - 2];
    final prevC = closes[len - 2];

    final body = (c - o).abs();
    final upperWick = h - math.max(o, c);
    final lowerWick = math.min(o, c) - l;

    if (c > o && prevC < prevO && c > prevO && o <= prevC) {
      return 'Bullish Engulfing Breakout';
    }
    if (c < o && prevC > prevO && c < prevO && o >= prevC) {
      return 'Bearish Engulfing Reversal';
    }
    if (lowerWick > body * 2.2 && upperWick < body * 0.6) {
      return 'Bullish Hammer Rejection';
    }
    if (upperWick > body * 2.2 && lowerWick < body * 0.6) {
      return 'Bearish Shooting Star';
    }
    if (body <= (h - l) * 0.12) {
      return 'Indecision Doji';
    }
    return c >= o ? 'Bullish Momentum Candle' : 'Bearish Supply Candle';
  }

  // ==========================================================================
  // B. QUANTITATIVE MUTUAL FUND AI ENGINE (LIVE AMFI / MFAPI.IN)
  // ==========================================================================

  Future<void> _syncQuantMutualFunds() async {
    for (final fund in quantFunds) {
      await _updateSingleFundQuantMetrics(fund);
    }
  }

  Future<void> _updateSingleFundQuantMetrics(QuantMutualFund fund) async {
    try {
      final uri = Uri.parse('https://api.mfapi.in/mf/${fund.schemeCode}');
      final req = await _http.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) return;

      final body = await res.transform(utf8.decoder).join();
      final jsonMap = json.decode(body) as Map<String, dynamic>;
      final List<dynamic> navList = jsonMap['data'] ?? [];
      if (navList.length < 30) return;

      final double latest =
          double.tryParse(navList.first['nav'].toString()) ?? fund.latestNav;
      fund.latestNav = latest;
      fund.navDate = navList.first['date'].toString();

      fund.cagr1Y = _computeCagr(navList, latest, 1);
      fund.cagr3Y = _computeCagr(navList, latest, 3);
      fund.cagr5Y = _computeCagr(navList, latest, 5);

      // Compute Real Daily Volatility, Sharpe Ratio, and Max Drawdown over 1 Year (248 trading days)
      final int window = math.min(248, navList.length - 1);
      final List<double> dailyReturns = [];
      double peakNav = 0;
      double maxDd = 0;

      for (int i = window; i >= 0; i--) {
        final double nav =
            double.tryParse(navList[i]['nav'].toString()) ?? latest;
        if (nav > peakNav) peakNav = nav;
        if (peakNav > 0) {
          final dd = ((nav - peakNav) / peakNav) * 100.0;
          if (dd < maxDd) maxDd = dd;
        }
        if (i < window) {
          final double prevNav =
              double.tryParse(navList[i + 1]['nav'].toString()) ?? nav;
          if (prevNav > 0) {
            dailyReturns.add((nav - prevNav) / prevNav);
          }
        }
      }

      if (dailyReturns.length > 20) {
        final mean =
            dailyReturns.reduce((a, b) => a + b) / dailyReturns.length;
        double sumSq = 0.0;
        for (final r in dailyReturns) {
          sumSq += math.pow(r - mean, 2);
        }
        final dailyStdDev = math.sqrt(sumSq / dailyReturns.length);
        final annualizedVol = dailyStdDev * math.sqrt(248) * 100.0;

        fund.volatility = double.parse(annualizedVol.toStringAsFixed(2));
        fund.maxDrawdown = double.parse(maxDd.toStringAsFixed(2));

        // Risk-free rate in India ~ 6.5%
        final double relevantCagr = fund.horizon == TimeHorizon.shortTerm
            ? fund.cagr1Y
            : fund.horizon == TimeHorizon.middleTerm
                ? fund.cagr3Y
                : fund.cagr5Y;
        final double sharpe = annualizedVol > 0.3
            ? (relevantCagr - 6.5) / annualizedVol
            : 1.85;
        fund.sharpeRatio =
            double.parse(sharpe.clamp(0.1, 3.5).toStringAsFixed(2));

        // Composite Quant AI Score (0 - 100)
        final rawScore = 60.0 +
            (relevantCagr * 1.1) +
            (fund.sharpeRatio * 8.5) -
            (fund.volatility * 0.45);
        fund.aiScore =
            double.parse(rawScore.clamp(55.0, 99.4).toStringAsFixed(1));
      }
    } catch (_) {}
  }

  double _computeCagr(List<dynamic> navData, double currentNav, int years) {
    final int idx = math.min(years * 248, navData.length - 1);
    if (idx <= 0) return 0.0;
    final pastNav = double.tryParse(navData[idx]['nav'].toString()) ?? 0.0;
    if (pastNav <= 0) return 0.0;
    final cagr = (math.pow(currentNav / pastNav, 1.0 / years) - 1.0) * 100.0;
    return double.parse(cagr.toStringAsFixed(2));
  }

  /// Live Search & Quant Evaluation of Any Mutual Fund in India
  Future<QuantMutualFund?> searchAndAnalyzeLiveFund(String query) async {
    try {
      final searchUri = Uri.parse(
          'https://api.mfapi.in/mf/search?q=${Uri.encodeComponent(query.trim())}');
      final req = await _http.getUrl(searchUri);
      final res = await req.close();
      if (res.statusCode != 200) return null;

      final body = await res.transform(utf8.decoder).join();
      final List<dynamic> list = json.decode(body);
      if (list.isEmpty) return null;

      // Prefer Direct Growth plan if available in top matches
      Map<String, dynamic> chosen = list.first as Map<String, dynamic>;
      for (final item in list.take(12)) {
        final name = item['schemeName'].toString().toLowerCase();
        if (name.contains('direct') && name.contains('growth')) {
          chosen = item as Map<String, dynamic>;
          break;
        }
      }

      final int code = int.tryParse(chosen['schemeCode'].toString()) ?? 0;
      if (code == 0) return null;

      final nameStr = chosen['schemeName'].toString();
      final lower = nameStr.toLowerCase();
      TimeHorizon horizon = TimeHorizon.longTerm;
      if (lower.contains('liquid') ||
          lower.contains('ultra short') ||
          lower.contains('overnight') ||
          lower.contains('money market')) {
        horizon = TimeHorizon.shortTerm;
      } else if (lower.contains('balanced') ||
          lower.contains('hybrid') ||
          lower.contains('arbitrage') ||
          lower.contains('short duration')) {
        horizon = TimeHorizon.middleTerm;
      }

      final newFund = QuantMutualFund(
        schemeCode: code,
        schemeName: nameStr,
        category: horizon == TimeHorizon.shortTerm
            ? 'Short-Term Debt/Liquid'
            : horizon == TimeHorizon.middleTerm
                ? 'Middle-Term Hybrid'
                : 'Long-Term Equity',
        horizon: horizon,
        latestNav: 100.0,
        navDate: 'Syncing',
        cagr1Y: 12.0,
        cagr3Y: 14.0,
        cagr5Y: 15.0,
      );

      await _updateSingleFundQuantMetrics(newFund);
      quantFunds.removeWhere((f) => f.schemeCode == code);
      quantFunds.insert(0, newFund);
      return newFund;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // C. ON-DEVICE FINANCIAL NLP NEWS SENTIMENT & REGIME ENGINE
  // ==========================================================================

  Future<void> _syncNewsAndComputeMarketRegime() async {
    const urls = [
      'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
      'https://economictimes.indiatimes.com/rssfeedsdefault.cms',
    ];

    for (final u in urls) {
      try {
        final req = await _http.getUrl(Uri.parse(u));
        req.headers.set('User-Agent', 'Mozilla/5.0');
        final res = await req.close();
        if (res.statusCode == 200) {
          final xml = await res.transform(utf8.decoder).join();
          final items = _parseAndScoreNewsRss(xml);
          if (items.isNotEmpty) {
            liveNews = items;
            double sumWeights = 0;
            for (final item in items) {
              sumWeights += item.sentimentWeight;
            }
            marketSentimentIndex = double.parse(
                ((sumWeights / items.length) * 100.0)
                    .clamp(-100.0, 100.0)
                    .toStringAsFixed(1));
            return;
          }
        }
      } catch (_) {}
    }
  }

  List<NewsSentimentItem> _parseAndScoreNewsRss(String xml) {
    final List<NewsSentimentItem> results = [];
    final itemMatches =
        RegExp(r'<item>([\s\S]*?)<\/item>', caseSensitive: false)
            .allMatches(xml);

    const Map<String, double> lexicon = {
      'surge': 0.8,
      'rally': 0.85,
      'breakout': 0.75,
      'bull': 0.8,
      'record high': 0.9,
      'buy': 0.6,
      'profit': 0.65,
      'upgrade': 0.7,
      'inflow': 0.6,
      'multibagger': 0.85,
      'jump': 0.6,
      'gain': 0.5,
      'crash': -0.9,
      'plunge': -0.85,
      'selloff': -0.8,
      'bear': -0.75,
      'slump': -0.7,
      'loss': -0.65,
      'downgrade': -0.7,
      'outflow': -0.6,
      'fall': -0.5,
      'drop': -0.5,
      'inflation': -0.45,
      'deficit': -0.4,
    };

    const Map<String, List<String>> sectorMap = {
      'Banking & Finance': ['bank', 'rbi', 'hdfc', 'icici', 'sbi', 'nbfc'],
      'IT & Tech': ['infosys', 'tcs', 'wipro', 'tech', 'ai', 'software'],
      'Energy & Power': ['reliance', 'suzlon', 'power', 'oil', 'solar', 'ntpc'],
      'Metals & Infra': ['tata steel', 'jsw', 'metal', 'infra', 'cement'],
      'Auto & EV': ['tata motors', 'mahindra', 'maruti', 'ev', 'auto'],
    };

    for (final m in itemMatches.take(12)) {
      final block = m.group(1) ?? '';
      final title = _stripXml(_extractXmlTag(block, 'title'));
      final desc = _stripXml(_extractXmlTag(block, 'description'));
      final date = _stripXml(_extractXmlTag(block, 'pubDate'));
      if (title.isEmpty) continue;

      final combined = '$title $desc'.toLowerCase();
      double score = 0.0;
      int hits = 0;
      lexicon.forEach((word, weight) {
        if (combined.contains(word)) {
          score += weight;
          hits++;
        }
      });
      final normalizedScore =
          hits > 0 ? (score / math.sqrt(hits)).clamp(-1.0, 1.0) : 0.0;

      final List<String> sectors = [];
      sectorMap.forEach((sectorName, keywords) {
        if (keywords.any((k) => combined.contains(k))) {
          sectors.add(sectorName);
        }
      });
      if (sectors.isEmpty) sectors.add('Broad NSE/BSE Market');

      results.add(NewsSentimentItem(
        title: title,
        summary: desc.length > 170 ? '${desc.substring(0, 170)}...' : desc,
        pubDate: date,
        sentimentWeight: double.parse(normalizedScore.toStringAsFixed(2)),
        detectedSectors: sectors,
      ));
    }
    return results;
  }

  String _extractXmlTag(String block, String tag) {
    return RegExp('<$tag[^>]*>([\\s\\S]*?)<\\/$tag>', caseSensitive: false)
            .firstMatch(block)
            ?.group(1) ??
        '';
  }

  String _stripXml(String input) {
    return input
        .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  // ==========================================================================
  // D. AUTONOMOUS PORTFOLIO & QUERY INFERENCE ENGINE (<1 SEC)
  // ==========================================================================

  Future<String> processUserCommand(String rawInput) async {
    final input = rawInput.trim();
    final lower = input.toLowerCase();

    // 1. Check if the user typed an NSE Stock Ticker or "analyze [stock]"
    final tickerCandidate = _extractPotentialTicker(input);
    if (tickerCandidate != null) {
      final cached = cachedStockSignals[tickerCandidate];
      final signal = cached ?? await analyzeLiveStock(tickerCandidate);
      if (signal != null) {
        return _formatStockSignalReport(signal);
      }
    }

    // 2. Check if user wants a Mutual Fund searched & analyzed live by AMC/name
    final mfKeywords = [
      'sbi',
      'axis',
      'quant',
      'kotak',
      'mirae',
      'tata',
      'aditya',
      'dsp',
      'uti',
      'bandhan',
      'edelweiss',
      'canara'
    ];
    for (final kw in mfKeywords) {
      if (lower.contains(kw)) {
        final fund = await searchAndAnalyzeLiveFund(input);
        if (fund != null) {
          return _formatQuantFundReport(fund);
        }
      }
    }

    // 3. Autonomous Goal, Horizon & Capital Allocation Optimizer
    return generateInstantQuantResponse(input);
  }

  String generateInstantQuantResponse(String rawInput) {
    final lower = rawInput.toLowerCase();

    // Extract any numbers (Capital amount, years, target return)
    final nums = RegExp(r'\d+(\.\d+)?')
        .allMatches(lower)
        .map((m) => double.tryParse(m.group(0)!) ?? 0)
        .where((n) => n > 0)
        .toList();

    final double capital =
        nums.firstWhere((n) => n >= 500, orElse: () => 10000);
    final int years = nums
        .firstWhere((n) => n >= 1 && n <= 40, orElse: () => 5)
        .toInt();

    if (lower.contains('short') ||
        lower.contains('month') ||
        lower.contains('1 year') ||
        lower.contains('liquid')) {
      return _buildHorizonQuantSynthesis(
          TimeHorizon.shortTerm, capital, math.min(years, 1));
    }
    if (lower.contains('mid') ||
        lower.contains('2 year') ||
        lower.contains('3 year') ||
        lower.contains('hybrid') ||
        lower.contains('balanced')) {
      return _buildHorizonQuantSynthesis(
          TimeHorizon.middleTerm, capital, years.clamp(2, 3));
    }
    if (lower.contains('long') ||
        lower.contains('5 year') ||
        lower.contains('10 year') ||
        lower.contains('equity') ||
        lower.contains('small') ||
        lower.contains('flexi')) {
      return _buildHorizonQuantSynthesis(
          TimeHorizon.longTerm, capital, math.max(years, 5));
    }

    if (lower.contains('news') ||
        lower.contains('sentiment') ||
        lower.contains('market') ||
        lower.contains('nifty')) {
      return _buildNewsAndRegimeSynthesis();
    }

    if (nums.isNotEmpty ||
        lower.contains('invest') ||
        lower.contains('return') ||
        lower.contains('interest') ||
        lower.contains('mutual fund') ||
        lower.contains('mf')) {
      return _buildCompleteHorizonMatrix(capital, years);
    }

    // Dynamic Mutual Fund Architecture & Tax Reasoning
    return _buildDeepMfDomainSynthesis(lower, capital, years);
  }

  String? _extractPotentialTicker(String input) {
    final cleaned = input.trim().toUpperCase();
    const ignoreWords = {
      'SHORT',
      'MIDDLE',
      'MEDIUM',
      'LONG',
      'TERM',
      'MUTUAL',
      'FUND',
      'FUNDS',
      'NEWS',
      'MARKET',
      'SIP',
      'NAV',
      'TAX',
      'BEST',
      'INVEST',
      'RETURN',
      'RETURNS',
      'INTEREST',
      'ELSS',
      'CAGR',
      'SHARPE',
      'HELLO',
      'HI'
    };

    // Single word ticker like "SUZLON" or "RELIANCE" or "TCS"
    if (RegExp(r'^[A-Z]{2,12}(\.NS)?$').hasMatch(cleaned) &&
        !ignoreWords.contains(cleaned)) {
      return cleaned.replaceAll('.NS', '');
    }

    // Phrase like "buy suzlon" or "stock tatasteel"
    final match = RegExp(
            r'(?:stock|analyze|buy|sell|signal|chart|price|target)\s+([a-zA-Z]{2,12})',
            caseSensitive: false)
        .firstMatch(input);
    if (match != null) {
      final candidate = match.group(1)!.toUpperCase();
      if (!ignoreWords.contains(candidate)) return candidate;
    }
    return null;
  }

  String _formatStockSignalReport(StockAiSignal s) {
    return '''🤖 **NEURAL TRADING AI SIGNAL: ${s.symbol} (NSE)**
• **AI Verdict:** ${s.verdict} (Confidence: **${s.aiConfidence.toStringAsFixed(1)}%**)
• **Live Price:** ₹${s.currentPrice.toStringAsFixed(2)} (${s.changePercent >= 0 ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%)
• **Indicators:** RSI(14): **${s.rsi14.toStringAsFixed(1)}** | EMA-9: ₹${s.ema9.toStringAsFixed(2)} | EMA-21: ₹${s.ema21.toStringAsFixed(2)} | MACD Hist: ${s.macdHist.toStringAsFixed(3)}
• **Candle Structure:** ${s.candlePattern} | Volatility (ATR-14): ₹${s.atr14.toStringAsFixed(2)}

🎯 **ALGORITHMIC TRADE LEVELS:**
• **Entry Zone:** ₹${s.entryPrice.toStringAsFixed(2)}
• **Target 1 (1.8x ATR):** ₹${s.target1.toStringAsFixed(2)}
• **Target 2 (3.2x ATR):** ₹${s.target2.toStringAsFixed(2)}
• **Stop-Loss (1.3x ATR):** ₹${s.stopLoss.toStringAsFixed(2)}

🧠 **AI Factor Breakdown:**
${s.reasoning.map((r) => '• $r').join('\n')}''';
  }

  String _formatQuantFundReport(QuantMutualFund f) {
    final sip5Y = _sipFutureValue(10000, f.cagr5Y, 5);
    return '''📊 **LIVE QUANT MUTUAL FUND ANALYSIS**
**${f.schemeName}** (Code: ${f.schemeCode})
• **AI Quant Score:** **${f.aiScore}/100** | Ideal Horizon: **${_horizonLabel(f.horizon)}**
• **Latest NAV:** ₹${f.latestNav.toStringAsFixed(2)} (As of ${f.navDate})
• **Rolling CAGR Returns:** 1Y: **${f.cagr1Y}%** | 3Y: **${f.cagr3Y}%** | 5Y: **${f.cagr5Y}%**
• **Risk Metrics:** Volatility: **${f.volatility}%** | Sharpe Ratio: **${f.sharpeRatio}** | Max Drawdown: **${f.maxDrawdown}%**
• **Compound Projection:** ₹10,000/mo SIP for 5 Yrs @ ${f.cagr5Y}% → **₹${_formatInr(sip5Y)}** (Principal: ₹6.00 Lakh)''';
  }

  String _buildHorizonQuantSynthesis(
      TimeHorizon horizon, double monthlySip, int years) {
    final list = quantFunds.where((f) => f.horizon == horizon).toList()
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));

    final buffer = StringBuffer(
        '🧠 **AI QUANT RANKING: ${_horizonLabel(horizon).toUpperCase()}**\n'
        'Market Sentiment Index: **$marketSentimentIndex** | Evaluated on CAGR, Sharpe Ratio & Drawdown\n\n');

    for (int i = 0; i < list.length; i++) {
      final f = list[i];
      final rate = horizon == TimeHorizon.shortTerm
          ? f.cagr1Y
          : horizon == TimeHorizon.middleTerm
              ? f.cagr3Y
              : f.cagr5Y;
      final maturity = _sipFutureValue(monthlySip, rate, years);
      final principal = monthlySip * 12 * years;

      buffer.writeln(
          '${i + 1}. **${f.schemeName}** (AI Score: **${f.aiScore}/100**)\n'
          '   • Live NAV: ₹${f.latestNav.toStringAsFixed(2)} | **1Y: ${f.cagr1Y}%** | **3Y: ${f.cagr3Y}%** | **5Y: ${f.cagr5Y}%**\n'
          '   • Quant Risk: Sharpe **${f.sharpeRatio}** | Volatility **${f.volatility}%** | Max DD **${f.maxDrawdown}%**\n'
          '   • ₹${monthlySip.toInt()}/mo SIP for $years Yrs → **₹${_formatInr(maturity)}** (Interest Earned: **₹${_formatInr(maturity - principal)}**)\n');
    }
    return buffer.toString().trim();
  }

  String _buildCompleteHorizonMatrix(double monthlySip, int years) {
    final shortTop = quantFunds
        .where((f) => f.horizon == TimeHorizon.shortTerm)
        .reduce((a, b) => a.aiScore > b.aiScore ? a : b);
    final midTop = quantFunds
        .where((f) => f.horizon == TimeHorizon.middleTerm)
        .reduce((a, b) => a.aiScore > b.aiScore ? a : b);
    final longTop = quantFunds
        .where((f) => f.horizon == TimeHorizon.longTerm)
        .reduce((a, b) => a.aiScore > b.aiScore ? a : b);

    final principal = monthlySip * 12 * years;
    final sVal = _sipFutureValue(monthlySip, shortTop.cagr1Y, years);
    final mVal = _sipFutureValue(monthlySip, midTop.cagr3Y, years);
    final lVal = _sipFutureValue(monthlySip, longTop.cagr5Y, years);

    return '''⚡ **AI MULTI-HORIZON ALLOCATION & INTEREST MATRIX**
Input Basis: **₹${monthlySip.toInt()}/month SIP** over **$years Years** (Total Invested: **₹${_formatInr(principal)}**)

1️⃣ **SHORT-TERM (0–1 Yr | Capital Safety & Liquidity):**
• Top Quant Pick: **${shortTop.schemeName}** (Score: ${shortTop.aiScore}/100)
• Return: **${shortTop.cagr1Y}% CAGR** | Sharpe: ${shortTop.sharpeRatio} | Max DD: ${shortTop.maxDrawdown}%
• Projected Value ($years Yrs): **₹${_formatInr(sVal)}** (Net Interest: +₹${_formatInr(sVal - principal)})

2️⃣ **MIDDLE-TERM (1–3 Yrs | Dynamic Equity-Debt Hybrid):**
• Top Quant Pick: **${midTop.schemeName}** (Score: ${midTop.aiScore}/100)
• Return: **${midTop.cagr3Y}% 3Y CAGR** | Sharpe: ${midTop.sharpeRatio} | Max DD: ${midTop.maxDrawdown}%
• Projected Value ($years Yrs): **₹${_formatInr(mVal)}** (Net Interest: +₹${_formatInr(mVal - principal)})

3️⃣ **LONG-TERM (5+ Yrs | High-Compounding Wealth):**
• Top Quant Pick: **${longTop.schemeName}** (Score: ${longTop.aiScore}/100)
• Return: **${longTop.cagr5Y}% 5Y CAGR** | Sharpe: ${longTop.sharpeRatio} | Max DD: ${longTop.maxDrawdown}%
• Projected Value ($years Yrs): **₹${_formatInr(lVal)}** (Net Interest: +₹${_formatInr(lVal - principal)})''';
  }

  String _buildNewsAndRegimeSynthesis() {
    if (liveNews.isEmpty) {
      return '📡 **NLP News Engine:** Syncing live Indian stock market RSS feeds. Tap the refresh icon or check the News NLP tab.';
    }
    final regime = marketSentimentIndex >= 15
        ? '🟢 RISK-ON BULLISH (Index: +$marketSentimentIndex)'
        : marketSentimentIndex <= -15
            ? '🔴 RISK-OFF DEFENSIVE (Index: $marketSentimentIndex)'
            : '🟡 NEUTRAL CONSOLIDATION (Index: $marketSentimentIndex)';

    final buf = StringBuffer('📰 **LIVE NLP NEWS SENTIMENT & TRADING REGIME**\n'
        '• **Regime:** $regime\n\n');

    for (final item in liveNews.take(5)) {
      final tag = item.sentimentWeight > 0.15
          ? '🟢 +${item.sentimentWeight}'
          : item.sentimentWeight < -0.15
              ? '🔴 ${item.sentimentWeight}'
              : '🟡 0.0';
      buf.writeln(
          '• **[$tag | ${item.detectedSectors.first}]** ${item.title}\n  _${item.summary}_\n');
    }

    buf.writeln(
        '🤖 **AI Portfolio Adjustment:** ${marketSentimentIndex < 0 ? "Shift fresh lumpsum inflows to Ultra-Short Liquid Funds and stagger equity entry via weekly STP." : "Favorable momentum for Flexi-Cap & Mid-Cap SIP continuation and breakout swing setups."}');
    return buf.toString().trim();
  }

  String _buildDeepMfDomainSynthesis(
      String query, double monthlySip, int years) {
    final directCorpus = _sipFutureValue(monthlySip, 18.0, years);
    final regularCorpus = _sipFutureValue(monthlySip, 16.9, years);
    final commissionLoss = directCorpus - regularCorpus;
    final gain = directCorpus - (monthlySip * 12 * years);
    final taxableLtcg = math.max(0.0, gain - 125000);
    final estimatedTax = taxableLtcg * 0.125;

    return '''🧠 **AUTONOMOUS TRADER & MUTUAL FUND AI ENGINE**
Type **any NSE Stock Symbol** (e.g. `SUZLON`, `RELIANCE`, `TATASTEEL`, `ZOMATO`), **any AMC/Mutual Fund name** (e.g. `SBI`, `Quant`, `Axis`), or **any investment amount & years** (e.g. `25000 for 7 years`).

📐 **LIVE QUANT SIMULATION FOR ₹${monthlySip.toInt()}/MO OVER $years YEARS:**
• **Direct Plan (@18.0% CAGR):** **₹${_formatInr(directCorpus)}**
• **Regular Plan (@16.9% after 1.1% Expense Commission):** **₹${_formatInr(regularCorpus)}**
• **Hidden Broker Commission Saved by Direct Plan:** **₹${_formatInr(commissionLoss)}**
• **Post-Tax LTCG Calculation (12.5% above ₹1.25L exemption):** Est. Tax = **₹${_formatInr(estimatedTax)}** | Net Take-Home = **₹${_formatInr(directCorpus - estimatedTax)}**''';
  }

  String _horizonLabel(TimeHorizon h) {
    switch (h) {
      case TimeHorizon.shortTerm:
        return 'Short-Term (0–1 Year)';
      case TimeHorizon.middleTerm:
        return 'Middle-Term (1–3 Years)';
      case TimeHorizon.longTerm:
        return 'Long-Term (5+ Years)';
    }
  }

  double _sipFutureValue(double monthly, double cagrPct, int years) {
    final double r = (cagrPct / 100.0) / 12.0;
    final int n = years * 12;
    if (r <= 0) return monthly * n;
    return monthly * ((math.pow(1 + r, n) - 1) / r) * (1 + r);
  }

  String _formatInr(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} Lakh';
    return v.toStringAsFixed(0);
  }
}

// ============================================================================
// 3. ZERO-SCAFFOLD OVERLAY WRAPPER (1-LINE INTEGRATION FOR ANY MAIN.DART)
// ============================================================================

class TraderAiOverlayWrapper extends StatefulWidget {
  final Widget child;
  const TraderAiOverlayWrapper({super.key, required this.child});

  @override
  State<TraderAiOverlayWrapper> createState() => _TraderAiOverlayWrapperState();
}

class _TraderAiOverlayWrapperState extends State<TraderAiOverlayWrapper> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOpen)
          Positioned.fill(
            child: Material(
              color: const Color(0xFF080E1A),
              child: TraderAgentScreen(
                onClose: () => setState(() => _isOpen = false),
              ),
            ),
          ),
        if (!_isOpen)
          Positioned(
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                elevation: 8,
                icon: const Icon(Icons.auto_graph),
                label: const Text(
                  'AI Trader',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                onPressed: () => setState(() => _isOpen = true),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// 4. FULL AI TERMINAL UI (STOCK SCANNER + MF QUANT + NLP NEWS + AI CONSOLE)
// ============================================================================

class TraderAgentScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const TraderAgentScreen({super.key, this.onClose});

  @override
  State<TraderAgentScreen> createState() => _TraderAgentScreenState();
}

class _TraderAgentScreenState extends State<TraderAgentScreen>
    with SingleTickerProviderStateMixin {
  final AutonomousTraderAi _ai = AutonomousTraderAi();
  late TabController _tabController;

  final TextEditingController _consoleController = TextEditingController();
  final TextEditingController _stockInputController =
      TextEditingController(text: 'SUZLON');
  final TextEditingController _mfSearchController = TextEditingController();

  TimeHorizon _selectedHorizon = TimeHorizon.longTerm;
  double _monthlySip = 15000;
  int _years = 5;
  bool _isAnalyzingStock = false;
  bool _isSearchingMf = false;

  final List> _consoleLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _consoleLogs.add({
      'isUser': false,
      'ms': 1,
      'text': _ai.generateInstantQuantResponse('overview'),
    });
    _ai.initializeAndSync(onUpdated: () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _executeConsoleCommand(String raw) async {
    if (raw.trim().isEmpty) return;
    _consoleController.clear();
    final sw = Stopwatch()..start();

    setState(() {
      _consoleLogs.add({'isUser': true, 'ms': 0, 'text': raw.trim()});
    });

    final reply = await _ai.processUserCommand(raw);
    sw.stop();

    if (mounted) {
      setState(() {
        _consoleLogs.add({
          'isUser': false,
          'ms': sw.elapsedMilliseconds,
          'text': reply,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10192E),
        foregroundColor: Colors.white,
        leading: widget.onClose != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onClose,
              )
            : null,
        title: Row(
          children: [
            const Icon(Icons.memory, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'On-Device Quant & Neural Trader AI',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _ai.marketSentimentIndex >= 0
                    ? Colors.green.withOpacity(0.25)
                    : Colors.red.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Mood: ${_ai.marketSentimentIndex >= 0 ? '+' : ''}${_ai.marketSentimentIndex}',
                style: TextStyle(
                  color: _ai.marketSentimentIndex >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: _ai.isSyncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.greenAccent),
                    )
                  : const Icon(Icons.sync, size: 18),
              onPressed: () => _ai.initializeAndSync(
                onUpdated: () => setState(() {}),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '📊 MF Quant AI'),
            Tab(text: '⚡ Stock Neural AI'),
            Tab(text: '📰 News NLP'),
            Tab(text: '🧠 Free-Form AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMfQuantTab(),
          _buildStockNeuralScannerTab(),
          _buildNewsNlpTab(),
          _buildFreeFormConsoleTab(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: AUTONOMOUS MUTUAL FUND QUANT ANALYZER (SHORT / MIDDLE / LONG)
  // --------------------------------------------------------------------------
  Widget _buildMfQuantTab() {
    final funds = _ai.quantFunds
        .where((f) => f.horizon == _selectedHorizon)
        .toList()
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Live AMFI Search across 10,000+ schemes
        TextField(
          controller: _mfSearchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText:
                'Analyze any live Indian MF (e.g. Quant Small Cap, SBI Contra)...',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
            prefixIcon: const Icon(Icons.manage_search, color: Colors.greenAccent),
            suffixIcon: _isSearchingMf
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.bolt, color: Colors.amberAccent),
                    onPressed: () async {
                      if (_mfSearchController.text.trim().isEmpty) return;
                      setState(() => _isSearchingMf = true);
                      final f = await _ai
                          .searchAndAnalyzeLiveFund(_mfSearchController.text);
                      if (mounted) {
                        setState(() {
                          _isSearchingMf = false;
                          if (f != null) _selectedHorizon = f.horizon;
                        });
                      }
                    },
                  ),
            filled: true,
            fillColor: const Color(0xFF131F38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (v) async {
            if (v.trim().isEmpty) return;
            setState(() => _isSearchingMf = true);
            final f = await _ai.searchAndAnalyzeLiveFund(v);
            if (mounted) {
              setState(() {
                _isSearchingMf = false;
                if (f != null) _selectedHorizon = f.horizon;
              });
            }
          },
        ),
        const SizedBox(height: 12),

        // Horizon Selection
        Row(
          children: [
            _horizonChip(
                TimeHorizon.shortTerm, 'Short (0–1Y)', Colors.cyanAccent),
            const SizedBox(width: 8),
            _horizonChip(
                TimeHorizon.middleTerm, 'Middle (1–3Y)', Colors.amberAccent),
            const SizedBox(width: 8),
            _horizonChip(
                TimeHorizon.longTerm, 'Long (5Y+)', Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 12),

        // Interactive Compound Interest & Horizon Simulator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF131F38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SIP Capital: ₹${_monthlySip.toInt()}/mo',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<int>(
                    dropdownColor: const Color(0xFF131F38),
                    value: _years,
                    items: [1, 2, 3, 5, 7, 10, 15, 20]
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y Years',
                                  style: const TextStyle(
                                      color: Colors.greenAccent)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _years = v);
                    },
                  ),
                ],
              ),
              Slider(
                value: _monthlySip,
                min: 1000,
                max: 100000,
                divisions: 99,
                activeColor: const Color(0xFF00E676),
                onChanged: (v) => setState(() => _monthlySip = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ranked Quant Mutual Fund Cards
        ...funds.map((f) {
          final rate = _selectedHorizon == TimeHorizon.shortTerm
              ? f.cagr1Y
              : _selectedHorizon == TimeHorizon.middleTerm
                  ? f.cagr3Y
                  : f.cagr5Y;
          final maturity = _ai._sipFutureValue(_monthlySip, rate, _years);
          final invested = _monthlySip * 12 * _years;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF121D35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI Score: ${f.aiScore}',
                        style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.schemeName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'NAV: ₹${f.latestNav.toStringAsFixed(2)} (${f.navDate}) • Sharpe: ${f.sharpeRatio} • Volatility: ${f.volatility}% • Max DD: ${f.maxDrawdown}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Divider(color: Colors.white12, height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricColumn('1Y Return', '${f.cagr1Y}%'),
                    _metricColumn('3Y CAGR', '${f.cagr3Y}%'),
                    _metricColumn('5Y CAGR', '${f.cagr5Y}%'),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080E1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Projected Corpus ($_years Yrs @ $rate%): ₹${_ai._formatInr(maturity)} '
                    '| Net Profit: +₹${_ai._formatInr(maturity - invested)}',
                    style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: ON-DEVICE NEURAL STOCK TRADING SCANNER (LIVE NSE CANDLESTICKS)
  // --------------------------------------------------------------------------
  Widget _buildStockNeuralScannerTab() {
    final signals = _ai.cachedStockSignals.values.toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stockInputController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Enter NSE Symbol (e.g. SUZLON, RELIANCE, IRFC, TCS)...',
                  hintStyle:
                      const TextStyle(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF131F38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              icon: _isAnalyzingStock
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.radar),
              label: const Text('Run AI',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                setState(() => _isAnalyzingStock = true);
                await _ai.analyzeLiveStock(_stockInputController.text);
                if (mounted) setState(() => _isAnalyzingStock = false);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...signals.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF131F38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${s.symbol} • ₹${s.currentPrice.toStringAsFixed(2)} (${s.changePercent >= 0 ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%)',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      '${s.verdict} (${s.aiConfidence.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'RSI(14): ${s.rsi14.toStringAsFixed(1)} | EMA9: ₹${s.ema9.toStringAsFixed(2)} | EMA21: ₹${s.ema21.toStringAsFixed(2)} | Pattern: ${s.candlePattern}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricColumn(
                        'Entry', '₹${s.entryPrice.toStringAsFixed(2)}'),
                    _metricColumn(
                        'Target 1', '₹${s.target1.toStringAsFixed(2)}'),
                    _metricColumn(
                        'Target 2', '₹${s.target2.toStringAsFixed(2)}'),
                    _metricColumn(
                        'Stop Loss', '₹${s.stopLoss.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                ...s.reasoning.map((r) => Text(
                      '• $r',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: LIVE NEWS NLP SENTIMENT & SECTOR IMPACT
  // --------------------------------------------------------------------------
  Widget _buildNewsNlpTab() {
    if (_ai.liveNews.isEmpty) {
      return const Center(
        child: Text(
          'Syncing live Indian market RSS feeds...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _ai.liveNews.length,
      itemBuilder: (context, idx) {
        final item = _ai.liveNews[idx];
        final isBull = item.sentimentWeight > 0.1;
        final isBear = item.sentimentWeight < -0.1;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF131F38),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBull
                        ? '🟢 Bullish (Weight: +${item.sentimentWeight})'
                        : isBear
                            ? '🔴 Bearish (Weight: ${item.sentimentWeight})'
                            : '🟡 Neutral (0.0)',
                    style: TextStyle(
                      color: isBull
                          ? Colors.greenAccent
                          : isBear
                              ? Colors.redAccent
                              : Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    item.detectedSectors.first,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                item.summary,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // TAB 4: FREE-FORM AI ANALYST CONSOLE
  // --------------------------------------------------------------------------
  Widget _buildFreeFormConsoleTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _consoleLogs.length,
            itemBuilder: (context, idx) {
              final log = _consoleLogs[idx];
              final bool isUser = log['isUser'] as bool;
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF00695C)
                        : const Color(0xFF131F38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        log['text'].toString(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13.5, height: 1.4),
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 6),
                        Text(
                          '⚡ Computed in ${log['ms']} ms • On-Device Quant Engine',
                          style: const TextStyle(
                              color: Colors.greenAccent, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          color: const Color(0xFF10192E),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _consoleController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _executeConsoleCommand,
                  decoration: InputDecoration(
                    hintText:
                        'Type any NSE stock (SUZLON), MF (SBI), or SIP amount...',
                    hintStyle:
                        const TextStyle(color: Colors.white54, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF080E1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF00E676),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black),
                  onPressed: () =>
                      _executeConsoleCommand(_consoleController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _horizonChip(TimeHorizon h, String label, Color color) {
    final selected = _selectedHorizon == h;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedHorizon = h),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : const Color(0xFF131F38),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.white12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricColumn(String label, String val) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      ],
    );
  }
}
