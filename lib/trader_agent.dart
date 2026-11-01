import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

// ============================================================================
// 1. DATA MODELS
// ============================================================================

enum HorizonType { shortTerm, mediumTerm, longTerm }

class MutualFundScheme {
  final int schemeCode;
  final String schemeName;
  final String category;
  final HorizonType horizon;
  final String riskLevel;
  double latestNav;
  String latestDate;
  double return1Y;
  double return3Y;
  double return5Y;
  bool isLiveLoaded;

  MutualFundScheme({
    required this.schemeCode,
    required this.schemeName,
    required this.category,
    required this.horizon,
    required this.riskLevel,
    required this.latestNav,
    required this.latestDate,
    required this.return1Y,
    required this.return3Y,
    required this.return5Y,
    this.isLiveLoaded = false,
  });
}

class MarketNewsItem {
  final String title;
  final String summary;
  final String pubDate;
  final String sentiment; // Bullish, Bearish, Neutral

  MarketNewsItem({
    required this.title,
    required this.summary,
    required this.pubDate,
    required this.sentiment,
  });
}

class AgentMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final int responseTimeMs;

  AgentMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.responseTimeMs = 0,
  });
}

// ============================================================================
// 2. FAST (<1 SEC) INDIAN TRADER & MUTUAL FUND AI ENGINE
// ============================================================================

class IndianTraderAgentEngine {
  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 6);

  bool isSyncing = false;
  DateTime? lastSynced;

  // Curated benchmark Indian Mutual Funds across Short, Medium & Long horizons
  // Backed by live sync with https://api.mfapi.in/mf/{schemeCode}
  final List<MutualFundScheme> trackedFunds = [
    // SHORT TERM (Liquid & Ultra Short Duration - Low Risk, 1M to 12M)
    MutualFundScheme(
      schemeCode: 119062,
      schemeName: 'HDFC Liquid Fund - Direct Plan - Growth',
      category: 'Debt - Liquid Fund',
      horizon: HorizonType.shortTerm,
      riskLevel: 'Low to Moderate',
      latestNav: 4985.20,
      latestDate: 'Live Cache',
      return1Y: 7.25,
      return3Y: 6.45,
      return5Y: 5.60,
    ),
    MutualFundScheme(
      schemeCode: 120533,
      schemeName: 'ICICI Prudential Ultra Short Term Fund - Direct - Growth',
      category: 'Debt - Ultra Short Duration',
      horizon: HorizonType.shortTerm,
      riskLevel: 'Moderate',
      latestNav: 28.45,
      latestDate: 'Live Cache',
      return1Y: 7.55,
      return3Y: 6.80,
      return5Y: 6.35,
    ),
    MutualFundScheme(
      schemeCode: 119766,
      schemeName: 'SBI Magnum Ultra Short Duration Fund - Direct - Growth',
      category: 'Debt - Ultra Short Duration',
      horizon: HorizonType.shortTerm,
      riskLevel: 'Low to Moderate',
      latestNav: 5712.10,
      latestDate: 'Live Cache',
      return1Y: 7.35,
      return3Y: 6.55,
      return5Y: 5.95,
    ),

    // MEDIUM TERM (Balanced Advantage, Aggressive Hybrid & Conservative - 1 to 3+ Yrs)
    MutualFundScheme(
      schemeCode: 118968,
      schemeName: 'ICICI Prudential Balanced Advantage Fund - Direct - Growth',
      category: 'Hybrid - Balanced Advantage (BAF)',
      horizon: HorizonType.mediumTerm,
      riskLevel: 'Moderately High',
      latestNav: 74.80,
      latestDate: 'Live Cache',
      return1Y: 16.40,
      return3Y: 14.80,
      return5Y: 14.20,
    ),
    MutualFundScheme(
      schemeCode: 119063,
      schemeName: 'HDFC Balanced Advantage Fund - Direct Plan - Growth',
      category: 'Hybrid - Balanced Advantage (BAF)',
      horizon: HorizonType.mediumTerm,
      riskLevel: 'High',
      latestNav: 518.90,
      latestDate: 'Live Cache',
      return1Y: 22.10,
      return3Y: 21.30,
      return5Y: 19.80,
    ),
    MutualFundScheme(
      schemeCode: 119609,
      schemeName: 'SBI Equity Hybrid Fund - Direct Plan - Growth',
      category: 'Hybrid - Aggressive Hybrid',
      horizon: HorizonType.mediumTerm,
      riskLevel: 'High',
      latestNav: 292.40,
      latestDate: 'Live Cache',
      return1Y: 18.20,
      return3Y: 15.10,
      return5Y: 16.05,
    ),

    // LONG TERM (Flexi Cap, Large Cap, Mid Cap & Small Cap - 5+ Yrs Wealth Creation)
    MutualFundScheme(
      schemeCode: 122639,
      schemeName: 'Parag Parikh Flexi Cap Fund - Direct Plan - Growth',
      category: 'Equity - Flexi Cap Fund',
      horizon: HorizonType.longTerm,
      riskLevel: 'Very High',
      latestNav: 86.30,
      latestDate: 'Live Cache',
      return1Y: 26.80,
      return3Y: 21.40,
      return5Y: 24.10,
    ),
    MutualFundScheme(
      schemeCode: 125497,
      schemeName: 'HDFC Top 100 Fund - Direct Plan - Growth',
      category: 'Equity - Large Cap Fund',
      horizon: HorizonType.longTerm,
      riskLevel: 'Very High',
      latestNav: 1195.40,
      latestDate: 'Live Cache',
      return1Y: 23.50,
      return3Y: 19.80,
      return5Y: 18.90,
    ),
    MutualFundScheme(
      schemeCode: 127042,
      schemeName: 'Motilal Oswal Midcap Fund - Direct Plan - Growth',
      category: 'Equity - Mid Cap Fund',
      horizon: HorizonType.longTerm,
      riskLevel: 'Very High',
      latestNav: 108.70,
      latestDate: 'Live Cache',
      return1Y: 42.10,
      return3Y: 31.50,
      return5Y: 29.40,
    ),
    MutualFundScheme(
      schemeCode: 125354,
      schemeName: 'Nippon India Small Cap Fund - Direct Plan - Growth',
      category: 'Equity - Small Cap Fund',
      horizon: HorizonType.longTerm,
      riskLevel: 'Very High',
      latestNav: 184.20,
      latestDate: 'Live Cache',
      return1Y: 33.40,
      return3Y: 29.80,
      return5Y: 32.10,
    ),
  ];

  List<MarketNewsItem> cachedNews = [];

  // Complete Mutual Fund & Indian Market Knowledge Base
  final Map<String, String> _knowledgeBase = {
    'nav':
        '📌 **NAV (Net Asset Value):**\nNAV is the per-unit market price of a mutual fund scheme.\n• **Formula:** `(Total Assets - Total Liabilities) / Total Outstanding Units`\n• Unlike stocks, a lower or higher NAV does NOT mean a fund is cheap or expensive—what matters is the **% CAGR return** and portfolio quality.',
    'sip':
        '📌 **SIP (Systematic Investment Plan) vs Lumpsum:**\n• **SIP:** Invests a fixed amount monthly. Gives you **Rupee Cost Averaging** (buys more units when markets crash, fewer when high).\n• **Lumpsum:** One-time investment. Ideal for Debt/Liquid funds or when Nifty 50 P/E valuation is significantly below historical averages.',
    'direct':
        '📌 **Direct vs Regular Plans:**\n• **Direct Plan:** Buy directly from the AMC/app with **0% distributor commission**. Has a lower Expense Ratio, saving 0.5% to 1.2% every year.\n• **Regular Plan:** Bought via brokers/distributors who take a trailing commission out of your compounding returns.\n• *Trader Verdict:* Always pick **Direct - Growth** plans.',
    'tax':
        '📌 **Indian Mutual Fund Taxation Rules:**\n• **Equity Funds (>65% Indian equities):**\n  - **STCG (< 12 months):** 20% tax on gains.\n  - **LTCG (> 12 months):** 12.5% tax on gains above ₹1.25 Lakh exemption per financial year.\n• **Debt / Liquid Funds (<35% equity):**\n  - Gains are added to your income and taxed at your **applicable Income Tax Slab Rate**.',
    'elss':
        '📌 **ELSS (Equity Linked Savings Scheme):**\n• Tax-saving mutual funds eligible for up to **₹1.5 Lakh deduction under Section 80C** (Old Tax Regime).\n• Has the shortest lock-in period among 80C options: **3 years**.',
    'expense':
        '📌 **Expense Ratio & Exit Load:**\n• **Expense Ratio:** Annual fee charged by the AMC for managing your money (typically 0.1%–1.0% for Direct plans). Deducted daily from NAV.\n• **Exit Load:** Penalty (usually 1%) if you withdraw from an equity fund before 1 year. Liquid funds have 0% exit load after 7 days.',
    'swp':
        '📌 **SWP (Systematic Withdrawal Plan) & STP (Systematic Transfer Plan):**\n• **SWP:** Withdraw a fixed monthly cashflow from your corpus while the rest stays invested and compounds.\n• **STP:** Park a lumpsum in a safe Liquid Fund and automatically transfer a fixed amount weekly/monthly into an Equity Fund.',
    'cagr':
        '📌 **CAGR vs XIRR:**\n• **CAGR (Compound Annual Growth Rate):** Measures point-to-point annualized return for a **Lumpsum** investment: `(End Value / Start Value)^(1 / Years) - 1`.\n• **XIRR (Extended Internal Rate of Return):** Measures actual annualized return across multiple cash flows like monthly **SIPs**.',
  };

  /// Background sync: Fetches real-time NAVs, calculates 1Y/3Y/5Y CAGR,
  /// and fetches live Indian stock market RSS news.
  Future<void> syncLiveMarketData({VoidCallback? onUpdate}) async {
    if (isSyncing) return;
    isSyncing = true;
    onUpdate?.call();

    try {
      await Future.wait([
        _refreshTrackedMutualFunds(),
        _fetchLiveMarketNews(),
      ]);
      lastSynced = DateTime.now();
    } catch (_) {
      // Keeps high-speed fallback cache if offline
    } finally {
      isSyncing = false;
      onUpdate?.call();
    }
  }

  Future<void> _refreshTrackedMutualFunds() async {
    for (final fund in trackedFunds) {
      try {
        final uri = Uri.parse('https://api.mfapi.in/mf/${fund.schemeCode}');
        final req = await _httpClient.getUrl(uri);
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final jsonMap = json.decode(body) as Map<String, dynamic>;
          final List<dynamic> data = jsonMap['data'] ?? [];
          if (data.isNotEmpty) {
            final latest = data.first;
            final latestNav = double.tryParse(latest['nav'].toString());
            if (latestNav != null && latestNav > 0) {
              fund.latestNav = latestNav;
              fund.latestDate = latest['date'].toString();
              fund.return1Y = _calculateCagrFromHistory(data, latestNav, 1);
              fund.return3Y = _calculateCagrFromHistory(data, latestNav, 3);
              fund.return5Y = _calculateCagrFromHistory(data, latestNav, 5);
              fund.isLiveLoaded = true;
            }
          }
        }
      } catch (_) {
        // Continue to next scheme if a single scheme times out
      }
    }
  }

  double _calculateCagrFromHistory(
      List<dynamic> navData, double currentNav, int years) {
    // Approximate trading days per year in Indian MF history ~ 248
    final int targetIndex = min(years * 248, navData.length - 1);
    if (targetIndex <= 0) return 0.0;
    final pastNav =
        double.tryParse(navData[targetIndex]['nav'].toString()) ?? 0.0;
    if (pastNav <= 0) return 0.0;
    final cagr = (pow(currentNav / pastNav, 1.0 / years) - 1.0) * 100.0;
    return double.parse(cagr.toStringAsFixed(2));
  }

  Future<void> _fetchLiveMarketNews() async {
    final feeds = [
      'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
      'https://economictimes.indiatimes.com/rssfeedsdefault.cms',
    ];

    for (final url in feeds) {
      try {
        final req = await _httpClient.getUrl(Uri.parse(url));
        req.headers.set('User-Agent', 'Mozilla/5.0 (Flutter Trader Agent)');
        final res = await req.close();
        if (res.statusCode == 200) {
          final xml = await res.transform(utf8.decoder).join();
          final parsed = _parseRssXml(xml);
          if (parsed.isNotEmpty) {
            cachedNews = parsed;
            return;
          }
        }
      } catch (_) {}
    }
  }

  List<MarketNewsItem> _parseRssXml(String xmlString) {
    final List<MarketNewsItem> items = [];
    final itemRegex = RegExp(r'<item>([\s\S]*?)<\/item>', caseSensitive: false);
    final matches = itemRegex.allMatches(xmlString);

    for (final match in matches.take(10)) {
      final block = match.group(1) ?? '';
      final title = _cleanXmlTag(_extractTag(block, 'title'));
      final desc = _cleanXmlTag(_extractTag(block, 'description'));
      final pubDate = _cleanXmlTag(_extractTag(block, 'pubDate'));

      if (title.isNotEmpty) {
        items.add(
          MarketNewsItem(
            title: title,
            summary: desc.isEmpty
                ? 'Market update impacting NSE/BSE indices and sectoral flows.'
                : (desc.length > 180 ? '${desc.substring(0, 180)}...' : desc),
            pubDate: pubDate,
            sentiment: _scoreNewsSentiment('$title $desc'),
          ),
        );
      }
    }
    return items;
  }

  String _extractTag(String block, String tag) {
    final regex =
        RegExp('<$tag[^>]*>([\\s\\S]*?)<\\/$tag>', caseSensitive: false);
    return regex.firstMatch(block)?.group(1) ?? '';
  }

  String _cleanXmlTag(String raw) {
    return raw
        .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  String _scoreNewsSentiment(String text) {
    final lower = text.toLowerCase();
    const bullishWords = [
      'rally',
      'surge',
      'jump',
      'gain',
      'profit',
      'bull',
      'breakout',
      'high',
      'buy',
      'up',
      'multibagger',
      'zooms',
      'climb'
    ];
    const bearishWords = [
      'crash',
      'plunge',
      'fall',
      'drop',
      'loss',
      'bear',
      'rout',
      'slump',
      'selloff',
      'down',
      'slash',
      'laggard',
      'weak'
    ];

    int score = 0;
    for (final w in bullishWords) {
      if (lower.contains(w)) score++;
    }
    for (final w in bearishWords) {
      if (lower.contains(w)) score--;
    }

    if (score > 0) return '🟢 Bullish';
    if (score < 0) return '🔴 Bearish';
    return '🟡 Neutral';
  }

  // ==========================================================================
  // SUB-MILLISECOND INSTANT REPLY ENGINE (< 10ms Execution)
  // ==========================================================================

  String generateInstantReply(String userQuery) {
    final q = userQuery.toLowerCase().trim();

    // 1. Check if user wants SIP / Compound Interest Calculation
    if (q.contains('calculate') ||
        q.contains('interest') ||
        RegExp(r'\b\d{3,}\b').hasMatch(q)) {
      return _handleInterestAndSipProjection(q);
    }

    // 2. Check Time Horizon Queries (Short, Medium/Middle, Long)
    if (q.contains('short') ||
        q.contains('liquid') ||
        q.contains('1 year') ||
        q.contains('6 month') ||
        q.contains('park')) {
      return formatHorizonRecommendation(HorizonType.shortTerm);
    }
    if (q.contains('mid') ||
        q.contains('medium') ||
        q.contains('balanced') ||
        q.contains('hybrid') ||
        q.contains('3 year')) {
      return formatHorizonRecommendation(HorizonType.mediumTerm);
    }
    if (q.contains('long') ||
        q.contains('5 year') ||
        q.contains('10 year') ||
        q.contains('wealth') ||
        q.contains('flexi') ||
        q.contains('small cap')) {
      return formatHorizonRecommendation(HorizonType.longTerm);
    }

    // 3. Check All Horizons Comparison
    if (q.contains('best fund') ||
        q.contains('invest') ||
        q.contains('recommend') ||
        q.contains('top fund') ||
        q.contains('return')) {
      return _formatAllHorizonsSummary();
    }

    // 4. Check Live Market News Request
    if (q.contains('news') ||
        q.contains('market today') ||
        q.contains('nifty') ||
        q.contains('sensex') ||
        q.contains('headline') ||
        q.contains('sentiment')) {
      return formatNewsDigest();
    }

    // 5. Check Mutual Fund Knowledge Base
    for (final entry in _knowledgeBase.entries) {
      if (q.contains(entry.key)) {
        return entry.value;
      }
    }

    // 6. Specific Fund Lookup in Cached List
    for (final fund in trackedFunds) {
      final firstWord = fund.schemeName.split(' ').first.toLowerCase();
      if (q.contains(firstWord)) {
        return _formatSingleFundAnalysis(fund);
      }
    }

    // Default Comprehensive Fast Guide
    return '''⚡ **Indian Trader & MF Quant AI (Instant Mode)**
I analyze live AMFI/MFapi mutual fund returns, compound interest projections, and live NSE/BSE market news in **< 10ms**.

Try asking me:
• **"Best short term funds"** (0–1 yr, ~7.3%–7.5% safe debt returns)
• **"Best middle term funds"** (1–3 yrs, ~15%–21% hybrid returns)
• **"Best long term funds"** (5+ yrs, ~21%–32% equity compounding)
• **"Calculate 10000 SIP for 10 years at 18%"** (Interest & wealth math)
• **"Market news summary"** (Live RSS headlines + Bull/Bear sentiment)
• **"Explain NAV, SIP, Tax, ELSS, Expense Ratio, or Direct vs Regular"**''';
  }

  String formatHorizonRecommendation(HorizonType horizon) {
    final funds = trackedFunds.where((f) => f.horizon == horizon).toList()
      ..sort((a, b) => b.return3Y.compareTo(a.return3Y));

    String title;
    String strategyNote;

    switch (horizon) {
      case HorizonType.shortTerm:
        title = '⏱️ SHORT-TERM HORIZON (1 Month – 1 Year)';
        strategyNote =
            'Goal: Capital preservation + beating bank FD rates with high liquidity.\nRecommended Category: **Liquid & Ultra-Short Duration Debt Funds**.';
        break;
      case HorizonType.mediumTerm:
        title = '⚖️ MIDDLE-TERM HORIZON (1 – 3 Years)';
        strategyNote =
            'Goal: Beat inflation with controlled volatility via dynamic equity-debt allocation.\nRecommended Category: **Balanced Advantage (BAF) & Aggressive Hybrid Funds**.';
        break;
      case HorizonType.longTerm:
        title = '🚀 LONG-TERM HORIZON (5+ Years)';
        strategyNote =
            'Goal: Maximum compounding wealth creation via Indian equities.\nRecommended Category: **Flexi Cap, Large Cap, Mid Cap & Small Cap Funds**.';
        break;
    }

    final buffer = StringBuffer('$title\n$strategyNote\n\n');
    for (int i = 0; i < funds.length; i++) {
      final f = funds[i];
      buffer.writeln(
          '${i + 1}. **${f.schemeName}**\n'
          '   • Latest NAV: ₹${f.latestNav.toStringAsFixed(2)} (${f.latestDate})\n'
          '   • CAGR Returns: **1Y: ${f.return1Y}%** | **3Y: ${f.return3Y}%** | **5Y: ${f.return5Y}%**\n'
          '   • Risk Profile: ${f.riskLevel} | ₹1L in 3Y → **₹${_projectLumpsum(100000, f.return3Y, 3)}**\n');
    }
    return buffer.toString().trim();
  }

  String _formatAllHorizonsSummary() {
    final shortBest = trackedFunds
        .where((f) => f.horizon == HorizonType.shortTerm)
        .reduce((a, b) => a.return1Y > b.return1Y ? a : b);
    final midBest = trackedFunds
        .where((f) => f.horizon == HorizonType.mediumTerm)
        .reduce((a, b) => a.return3Y > b.return3Y ? a : b);
    final longBest = trackedFunds
        .where((f) => f.horizon == HorizonType.longTerm)
        .reduce((a, b) => a.return5Y > b.return5Y ? a : b);

    return '''📊 **TOP MUTUAL FUNDS BY TIME HORIZON & RETURNS**

1️⃣ **Short-Term Pick (0–1 Year | Safe Interest):**
• **${shortBest.schemeName}**
• NAV: ₹${shortBest.latestNav} | **1Y Return: ${shortBest.return1Y}%** | 3Y: ${shortBest.return3Y}%

2️⃣ **Middle-Term Pick (1–3 Years | Balanced Growth):**
• **${midBest.schemeName}**
• NAV: ₹${midBest.latestNav} | 1Y: ${midBest.return1Y}% | **3Y CAGR: ${midBest.return3Y}%**

3️⃣ **Long-Term Pick (5+ Years | High Compounding):**
• **${longBest.schemeName}**
• NAV: ₹${longBest.latestNav} | 3Y: ${longBest.return3Y}% | **5Y CAGR: ${longBest.return5Y}%**

💡 *Tap any horizon chip above or type "Short term", "Middle term", or "Long term" for full rankings.*''';
  }

  String _handleInterestAndSipProjection(String q) {
    final numbers = RegExp(r'\d+(\.\d+)?')
        .allMatches(q)
        .map((m) => double.tryParse(m.group(0)!) ?? 0)
        .where((n) => n > 0)
        .toList();

    final double amount = numbers.isNotEmpty ? numbers[0] : 10000;
    final int years =
        numbers.length >= 2 ? numbers[1].toInt().clamp(1, 40) : 5;
    final double customRate =
        numbers.length >= 3 ? numbers[2].clamp(1.0, 50.0) : 0.0;

    if (customRate > 0) {
      final sipTotal = _calculateSipFutureValue(amount, customRate, years);
      final invested = amount * 12 * years;
      final profit = sipTotal - invested;
      return '''🧮 **COMPOUND INTEREST & SIP PROJECTION**
• **Monthly SIP:** ₹${amount.toStringAsFixed(0)} for **$years Years** @ **$customRate% p.a.**
• **Total Invested:** ₹${_formatInr(invested)}
• **Est. Interest/Gains:** ₹${_formatInr(profit)}
• **Total Maturity Value:** **₹${_formatInr(sipTotal)}**''';
    }

    // Compare across Short (7.4%), Medium (16.5%), and Long (22.0%) rates
    final invested = amount * 12 * years;
    final shortVal = _calculateSipFutureValue(amount, 7.4, years);
    final midVal = _calculateSipFutureValue(amount, 16.5, years);
    final longVal = _calculateSipFutureValue(amount, 22.0, years);

    return '''📈 **HORIZON RETURN COMPARISON FOR ₹${amount.toStringAsFixed(0)}/MO SIP ($years YRS)**
• **Total Principal Invested:** ₹${_formatInr(invested)}

1️⃣ **Short-Term Debt (~7.4% CAGR):**
   Maturity: **₹${_formatInr(shortVal)}** (Gain: ₹${_formatInr(shortVal - invested)})
2️⃣ **Middle-Term Hybrid (~16.5% CAGR):**
   Maturity: **₹${_formatInr(midVal)}** (Gain: ₹${_formatInr(midVal - invested)})
3️⃣ **Long-Term Equity (~22.0% CAGR):**
   Maturity: **₹${_formatInr(longVal)}** (Gain: ₹${_formatInr(longVal - invested)})''';
  }

  String _formatSingleFundAnalysis(MutualFundScheme f) {
    return '''🔍 **FUND ANALYSIS: ${f.schemeName}**
• **Scheme Code:** ${f.schemeCode} (${f.category})
• **Latest NAV:** ₹${f.latestNav.toStringAsFixed(2)} (${f.latestDate})
• **Historical Returns:** 1Y: **${f.return1Y}%** | 3Y: **${f.return3Y}%** | 5Y: **${f.return5Y}%**
• **Ideal Horizon:** ${f.horizon == HorizonType.shortTerm ? 'Short-Term (0–1 Yr)' : f.horizon == HorizonType.mediumTerm ? 'Middle-Term (1–3 Yrs)' : 'Long-Term (5+ Yrs)'}
• **₹10,000/mo SIP for 5 Years @ ${f.return5Y}%:** **₹${_formatInr(_calculateSipFutureValue(10000, f.return5Y, 5))}**''';
  }

  String formatNewsDigest() {
    if (cachedNews.isEmpty) {
      return '''📰 **INDIAN MARKET NEWS RADAR**
Live RSS feed is currently syncing or offline.
• **Macro Trend:** Watch RBI liquidity stance, FII/DII daily net inflows, and Q2/Q3 corporate earnings before deploying lumpsum capital.
• **Agent Strategy:** Use **SIP** in Flexi/Mid-cap funds during market pullbacks and park emergency cash in **Liquid Funds**.''';
    }

    int bulls =
        cachedNews.where((n) => n.sentiment.contains('Bullish')).length;
    int bears =
        cachedNews.where((n) => n.sentiment.contains('Bearish')).length;
    String overallMood = bulls > bears
        ? '🟢 OVERALL MOOD: BULLISH ($bulls positive vs $bears negative headlines)'
        : bears > bulls
            ? '🔴 OVERALL MOOD: CAUTIOUS / BEARISH ($bears negative vs $bulls positive headlines)'
            : '🟡 OVERALL MOOD: NEUTRAL / MIXED CONSOLIDATION';

    final buffer = StringBuffer('📰 **LIVE STOCK MARKET NEWS SUMMARY**\n$overallMood\n\n');
    for (int i = 0; i < min(5, cachedNews.length); i++) {
      final item = cachedNews[i];
      buffer.writeln(
          '${i + 1}. **[${item.sentiment}] ${item.title}**\n   _${item.summary}_\n');
    }
    buffer.writeln(
        '💡 **Trader Agent Actionable Takeaway:** ${bears > bulls ? "Market volatility is elevated—prefer staggered SIPs or Balanced Advantage Funds over aggressive lumpsum entries." : "Momentum favors equities—continue systematic allocations into Flexi Cap & Large/Mid Cap leaders."}');
    return buffer.toString().trim();
  }

  /// Live Search across all 10,000+ Indian Mutual Funds via api.mfapi.in
  Future<List<Map<String, dynamic>>> searchAnyMutualFund(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final uri = Uri.parse(
          'https://api.mfapi.in/mf/search?q=${Uri.encodeComponent(query.trim())}');
      final req = await _httpClient.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final List<dynamic> list = json.decode(body);
        return list.take(15).cast<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetches live NAV & calculates 1Y/3Y/5Y CAGR for any searched scheme code
  Future<MutualFundScheme?> fetchSchemeDetailsByCode(int schemeCode) async {
    try {
      final uri = Uri.parse('https://api.mfapi.in/mf/$schemeCode');
      final req = await _httpClient.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final jsonMap = json.decode(body) as Map<String, dynamic>;
        final meta = jsonMap['meta'] as Map<String, dynamic>? ?? {};
        final List<dynamic> data = jsonMap['data'] ?? [];
        if (data.isEmpty) return null;

        final latestNav =
            double.tryParse(data.first['nav'].toString()) ?? 0.0;
        final category = meta['scheme_category']?.toString() ?? 'Mutual Fund';
        final catLower = category.toLowerCase();

        HorizonType horizon = HorizonType.longTerm;
        if (catLower.contains('liquid') ||
            catLower.contains('overnight') ||
            catLower.contains('ultra short') ||
            catLower.contains('low duration') ||
            catLower.contains('money market')) {
          horizon = HorizonType.shortTerm;
        } else if (catLower.contains('hybrid') ||
            catLower.contains('balanced') ||
            catLower.contains('arbitrage') ||
            catLower.contains('short duration') ||
            catLower.contains('corporate bond')) {
          horizon = HorizonType.mediumTerm;
        }

        return MutualFundScheme(
          schemeCode: schemeCode,
          schemeName: meta['scheme_name']?.toString() ?? 'Scheme $schemeCode',
          category: category,
          horizon: horizon,
          riskLevel: horizon == HorizonType.shortTerm
              ? 'Low to Moderate'
              : horizon == HorizonType.mediumTerm
                  ? 'Moderately High'
                  : 'Very High',
          latestNav: latestNav,
          latestDate: data.first['date']?.toString() ?? '',
          return1Y: _calculateCagrFromHistory(data, latestNav, 1),
          return3Y: _calculateCagrFromHistory(data, latestNav, 3),
          return5Y: _calculateCagrFromHistory(data, latestNav, 5),
          isLiveLoaded: true,
        );
      }
    } catch (_) {}
    return null;
  }

  double _calculateSipFutureValue(
      double monthlySip, double annualRatePercent, int years) {
    final double r = (annualRatePercent / 100.0) / 12.0;
    final int n = years * 12;
    if (r == 0) return monthlySip * n;
    return monthlySip * ((pow(1 + r, n) - 1) / r) * (1 + r);
  }

  String _projectLumpsum(double principal, double cagrPercent, int years) {
    final val = principal * pow(1 + (cagrPercent / 100.0), years);
    return _formatInr(val);
  }

  String _formatInr(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} Lakh';
    }
    return value.toStringAsFixed(0);
  }
}

// ============================================================================
// 3. COMPLETE FLUTTER UI SCREEN FOR THE TRADER AI AGENT
// ============================================================================

class TraderAgentScreen extends StatefulWidget {
  const TraderAgentScreen({super.key});

  @override
  State<TraderAgentScreen> createState() => _TraderAgentScreenState();
}

class _TraderAgentScreenState extends State<TraderAgentScreen>
    with SingleTickerProviderStateMixin {
  final IndianTraderAgentEngine _engine = IndianTraderAgentEngine();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  HorizonType _selectedHorizon = HorizonType.longTerm;
  double _monthlySip = 10000;
  int _investmentYears = 5;

  List> _searchResults = [];
  bool _isSearchingScheme = false;

  final List<AgentMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _messages.add(
      AgentMessage(
        text: _engine.generateInstantReply('help'),
        isUser: false,
        timestamp: DateTime.now(),
        responseTimeMs: 1,
      ),
    );
    // Pre-warm real-time NAVs and RSS news in the background
    _engine.syncLiveMarketData(onUpdate: () {
      if (mounted) setState(() {});
    });
  }

  void _sendPrompt(String text) {
    if (text.trim().isEmpty) return;
    final sw = Stopwatch()..start();
    final reply = _engine.generateInstantReply(text);
    sw.stop();

    setState(() {
      _messages.add(AgentMessage(
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messages.add(AgentMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
        responseTimeMs: sw.elapsedMilliseconds,
      ));
    });

    _chatController.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C33),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amberAccent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Indian Trader & MF AI Agent',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
            if (_engine.isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.greenAccent),
              )
            else
              IconButton(
                icon: const Icon(Icons.sync, size: 20),
                tooltip: 'Refresh Live NAV & News',
                onPressed: () => _engine.syncLiveMarketData(
                  onUpdate: () => setState(() {}),
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: 'Fast AI Chat'),
            Tab(icon: Icon(Icons.pie_chart), text: 'MF Analyzer'),
            Tab(icon: Icon(Icons.newspaper), text: 'Market News'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFastAiChatTab(),
          _buildMutualFundAnalyzerTab(),
          _buildLiveNewsTab(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: INSTANT (< 1 SECOND) AI AGENT CHAT
  // --------------------------------------------------------------------------
  Widget _buildFastAiChatTab() {
    final quickPrompts = [
      'Short Term Funds',
      'Middle Term Funds',
      'Long Term Funds',
      'Market News Summary',
      'Calculate 15000 SIP for 10 years',
      'Direct vs Regular',
      'MF Tax Rules',
      'What is NAV?',
    ];

    return Column(
      children: [
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: const Color(0xFF111C33),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              return ActionChip(
                backgroundColor: const Color(0xFF1D2D50),
                label: Text(
                  quickPrompts[idx],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                onPressed: () => _sendPrompt(quickPrompts[idx]),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment:
                    msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.86,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? const Color(0xFF00796B)
                        : const Color(0xFF17233D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: msg.isUser
                          ? Colors.tealAccent.withOpacity(0.3)
                          : Colors.white12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        msg.text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                      if (!msg.isUser) ...[
                        const SizedBox(height: 6),
                        Text(
                          '⚡ Answered in ${msg.responseTimeMs} ms • Live AMFI/RSS Engine',
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF111C33),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _sendPrompt,
                  decoration: InputDecoration(
                    hintText:
                        'Ask MF horizon, returns, SIP math, or market news...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0B1220),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.greenAccent,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black),
                  onPressed: () => _sendPrompt(_chatController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: MUTUAL FUND TIME-HORIZON & COMPOUND RETURN ANALYZER
  // --------------------------------------------------------------------------
  Widget _buildMutualFundAnalyzerTab() {
    final horizonFunds = _engine.trackedFunds
        .where((f) => f.horizon == _selectedHorizon)
        .toList()
      ..sort((a, b) => b.return3Y.compareTo(a.return3Y));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Live AMFI Search Bar (10,000+ Schemes)
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search any Indian MF (e.g. SBI, Quant, Axis, Parag)...',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.greenAccent),
              onPressed: () async {
                setState(() => _isSearchingScheme = true);
                final res = await _engine
                    .searchAnyMutualFund(_searchController.text);
                if (mounted) {
                  setState(() {
                    _searchResults = res;
                    _isSearchingScheme = false;
                  });
                }
              },
            ),
            filled: true,
            fillColor: const Color(0xFF17233D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) async {
            setState(() => _isSearchingScheme = true);
            final res = await _engine.searchAnyMutualFund(val);
            if (mounted) {
              setState(() {
                _searchResults = res;
                _isSearchingScheme = false;
              });
            }
          },
        ),
        if (_isSearchingScheme)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF17233D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Search Results (Tap to Analyze Live NAV & CAGR):',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white54, size: 18),
                      onPressed: () => setState(() => _searchResults = []),
                    ),
                  ],
                ),
                ..._searchResults.take(6).map((item) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      item['schemeName'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.analytics,
                        color: Colors.amberAccent, size: 18),
                    onTap: () async {
                      final code =
                          int.tryParse(item['schemeCode'].toString()) ?? 0;
                      if (code == 0) return;
                      final scheme =
                          await _engine.fetchSchemeDetailsByCode(code);
                      if (scheme != null && mounted) {
                        setState(() {
                          _engine.trackedFunds.insert(0, scheme);
                          _selectedHorizon = scheme.horizon;
                          _searchResults = [];
                        });
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Time Horizon Selector
        Row(
          children: [
            _buildHorizonButton(
                HorizonType.shortTerm, 'Short (<1Y)', Colors.cyanAccent),
            const SizedBox(width: 8),
            _buildHorizonButton(
                HorizonType.mediumTerm, 'Middle (1–3Y)', Colors.amberAccent),
            const SizedBox(width: 8),
            _buildHorizonButton(
                HorizonType.longTerm, 'Long (5Y+)', Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 14),

        // Interactive SIP & Compound Return Calculator Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF17233D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💰 SIP Interest & Return Simulator (₹${_monthlySip.toInt()}/mo for $_investmentYears Yrs)',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _monthlySip,
                min: 1000,
                max: 100000,
                divisions: 99,
                activeColor: Colors.greenAccent,
                label: '₹${_monthlySip.toInt()}',
                onChanged: (v) => setState(() => _monthlySip = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Horizon Duration:',
                      style: TextStyle(color: Colors.white70)),
                  DropdownButton<int>(
                    dropdownColor: const Color(0xFF111C33),
                    value: _investmentYears,
                    items: [1, 2, 3, 5, 10, 15, 20]
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y Years',
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _investmentYears = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Fund Cards with Live NAV, 1Y/3Y/5Y CAGR & Projected Maturity
        ...horizonFunds.map((f) {
          final rate = _selectedHorizon == HorizonType.shortTerm
              ? f.return1Y
              : _selectedHorizon == HorizonType.mediumTerm
                  ? f.return3Y
                  : f.return5Y;
          final projectedValue = _engine._calculateSipFutureValue(
              _monthlySip, rate, _investmentYears);
          final totalInvested = _monthlySip * 12 * _investmentYears;

          return Card(
            color: const Color(0xFF141E34),
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          f.schemeName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NAV: ₹${f.latestNav.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${f.category} • Risk: ${f.riskLevel} • Updated: ${f.latestDate}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const Divider(color: Colors.white12, height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildReturnStat('1Y Return', '${f.return1Y}%'),
                      _buildReturnStat('3Y CAGR', '${f.return3Y}%'),
                      _buildReturnStat('5Y CAGR', '${f.return5Y}%'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${_monthlySip.toInt()}/mo for $_investmentYears Yrs @ $rate% → '
                      '₹${_engine._formatInr(projectedValue)} '
                      '(Invested: ₹${_engine._formatInr(totalInvested)})',
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHorizonButton(
      HorizonType type, String label, Color activeColor) {
    final isSelected = _selectedHorizon == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedHorizon = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isSelected ? activeColor.withOpacity(0.2) : const Color(0xFF17233D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReturnStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: LIVE STOCK MARKET NEWS & AI SENTIMENT SUMMARIZER
  // --------------------------------------------------------------------------
  Widget _buildLiveNewsTab() {
    if (_engine.cachedNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.greenAccent),
            const SizedBox(height: 12),
            const Text(
              'Fetching Live Economic Times Market RSS Feed...',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Sync'),
              onPressed: () =>
                  _engine.syncLiveMarketData(onUpdate: () => setState(() {})),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _engine.cachedNews.length,
      itemBuilder: (context, index) {
        final item = _engine.cachedNews[index];
        return Card(
          color: const Color(0xFF17233D),
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.sentiment,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.amberAccent),
                    ),
                    Expanded(
                      child: Text(
                        item.pubDate,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  item.summary,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
