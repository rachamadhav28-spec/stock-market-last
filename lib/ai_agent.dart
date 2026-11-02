// ============================================================================
// AI TRADER AGENT
// - Mutual fund analysis for short / medium / long horizons (free AMFI NAV
//   data via mfapi.in, cached on the phone so every reply is instant)
// - Market news from free public RSS feeds with simple mood scoring
// - Built-in mutual fund knowledge base and a SIP calculator
// Replies are computed locally from cached data, so they take milliseconds.
// ============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FundHorizon { short, medium, long }

// ---------------------------------------------------------------------------
// Fund universe: popular direct-growth funds per horizon. Each name is looked
// up on mfapi.in at runtime, so scheme codes never go out of date.
// ---------------------------------------------------------------------------
class FundSeed {
  final String query;
  final FundHorizon group;
  const FundSeed(this.query, this.group);
}

const List<FundSeed> _kFundSeeds = [
  // Short term: low-risk debt
  FundSeed('HDFC Liquid Fund', FundHorizon.short),
  FundSeed('ICICI Prudential Liquid Fund', FundHorizon.short),
  FundSeed('SBI Liquid Fund', FundHorizon.short),
  FundSeed('Axis Liquid Fund', FundHorizon.short),
  FundSeed('Nippon India Liquid Fund', FundHorizon.short),
  FundSeed('Aditya Birla Sun Life Liquid Fund', FundHorizon.short),
  FundSeed('HDFC Money Market Fund', FundHorizon.short),
  FundSeed('ICICI Prudential Money Market Fund', FundHorizon.short),
  FundSeed('HDFC Ultra Short Term Fund', FundHorizon.short),
  FundSeed('SBI Magnum Ultra Short Duration Fund', FundHorizon.short),
  FundSeed('Aditya Birla Sun Life Low Duration Fund', FundHorizon.short),
  // Medium term: short-duration debt and hybrid
  FundSeed('HDFC Balanced Advantage Fund', FundHorizon.medium),
  FundSeed('ICICI Prudential Balanced Advantage Fund', FundHorizon.medium),
  FundSeed('SBI Equity Hybrid Fund', FundHorizon.medium),
  FundSeed('ICICI Prudential Equity & Debt Fund', FundHorizon.medium),
  FundSeed('Kotak Equity Hybrid Fund', FundHorizon.medium),
  FundSeed('HDFC Hybrid Equity Fund', FundHorizon.medium),
  FundSeed('HDFC Short Term Debt Fund', FundHorizon.medium),
  FundSeed('ICICI Prudential Corporate Bond Fund', FundHorizon.medium),
  FundSeed('HDFC Corporate Bond Fund', FundHorizon.medium),
  FundSeed('SBI Corporate Bond Fund', FundHorizon.medium),
  FundSeed('Axis Short Term Fund', FundHorizon.medium),
  FundSeed('Kotak Equity Savings Fund', FundHorizon.medium),
  // Long term: equity
  FundSeed('Parag Parikh Flexi Cap Fund', FundHorizon.long),
  FundSeed('UTI Nifty 50 Index Fund', FundHorizon.long),
  FundSeed('HDFC Index Fund Nifty 50 Plan', FundHorizon.long),
  FundSeed('HDFC Flexi Cap Fund', FundHorizon.long),
  FundSeed('SBI Bluechip Fund', FundHorizon.long),
  FundSeed('ICICI Prudential Bluechip Fund', FundHorizon.long),
  FundSeed('Axis Bluechip Fund', FundHorizon.long),
  FundSeed('Mirae Asset Large Cap Fund', FundHorizon.long),
  FundSeed('Nippon India Small Cap Fund', FundHorizon.long),
  FundSeed('SBI Small Cap Fund', FundHorizon.long),
  FundSeed('Axis Small Cap Fund', FundHorizon.long),
  FundSeed('HDFC Mid-Cap Opportunities Fund', FundHorizon.long),
  FundSeed('Kotak Emerging Equity Fund', FundHorizon.long),
  FundSeed('Motilal Oswal Midcap Fund', FundHorizon.long),
  FundSeed('ICICI Prudential Nifty Next 50 Index Fund', FundHorizon.long),
  FundSeed('Axis ELSS Tax Saver Fund', FundHorizon.long),
];

int riskTierFor(String category) {
  final t = category.toLowerCase();
  bool has(List<String> words) => words.any((w) => t.contains(w));
  if (has(['overnight', 'liquid', 'money market'])) return 1;
  if (has([
    'ultra short',
    'low duration',
    'short duration',
    'corporate bond',
    'banking and psu',
    'floater',
    'arbitrage',
    'equity savings',
    'conservative hybrid',
  ])) {
    return 2;
  }
  if (has([
    'gilt',
    'medium duration',
    'dynamic bond',
    'credit risk',
    'balanced advantage',
    'dynamic asset',
    'aggressive hybrid',
    'multi asset',
    'hybrid',
  ])) {
    return 3;
  }
  if (has(['small cap', 'sectoral', 'thematic'])) return 5;
  if (t.contains('large & mid')) return 4;
  if (t.contains('mid cap')) return 5;
  if (t.contains('debt')) return 2;
  return 4;
}

String riskLabel(int tier) {
  switch (tier) {
    case 1:
      return 'Low';
    case 2:
      return 'Low to moderate';
    case 3:
      return 'Moderate';
    case 4:
      return 'Moderately high';
    default:
      return 'High';
  }
}

class _NavPoint {
  final DateTime date;
  final double nav;
  const _NavPoint(this.date, this.nav);
}

class FundMetrics {
  final int code;
  final String name;
  final String category;
  final FundHorizon group;
  final String navDate;
  final double nav;
  final double? ret6m;
  final double? ret1y;
  final double? cagr3y;
  final double? cagr5y;
  final double volatility;
  final int riskTier;

  const FundMetrics({
    required this.code,
    required this.name,
    required this.category,
    required this.group,
    required this.navDate,
    required this.nav,
    required this.ret6m,
    required this.ret1y,
    required this.cagr3y,
    required this.cagr5y,
    required this.volatility,
    required this.riskTier,
  });

  /// The return used to rank this fund for a given horizon.
  double? rankReturn(FundHorizon h) {
    switch (h) {
      case FundHorizon.short:
        return ret1y ?? ret6m;
      case FundHorizon.medium:
        return cagr3y ?? ret1y;
      case FundHorizon.long:
        return cagr5y ?? cagr3y ?? ret1y;
    }
  }

  static String pct(double? v) {
    if (v == null) return '-';
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';
  }

  String returnsLine() {
    final parts = <String>[];
    if (ret1y != null) parts.add('1Y ${pct(ret1y)}');
    if (cagr3y != null) parts.add('3Y ${pct(cagr3y)} a year');
    if (cagr5y != null) parts.add('5Y ${pct(cagr5y)} a year');
    if (parts.isEmpty && ret6m != null) parts.add('6M ${pct(ret6m)}');
    return parts.isEmpty ? 'returns not available' : parts.join(' | ');
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
        'group': group.index,
        'navDate': navDate,
        'nav': nav,
        'ret6m': ret6m,
        'ret1y': ret1y,
        'cagr3y': cagr3y,
        'cagr5y': cagr5y,
        'vol': volatility,
        'tier': riskTier,
      };

  factory FundMetrics.fromJson(Map<String, dynamic> j) => FundMetrics(
        code: (j['code'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        group: FundHorizon.values[(j['group'] as num).toInt()],
        navDate: (j['navDate'] ?? '').toString(),
        nav: (j['nav'] as num).toDouble(),
        ret6m: (j['ret6m'] as num?)?.toDouble(),
        ret1y: (j['ret1y'] as num?)?.toDouble(),
        cagr3y: (j['cagr3y'] as num?)?.toDouble(),
        cagr5y: (j['cagr5y'] as num?)?.toDouble(),
        volatility: (j['vol'] as num?)?.toDouble() ?? 0.0,
        riskTier: (j['tier'] as num?)?.toInt() ?? 4,
      );
}

// ---------------------------------------------------------------------------
// Mutual fund data (mfapi.in = free AMFI NAV data, no key needed)
// ---------------------------------------------------------------------------
class MfService {
  static const String _base = 'https://api.mfapi.in';
  static const Map<String, String> _headers = {'User-Agent': 'PennyTrader/1.0'};

  static DateTime? _parseDmy(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  static Future<int?> _findDirectGrowthCode(String query) async {
    final uri =
        Uri.parse('$_base/mf/search?q=${Uri.encodeQueryComponent(query)}');
    final r =
        await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) return null;
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return null;

    final words = query.toLowerCase().split(' ');
    final needed = words.take(2).toList();
    const bad = ['idcw', 'dividend', 'bonus', 'segregated', 'payout', 'reinvest'];

    for (final item in decoded) {
      if (item is! Map) continue;
      final code = item['schemeCode'];
      if (code is! num) continue;
      final name = (item['schemeName'] ?? '').toString().toLowerCase();
      final okWords = needed.every((w) => name.contains(w));
      final okPlan = name.contains('direct') && name.contains('growth');
      final okBad = !bad.any((b) => name.contains(b));
      if (okWords && okPlan && okBad) return code.toInt();
    }
    return null;
  }

  static double? _periodReturn(List<_NavPoint> s, double years) {
    final last = s.last;
    final target = last.date.subtract(Duration(days: (365.25 * years).round()));
    if (s.first.date.isAfter(target.add(const Duration(days: 10)))) return null;
    _NavPoint? past;
    for (var i = s.length - 1; i >= 0; i--) {
      if (!s[i].date.isAfter(target)) {
        past = s[i];
        break;
      }
    }
    past ??= s.first;
    final ratio = last.nav / past.nav;
    if (years <= 1.01) return (ratio - 1) * 100;
    return (math.pow(ratio, 1 / years).toDouble() - 1) * 100;
  }

  static double _volatility(List<_NavPoint> s) {
    final tail = s.length > 253 ? s.sublist(s.length - 253) : s;
    final rets = <double>[];
    for (var i = 1; i < tail.length; i++) {
      rets.add(math.log(tail[i].nav / tail[i - 1].nav));
    }
    if (rets.length < 5) return 0.0;
    final mean = rets.reduce((a, b) => a + b) / rets.length;
    double sq = 0;
    for (final r in rets) {
      sq += (r - mean) * (r - mean);
    }
    final std = math.sqrt(sq / (rets.length - 1));
    return std * math.sqrt(252) * 100;
  }

  static String _cleanName(String raw) {
    var n = raw;
    final re = RegExp(
        r'\s*-?\s*(Direct Plan|Direct|Growth Option|Growth Plan|Growth)\b',
        caseSensitive: false);
    n = n.replaceAll(re, '');
    n = n.replaceAll(RegExp(r'\s*-\s*$'), '').replaceAll(RegExp(r'\s+'), ' ');
    return n.trim();
  }

  static Future<FundMetrics?> loadFund(FundSeed seed) async {
    final code = await _findDirectGrowthCode(seed.query);
    if (code == null) return null;

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 365 * 5 + 25));
    final f = DateFormat('yyyy-MM-dd');
    final uri = Uri.parse(
        '$_base/mf/$code?startDate=${f.format(start)}&endDate=${f.format(now)}');
    final r =
        await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) return null;

    final decoded = jsonDecode(r.body);
    if (decoded is! Map) return null;
    final rows = decoded['data'];
    if (rows is! List || rows.length < 30) return null;

    final points = <_NavPoint>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final d = _parseDmy((row['date'] ?? '').toString());
      final n = double.tryParse((row['nav'] ?? '').toString());
      if (d == null || n == null || n <= 0) continue;
      points.add(_NavPoint(d, n));
    }
    if (points.length < 30) return null;
    points.sort((a, b) => a.date.compareTo(b.date));

    final meta = decoded['meta'];
    final category =
        meta is Map ? (meta['scheme_category'] ?? '').toString() : '';
    final rawName = meta is Map
        ? (meta['scheme_name'] ?? seed.query).toString()
        : seed.query;

    return FundMetrics(
      code: code,
      name: _cleanName(rawName),
      category: category,
      group: seed.group,
      navDate: DateFormat('dd MMM yyyy').format(points.last.date),
      nav: points.last.nav,
      ret6m: _periodReturn(points, 0.5),
      ret1y: _periodReturn(points, 1),
      cagr3y: _periodReturn(points, 3),
      cagr5y: _periodReturn(points, 5),
      volatility: _volatility(points),
      riskTier: riskTierFor(category),
    );
  }
}

// ---------------------------------------------------------------------------
// Market news (free public RSS) with a simple mood score
// ---------------------------------------------------------------------------
class NewsItem {
  final String title;
  final String source;
  final DateTime? time;
  final int sentiment;
  const NewsItem(this.title, this.source, this.time, this.sentiment);
}

class NewsService {
  static const List<String> _feeds = [
    'https://news.google.com/rss/search?q=Indian+stock+market+Sensex+Nifty+when:2d&hl=en-IN&gl=IN&ceid=IN:en',
    'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
  ];

  static const List<String> _positive = [
    'surge', 'rally', 'gain', 'jump', 'soar', 'record high', 'rise', 'climb',
    'bullish', 'upbeat', 'strong', 'boost', 'profit', 'recovery', 'rebound',
    'higher', 'advance', 'outperform', 'upgrade',
  ];
  static const List<String> _negative = [
    'fall', 'drop', 'slump', 'crash', 'plunge', 'tumble', 'bearish', 'loss',
    'weak', 'selloff', 'sell-off', 'decline', 'fear', 'warn', 'probe', 'fraud',
    'downgrade', 'lower', 'slide', 'cut', 'tank',
  ];

  static int scoreHeadline(String title) {
    final t = title.toLowerCase();
    int s = 0;
    for (final w in _positive) {
      if (t.contains(w)) s++;
    }
    for (final w in _negative) {
      if (t.contains(w)) s--;
    }
    return s.clamp(-2, 2);
  }

  static String _decode(String s) {
    var out = s
        .replaceAll('<![CDATA[', '')
        .replaceAll(']]>', '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '');
      return code == null ? '' : String.fromCharCode(code);
    });
    return out.trim();
  }

  static String? _tag(String block, String tag) {
    final m = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true).firstMatch(block);
    if (m == null) return null;
    return _decode(m.group(1) ?? '');
  }

  static DateTime? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final cleaned = s.replaceAll(RegExp(r'\s*(GMT|UTC|[+-]\d{4})$'), '');
      return DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(cleaned);
    } catch (_) {
      return null;
    }
  }

  static Future<List<NewsItem>> fetch() async {
    final out = <NewsItem>[];
    final seen = <String>{};
    for (final url in _feeds) {
      try {
        final r = await http
            .get(Uri.parse(url), headers: {'User-Agent': 'PennyTrader/1.0'})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final items =
            RegExp(r'<item>(.*?)</item>', dotAll: true).allMatches(r.body);
        for (final m in items) {
          final block = m.group(1) ?? '';
          var title = _tag(block, 'title') ?? '';
          if (title.isEmpty) continue;
          var source = _tag(block, 'source') ?? '';
          final dash = title.lastIndexOf(' - ');
          if (dash > 20 && source.isEmpty) {
            source = title.substring(dash + 3);
            title = title.substring(0, dash);
          } else if (dash > 20 && title.endsWith(source) && source.isNotEmpty) {
            title = title.substring(0, dash);
          }
          if (source.isEmpty) source = 'Economic Times';
          final key = title.toLowerCase();
          final shortKey = key.length > 60 ? key.substring(0, 60) : key;
          if (!seen.add(shortKey)) continue;
          out.add(NewsItem(
              title, source, _parseTime(_tag(block, 'pubDate')), scoreHeadline(title)));
        }
      } catch (_) {
        // A feed that fails is skipped; the others still work.
      }
    }
    out.sort((a, b) {
      final ta = a.time ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.time ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return out.take(14).toList();
  }
}

// ---------------------------------------------------------------------------
// Knowledge base
// ---------------------------------------------------------------------------
class _Kb {
  final List<String> keys;
  final String answer;
  const _Kb(this.keys, this.answer);
}

const List<_Kb> _kKnowledge = [
  _Kb(['sip', 'systematic investment'],
      'SIP (Systematic Investment Plan) means investing a fixed amount every month. It spreads your buying over highs and lows, so you do not need to time the market, and it builds a habit. You can start with small amounts.\n\nTry: "SIP 5000 for 10 years at 12%" and I will calculate an illustration.'),
  _Kb(['lumpsum', 'lump sum', 'one time'],
      'Lumpsum means investing a big amount at once. It can do well if you invest at a good time, but a bad start hurts more. For equity funds, many people split a lumpsum into parts over a few months or use an STP.'),
  _Kb(['nav', 'net asset value'],
      'NAV is the price of one fund unit: (fund assets minus liabilities) divided by units. It is published once a day after the market closes. A low NAV does not mean a fund is cheap, because what matters is the growth rate.'),
  _Kb(['expense ratio', 'expense', 'fees', 'charges'],
      'Expense ratio is the yearly fee, in percent, that the fund takes from your money. Direct plans have lower fees than regular plans. Over 10-20 years even a 1% difference adds up, so for index funds especially, lower is better.'),
  _Kb(['direct', 'regular', 'commission'],
      'Direct plans are bought straight from the fund house with no distributor commission, so the expense ratio is lower and your returns are higher over time. Regular plans include a commission for an agent. Same fund, same portfolio.'),
  _Kb(['growth', 'idcw', 'dividend'],
      'Growth option reinvests all gains, so your money compounds. IDCW (earlier called dividend) pays money out now and the NAV drops by that amount. For long-term wealth building, growth is usually the simpler choice.'),
  _Kb(['exit load', 'exit'],
      'Exit load is a fee if you sell units too soon. Many equity funds charge about 1% if you sell within a year. It differs per fund, so check the fund details before investing.'),
  _Kb(['elss', 'tax saver', 'tax saving', '80c'],
      'ELSS is an equity fund with a 3-year lock-in that can qualify for a tax deduction under the old tax regime. Tax rules change, so check current rules at incometax.gov.in or with a tax advisor before relying on it.'),
  _Kb(['index fund', 'index', 'nifty 50'],
      'An index fund copies an index like Nifty 50. There is no fund manager picking stocks, costs are low, and returns are close to the index minus a small tracking error. A simple, low-cost choice for long-term investing.'),
  _Kb(['etf', 'exchange traded'],
      'An ETF is like an index fund that trades on the stock exchange during the day. You need a demat account to buy it. An index fund is bought through a mutual fund account instead.'),
  _Kb(['large cap', 'mid cap', 'small cap', 'market cap'],
      'By SEBI rules: large cap = the top 100 companies by size, mid cap = companies ranked 101-250, small cap = rank 251 onwards. Large caps are steadier, mid caps grow faster with more swings, and small caps can give high returns but can fall a lot.'),
  _Kb(['debt fund', 'bond', 'debt'],
      'Debt funds lend money by buying bonds. Risks are interest-rate risk (prices fall when rates rise) and credit risk (a borrower fails to pay). They are usually steadier than equity but returns are not guaranteed.'),
  _Kb(['liquid', 'overnight', 'money market', 'parking'],
      'Liquid funds invest in very short-term debt (up to 91 days). They are low risk and good for parking money for days to a few months. Returns are not guaranteed, but swings are small.'),
  _Kb(['hybrid', 'balanced advantage', 'equity savings', 'multi asset'],
      'Hybrid funds mix equity and debt. Aggressive hybrids hold mostly equity, conservative ones mostly debt, and balanced advantage funds shift between them automatically. They suit a 2-4 year horizon with moderate risk.'),
  _Kb(['risk-o-meter', 'riskometer', 'risk o meter', 'risk level'],
      'SEBI\'s Riskometer has six levels: Low, Low to moderate, Moderate, Moderately high, High, Very high. It is shown on every fund and is based on what the fund holds.'),
  _Kb(['cagr', 'compound annual'],
      'CAGR is the steady yearly rate that would turn your starting amount into the ending amount. It smooths out ups and downs so you can compare funds fairly. A 5Y CAGR of 15% means about 15% a year on average.'),
  _Kb(['rolling return', 'rolling'],
      'Rolling returns measure returns over many overlapping periods (for example every 3-year window). They show how steady a fund has been, which is more reliable than one start-to-end number.'),
  _Kb(['volatility', 'standard deviation', 'risk'],
      'Volatility shows how much the price swings, shown here as a yearly percentage. Higher volatility means a bumpier ride. Debt funds are usually below 2%, large cap equity around 10-15%, small caps often above 15%.'),
  _Kb(['diversif', 'overlap', 'how many funds'],
      'Diversification means not putting everything in one place. Mixing equity and debt, and a few funds of different types, is enough. Too many funds often hold the same stocks and just add confusion.'),
  _Kb(['horizon', 'how long', 'which fund for'],
      'Rule of thumb: under 1 year, use liquid, money market or ultra-short funds. For 2-4 years, use short-duration debt or hybrid funds. For 5+ years, equity funds. Equity can fall 20-30% in a year, so never put short-term money there.'),
  _Kb(['kyc', 'pan', 'age', '18', 'minor', 'start investing'],
      'To invest in mutual funds you complete KYC (PAN and Aadhaar). You must be 18 to invest on your own. Under 18, a parent or guardian can invest in your name. After your 18th birthday you can get your own PAN and start.'),
  _Kb(['stp', 'swp', 'systematic transfer', 'systematic withdrawal'],
      'STP moves money gradually from one fund to another (for example liquid to equity). SWP takes out a fixed amount regularly from a fund, which is useful for regular income.'),
  _Kb(['sebi', 'amfi', 'amc', 'who regulates'],
      'SEBI regulates mutual funds. AMFI is the industry body that publishes daily NAVs. An AMC (asset management company, like HDFC or SBI) runs the funds. Your units are held safely and separately from the AMC.'),
  _Kb(['benchmark', 'fund manager', 'alpha'],
      'A benchmark is the index a fund is measured against (for example Nifty 50 TRI). A good active fund beats its benchmark consistently over years, not just in one good year.'),
  _Kb(['tracking error'],
      'Tracking error shows how closely an index fund follows its index. Smaller is better.'),
  _Kb(['tax', 'taxation', 'capital gain'],
      'Tax on fund gains depends on the fund type and how long you hold it. The rules change often, so check current rules at incometax.gov.in or with a tax advisor.'),
  _Kb(['past performance', 'guarantee', 'guaranteed'],
      'Past returns never guarantee future returns. Use them to compare funds, not to predict. No mutual fund return is guaranteed.'),
  _Kb(['emergency fund', 'emergency'],
      'Before investing in equity, keep 6 months of expenses in a liquid fund or savings account. Then you never have to sell equity at a bad time.'),
  _Kb(['crash', 'fall', 'panic', 'market down', 'correction'],
      'Markets fall regularly. For long-term goals, keep your SIP running, because you buy more units when prices are low. Selling in panic locks in the loss. Only money you need within 2-3 years should avoid equity.'),
  _Kb(['mutual fund', 'what is mutual'],
      'A mutual fund pools money from many people and a fund manager invests it in stocks, bonds or both. You own units and the NAV shows their value. It gives you diversification and professional management for a small amount.'),
  _Kb(['stock vs', 'stocks or', 'mutual fund or stock', 'direct stock'],
      'Mutual funds spread your money over many companies and are managed for you. Picking stocks directly can give higher returns but needs research, time and a high tolerance for losses. Beginners usually start with funds.'),
  _Kb(['penny', 'circuit', 'illiquid'],
      'Penny stocks are low-priced and often thinly traded, so prices can jump or freeze at circuit limits and you may not be able to sell. Your app avoids low-volume stocks for this reason. Treat them as high risk.'),
  _Kb(['stop loss', 'stoploss', 'risk reward', 'risk-reward', 'target'],
      'A stop-loss is the price where you exit to limit a loss. Risk-reward 1:2 means the possible gain is twice the possible loss. Your app only gives signals with at least 1:2.'),
  _Kb(['intraday', 'day trading'],
      'Intraday means buying and selling on the same day. It is high risk and most people lose money, so keep to practice trades until you have a proven record.'),
  _Kb(['sector', 'thematic'],
      'Sector and thematic funds invest in one area (banks, tech, energy). They can do very well or very badly, so they are high risk and not a good first fund.'),
];

// ---------------------------------------------------------------------------
// The agent
// ---------------------------------------------------------------------------
class ChatLine {
  final bool fromUser;
  final String text;
  final String? meta;
  const ChatLine(this.fromUser, this.text, {this.meta});
}

class TraderAiAgent extends ChangeNotifier {
  TraderAiAgent({required this.stockSignals});

  /// Lines describing the app's current strong stock signals.
  final List<String> Function() stockSignals;

  final List<ChatLine> messages = [];
  List<FundMetrics> funds = [];
  List<NewsItem> news = [];
  DateTime? newsTime;
  bool fundsLoading = false;
  bool newsLoading = false;
  int fundsDone = 0;
  int riskStyle = 1; // 0 safe, 1 balanced, 2 aggressive
  bool _disposed = false;

  static const String _cacheKey = 'mf_cache_v2';

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setRiskStyle(int v) {
    riskStyle = v;
    _safeNotify();
  }

  String get statusLine {
    final f = fundsLoading
        ? 'Funds: loading $fundsDone/${_kFundSeeds.length}'
        : 'Funds: ${funds.length} loaded';
    final navDate = funds.isEmpty ? '' : ' (NAV ${funds.first.navDate})';
    final n = newsLoading
        ? 'News: loading'
        : 'News: ${news.length} headlines';
    return '$f$navDate  |  $n';
  }

  Future<void> init() async {
    messages.add(ChatLine(false, _helpText(short: true)));
    _safeNotify();
    await _loadCache();
    unawaited(refreshFunds());
    unawaited(refreshNews());
  }

  // ---- data loading -------------------------------------------------------
  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final list = decoded['funds'];
      if (list is! List) return;
      funds = list
          .whereType<Map>()
          .map((e) => FundMetrics.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _safeNotify();
    } catch (_) {
      funds = [];
    }
  }

  Future<bool> _cacheIsFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return false;
      final decoded = jsonDecode(raw);
      final ts = decoded is Map ? decoded['ts'] : null;
      if (ts is! num) return false;
      final age = DateTime.now().millisecondsSinceEpoch - ts.toInt();
      return age < const Duration(hours: 10).inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshFunds({bool force = false}) async {
    if (fundsLoading) return;
    if (!force && funds.isNotEmpty && await _cacheIsFresh()) return;
    fundsLoading = true;
    fundsDone = 0;
    _safeNotify();

    final fresh = <FundMetrics>[];
    const batch = 4;
    for (var i = 0; i < _kFundSeeds.length; i += batch) {
      final end = math.min(i + batch, _kFundSeeds.length);
      final results = await Future.wait(
        _kFundSeeds.sublist(i, end).map((seed) async {
          try {
            return await MfService.loadFund(seed);
          } catch (_) {
            return null;
          }
        }),
      );
      for (final r in results) {
        if (r != null) fresh.add(r);
      }
      fundsDone = end;
      if (fresh.isNotEmpty && funds.isEmpty) {
        funds = List<FundMetrics>.from(fresh);
      }
      _safeNotify();
      if (_disposed) return;
    }

    if (fresh.isNotEmpty) {
      funds = fresh;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _cacheKey,
          jsonEncode({
            'ts': DateTime.now().millisecondsSinceEpoch,
            'funds': fresh.map((f) => f.toJson()).toList(),
          }),
        );
      } catch (_) {}
    }
    fundsLoading = false;
    _safeNotify();
  }

  Future<void> refreshNews() async {
    if (newsLoading) return;
    newsLoading = true;
    _safeNotify();
    try {
      final items = await NewsService.fetch();
      if (items.isNotEmpty) {
        news = items;
        newsTime = DateTime.now();
      }
    } catch (_) {}
    newsLoading = false;
    _safeNotify();
  }

  // ---- chat ---------------------------------------------------------------
  void ask(String text) {
    messages.add(ChatLine(true, text));
    final sw = Stopwatch()..start();
    String reply;
    try {
      reply = _answer(text);
    } catch (_) {
      reply = 'Sorry, something went wrong while answering. Please try again.';
    }
    sw.stop();
    final ms = sw.elapsedMicroseconds / 1000.0;
    messages.add(ChatLine(false, reply,
        meta: 'Replied in ${ms < 1 ? '<1' : ms.toStringAsFixed(0)} ms'));
    _safeNotify();

    // Keep news fresh in the background for next time.
    final stale = newsTime == null ||
        DateTime.now().difference(newsTime!) > const Duration(minutes: 10);
    if (stale) unawaited(refreshNews());
  }

  String _helpText({bool short = false}) {
    const base = 'I am your trading and mutual fund assistant.\n\n'
        'I can:\n'
        '- Pick mutual funds for short, medium or long term (ranked by returns and risk)\n'
        '- Show the latest market news with a mood score\n'
        '- Show strong stock signals from your watchlist\n'
        '- Explain mutual fund terms (SIP, NAV, expense ratio...)\n'
        '- Calculate a SIP, for example: "SIP 5000 for 10 years at 12%"\n\n'
        'Try: "best funds for 5 years" or "market news".';
    if (short) {
      return '$base\n\nFund NAVs are published once a day after the market closes, so "latest" means the most recent daily NAV. For learning only, not investment advice.';
    }
    return base;
  }

  String _answer(String raw) {
    final q = raw.toLowerCase().trim();
    if (q.isEmpty) return _helpText();

    if (RegExp(r'^(hi|hello|hey|namaste|hii)\b').hasMatch(q) ||
        q.contains('help') ||
        q.contains('what can you')) {
      return _helpText();
    }

    final sip = _sipCalc(q);
    if (sip != null) return sip;

    if (RegExp(r'news|headline|market mood|sentiment|happening').hasMatch(q)) {
      return _newsReply();
    }

    final fundWords = q.contains('fund') || q.contains('mutual');
    if (!fundWords &&
        RegExp(r'stock signal|signals|which stock|stocks to buy|watchlist')
            .hasMatch(q)) {
      return _stockReply();
    }

    final isLearn = RegExp(
            r'^(what|explain|define|meaning|difference|why|how|tell me about|is |are |can )')
        .hasMatch(q);
    if (isLearn) {
      final kb = _kbLookup(q);
      if (kb != null) return kb;
    }

    final horizon = _detectHorizon(q);
    final wantsPicks = RegExp(
            r'fund|invest|mutual|returns?|best|top|recommend|suggest|where|put money|save')
        .hasMatch(q);
    if (horizon != null && wantsPicks) {
      return _picksReply(horizon, _detectStyle(q) ?? riskStyle);
    }

    final fund = _findFund(q);
    if (fund != null) return _fundDetail(fund);

    if (RegExp(r'invest|best fund|which fund|top fund|recommend|suggest')
        .hasMatch(q)) {
      return _overview(_detectStyle(q) ?? riskStyle);
    }

    final kb = _kbLookup(q);
    if (kb != null) return kb;

    return 'I did not quite get that. Try one of these:\n'
        '- "Best funds for 5 years"\n'
        '- "Short term funds" or "medium term funds"\n'
        '- "Market news"\n'
        '- "Stock signals"\n'
        '- "What is expense ratio?"\n'
        '- "SIP 5000 for 10 years at 12%"';
  }

  // ---- parsing helpers ----------------------------------------------------
  FundHorizon? _detectHorizon(String q) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*(year|yr|month|mo)').firstMatch(q);
    if (m != null) {
      var n = double.tryParse(m.group(1) ?? '') ?? 0;
      if ((m.group(2) ?? '').startsWith('mo')) n = n / 12;
      if (n <= 1.5) return FundHorizon.short;
      if (n < 5) return FundHorizon.medium;
      return FundHorizon.long;
    }
    if (RegExp(r'short|few months|emergency|parking|park ').hasMatch(q)) {
      return FundHorizon.short;
    }
    if (RegExp(r'medium|middle|mid term|mid-term|intermediate').hasMatch(q)) {
      return FundHorizon.medium;
    }
    if (RegExp(r'long|retire|child|wealth|decade').hasMatch(q)) {
      return FundHorizon.long;
    }
    return null;
  }

  int? _detectStyle(String q) {
    if (RegExp(r'safe|low risk|conservative|stable|no risk').hasMatch(q)) {
      return 0;
    }
    if (RegExp(r'aggressive|high risk|high return|maximum|max return')
        .hasMatch(q)) {
      return 2;
    }
    if (RegExp(r'balanced|moderate').hasMatch(q)) return 1;
    return null;
  }

  String? _kbLookup(String q) {
    int best = 0;
    _Kb? hit;
    for (final e in _kKnowledge) {
      int score = 0;
      for (final k in e.keys) {
        if (q.contains(k)) score += k.length > 4 ? 2 : 1;
      }
      if (score > best) {
        best = score;
        hit = e;
      }
    }
    return best >= 1 ? hit?.answer : null;
  }

  FundMetrics? _findFund(String q) {
    const stop = {
      'fund', 'best', 'invest', 'the', 'for', 'and', 'about', 'tell', 'what',
      'which', 'plan', 'direct', 'growth', 'show', 'give', 'how', 'is', 'me',
      'good', 'return', 'returns',
    };
    final tokens = q
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 3 && !stop.contains(t))
        .toList();
    if (tokens.length < 2) return null;
    FundMetrics? best;
    int bestScore = 0;
    for (final f in funds) {
      final n = f.name.toLowerCase();
      final score = tokens.where((t) => n.contains(t)).length;
      if (score > bestScore) {
        bestScore = score;
        best = f;
      }
    }
    return bestScore >= 2 ? best : null;
  }

  // ---- replies ------------------------------------------------------------
  static String _horizonTitle(FundHorizon h) {
    switch (h) {
      case FundHorizon.short:
        return 'Short term (up to about 1 year)';
      case FundHorizon.medium:
        return 'Medium term (about 2 to 4 years)';
      case FundHorizon.long:
        return 'Long term (5 years or more)';
    }
  }

  static String _horizonAdvice(FundHorizon h) {
    switch (h) {
      case FundHorizon.short:
        return 'For money you need soon, stay in low-risk debt funds. Equity can fall 10-30% in a year, so it does not belong here.';
      case FundHorizon.medium:
        return 'Short-duration debt and hybrid funds balance steady income with some growth. Pure equity is risky over only 2-4 years.';
      case FundHorizon.long:
        return 'With 5+ years you can ride out falls, so equity funds (index, flexi cap, mid and small cap) can grow your money most. Expect bumpy years.';
    }
  }

  static String _styleName(int s) =>
      s == 0 ? 'Safe' : (s == 2 ? 'Aggressive' : 'Balanced');

  List<FundMetrics> _pick(FundHorizon h, int style, int count) {
    final list = funds.where((f) => f.group == h).toList();
    double r(FundMetrics f) => f.rankReturn(h) ?? -999;
    if (style == 0) {
      list.sort((a, b) {
        final c = a.riskTier.compareTo(b.riskTier);
        return c != 0 ? c : r(b).compareTo(r(a));
      });
      return list.take(count).toList();
    }
    if (style == 2) {
      list.sort((a, b) => r(b).compareTo(r(a)));
      return list.take(count).toList();
    }
    final bal = list.where((f) => f.riskTier <= 4).toList();
    final src = bal.isEmpty ? list : bal;
    src.sort((a, b) => r(b).compareTo(r(a)));
    return src.take(count).toList();
  }

  String _loadingNote() {
    if (fundsLoading) {
      return 'Fund data is still loading ($fundsDone of ${_kFundSeeds.length} checked). Ask again in a few seconds.';
    }
    return 'I could not load fund data yet (check your internet). I will retry when you open the app again.';
  }

  String _fundLines(List<FundMetrics> picks) {
    final b = StringBuffer();
    for (var i = 0; i < picks.length; i++) {
      final f = picks[i];
      b.writeln('${i + 1}. ${f.name}');
      b.writeln(
          '   ${f.category.isEmpty ? 'Fund' : f.category} | Risk: ${riskLabel(f.riskTier)}');
      b.writeln('   ${f.returnsLine()} | Volatility ${f.volatility.toStringAsFixed(1)}%');
    }
    return b.toString().trimRight();
  }

  String _picksReply(FundHorizon h, int style) {
    if (funds.isEmpty) return _loadingNote();
    final picks = _pick(h, style, 5);
    if (picks.isEmpty) {
      return 'I have no ${_horizonTitle(h)} funds loaded yet. ${_loadingNote()}';
    }
    final navDate = picks.first.navDate;
    return '${_horizonTitle(h)} - ${_styleName(style)} picks\n\n'
        '${_horizonAdvice(h)}\n\n'
        '${_fundLines(picks)}\n\n'
        'Ranked by ${h == FundHorizon.short ? '1-year' : (h == FundHorizon.medium ? '3-year' : '5-year')} return. Latest NAV date: $navDate. '
        'Past returns do not guarantee future returns. For learning, not investment advice. Pick Safe or Aggressive with the chips below.';
  }

  String _overview(int style) {
    if (funds.isEmpty) return _loadingNote();
    final b = StringBuffer('Top picks by time horizon (${_styleName(style)}):\n');
    for (final h in FundHorizon.values) {
      final picks = _pick(h, style, 2);
      if (picks.isEmpty) continue;
      b.writeln('\n${_horizonTitle(h)}');
      b.writeln(_fundLines(picks));
    }
    b.writeln(
        '\nAsk "short term funds", "medium term funds" or "long term funds" for the full top 5. Not investment advice.');
    return b.toString().trimRight();
  }

  String _fundDetail(FundMetrics f) {
    return '${f.name}\n'
        '${f.category}\n\n'
        'NAV: Rs ${f.nav.toStringAsFixed(2)} (as of ${f.navDate})\n'
        'Returns: ${f.returnsLine()}\n'
        'Risk: ${riskLabel(f.riskTier)} | Volatility ${f.volatility.toStringAsFixed(1)}% a year\n'
        'Best for: ${_horizonTitle(f.group)}\n\n'
        'Past returns do not guarantee future returns. Not investment advice.';
  }

  String _newsReply() {
    if (news.isEmpty) {
      unawaited(refreshNews());
      return newsLoading
          ? 'Fetching the latest market news... ask again in a few seconds.'
          : 'I could not load news right now (check your internet). Trying again.';
    }
    int pos = 0;
    int neg = 0;
    for (final n in news) {
      if (n.sentiment > 0) pos++;
      if (n.sentiment < 0) neg++;
    }
    final mood = pos > neg + 1
        ? 'Positive'
        : (neg > pos + 1 ? 'Negative' : 'Mixed');
    final b = StringBuffer(
        'Market mood from ${news.length} recent headlines: $mood ($pos positive, $neg negative)\n');
    for (final n in news.take(8)) {
      final tag = n.sentiment > 0 ? '[+]' : (n.sentiment < 0 ? '[-]' : '[ ]');
      var age = '';
      if (n.time != null) {
        final d = DateTime.now().toUtc().difference(n.time!);
        if (d.inMinutes < 60) {
          age = ' (${math.max(d.inMinutes, 1)}m ago)';
        } else if (d.inHours < 48) {
          age = ' (${d.inHours}h ago)';
        }
      }
      b.writeln('\n$tag ${n.title}\n    ${n.source}$age');
    }
    b.writeln(
        '\nMood is a simple word-based score, not a prediction. News can move prices fast, so check it before acting on any signal.');
    return b.toString().trimRight();
  }

  String _stockReply() {
    final lines = stockSignals();
    if (lines.isEmpty) {
      return 'No strong BUY or SELL signals in your watchlist right now. The app scans all 94 stocks every 3 minutes during market hours (9:15 to 3:30 IST).';
    }
    return 'Strong signals from your watchlist:\n\n${lines.join('\n')}\n\n'
        'These are practice signals from delayed data. Not investment advice.';
  }

  String? _sipCalc(String q) {
    if (!q.contains('sip') && !q.contains('invest')) return null;
    var rest = q;
    final yearsM =
        RegExp(r'(\d+(?:\.\d+)?)\s*(?:years?|yrs?|y)\b').firstMatch(rest);
    if (yearsM == null) return null;
    final years = double.tryParse(yearsM.group(1) ?? '');
    rest = rest.replaceFirst(yearsM.group(0) ?? '', ' ');
    double rate = 12;
    final rateM = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(rest);
    if (rateM != null) {
      rate = double.tryParse(rateM.group(1) ?? '') ?? 12;
      rest = rest.replaceFirst(rateM.group(0) ?? '', ' ');
    }
    final amtM =
        RegExp(r'(\d+(?:\.\d+)?)\s*(k|lakh|lac|l)?\b').firstMatch(rest);
    if (amtM == null || years == null || years <= 0) return null;
    var amount = double.tryParse(amtM.group(1) ?? '') ?? 0;
    final unit = amtM.group(2);
    if (unit == 'k') amount *= 1000;
    if (unit == 'lakh' || unit == 'lac' || unit == 'l') amount *= 100000;
    if (amount <= 0 || rate <= 0) return null;

    final r = rate / 12 / 100;
    final n = (years * 12).round();
    final fv = amount * ((math.pow(1 + r, n).toDouble() - 1) / r) * (1 + r);
    final invested = amount * n;
    final fmt = NumberFormat.decimalPattern('en_IN');
    return 'SIP illustration\n\n'
        'Monthly SIP: Rs ${fmt.format(amount.round())}\n'
        'Period: ${years.toStringAsFixed(years == years.roundToDouble() ? 0 : 1)} years at ${rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 1)}% a year\n'
        'You invest: Rs ${fmt.format(invested.round())}\n'
        'Estimated value: Rs ${fmt.format(fv.round())}\n'
        'Estimated gain: Rs ${fmt.format((fv - invested).round())}\n\n'
        'This assumes a steady return. Real equity returns go up and down, and are not guaranteed.';
  }
}

// ---------------------------------------------------------------------------
// Chat screen
// ---------------------------------------------------------------------------
class AiAgentTab extends StatefulWidget {
  final TraderAiAgent agent;
  const AiAgentTab({super.key, required this.agent});

  @override
  State<AiAgentTab> createState() => _AiAgentTabState();
}

class _AiAgentTabState extends State<AiAgentTab> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  static const List<String> _quick = [
    'Short term funds',
    'Medium term funds',
    'Long term funds',
    'Market news',
    'Stock signals',
    'What is SIP?',
    'SIP 5000 for 10 years at 12%',
  ];

  @override
  void initState() {
    super.initState();
    _lastCount = widget.agent.messages.length;
    widget.agent.addListener(_onAgent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown(jump: true));
  }

  void _onAgent() {
    if (widget.agent.messages.length != _lastCount) {
      _lastCount = widget.agent.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
    }
  }

  void _scrollDown({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (jump) {
      _scroll.jumpTo(max);
    } else {
      _scroll.animateTo(max,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    widget.agent.removeListener(_onAgent);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    widget.agent.ask(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final botBg = isDark ? const Color(0xFF1A1E26) : const Color(0xFFF5F6F8);
    const userBg = Color(0xFF00A97F);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return ListenableBuilder(
      listenable: widget.agent,
      builder: (context, _) {
        final agent = widget.agent;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      agent.statusLine,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      agent.refreshFunds(force: true);
                      agent.refreshNews();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.refresh, size: 18, color: muted),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: agent.messages.length,
                itemBuilder: (context, i) {
                  final m = agent.messages[i];
                  return Align(
                    alignment:
                        m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.88,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.fromUser ? userBg : botBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            m.text,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: m.fromUser ? Colors.white : null,
                            ),
                          ),
                          if (m.meta != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                m.meta!,
                                style: TextStyle(fontSize: 10, color: muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final entry in const [
                    MapEntry(0, 'Safe'),
                    MapEntry(1, 'Balanced'),
                    MapEntry(2, 'Aggressive'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: agent.riskStyle == entry.key,
                        onSelected: (_) => agent.setRiskStyle(entry.key),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _quick.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ActionChip(
                    label: Text(_quick[i], style: const TextStyle(fontSize: 12)),
                    onPressed: () => _send(_quick[i]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about funds, news or stocks',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF00A97F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
