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

  Future<void> _updateApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    setState(() {
      _geminiApiKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penny Trader - Stage 3',
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
        onThemeChanged: _updateTheme,
        onLanguageChanged: _updateLanguage,
        onApiKeyChanged: _updateApiKey,
      ),
    );
  }
}

class AppStrings {
  static String get(String lang, String key) {
    const Map<String, Map<String, String>> dict = {
      'EN': {
        'app_title': 'Penny Trader - Stage 3 (AI Signal)',
        'market_open': 'NSE Market OPEN (9:15-3:30 IST) • 10s Live Update',
        'market_closed': 'Market CLOSED • Showing Last Session Data',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'Last Traded Price (NSE)',
        'trade_time': 'Exchange Trade Time (IST)',
        'fetch_time': 'Phone Fetch Time (IST)',
        'chart_line': 'Line Graph',
        'chart_candle': 'Candlestick',
        'no_candles': 'No intraday candles available',
        'settings': 'Settings & AI Key',
        'theme_title': 'Dark Theme',
        'theme_sub': 'Switch between Dark and Light screen mode',
        'lang_title': 'App & AI Language',
        'lang_sub': 'Choose English or Telugu (తెలుగు)',
        'key_title': 'Gemini API Key (Google AI Studio)',
        'key_sub': 'Type or paste your free key here securely',
        'key_hint': 'AI Studio API Key (Never saved in GitHub)',
        'close': 'Close',
        'verify_title': 'Same-Minute Google Finance Test:',
        'candles_count': '5-Min Intraday Bars Shown:',
        'get_ai_signal': 'Generate AI Intraday Signal',
        'analyzing': 'AI Analyst is evaluating technicals & risk...',
        'enter_key_prompt': 'Please enter your Gemini API Key in Settings (Gear Icon) to generate AI signals.',
      },
      'TE': {
        'app_title': 'పెన్నీ ట్రేడర్ - దశ 3 (AI సిగ్నల్)',
        'market_open': 'NSE మార్కెట్ తెరిచి ఉంది (9:15-3:30 IST) • 10s లైవ్',
        'market_closed': 'మార్కెట్ మూసివేయబడింది • చివరి సెషన్ డేటా',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA (ఆలస్యమైన డేటా)',
        'ltp': 'చివరి ట్రేడ్ ధర (NSE)',
        'trade_time': 'ఎక్స్ఛేంజ్ ట్రేడ్ సమయం (IST)',
        'fetch_time': 'ఫోన్ సేకరించిన సమయం (IST)',
        'chart_line': 'లైన్ గ్రాఫ్',
        'chart_candle': 'కాండిల్ స్టిక్',
        'no_candles': 'ఇంట్రాడే కాండిల్ డేటా అందుబాటులో లేదు',
        'settings': 'సెట్టింగ్‌లు & AI కీ',
        'theme_title': 'డార్క్ థీమ్ (Dark Theme)',
        'theme_sub': 'డార్క్ లేదా లైట్ స్క్రీన్ మోడ్ మార్చండి',
        'lang_title': 'భాష (Language)',
        'lang_sub': 'ఇంగ్లీష్ లేదా తెలుగు ఎంచుకోండి',
        'key_title': 'Gemini API కీ',
        'key_sub': 'మీ ఉచిత కీని ఇక్కడ నమోదు చేయండి',
        'key_hint': 'AI స్టూడియో API కీ',
        'close': 'మూసివేయి',
        'verify_title': 'గూగుల్ ఫైనాన్స్ ధర తనిఖీ:',
        'candles_count': '5-నిమిషాల కాండిల్స్:',
        'get_ai_signal': 'AI సిగ్నల్ సృష్టించండి',
        'analyzing': 'AI విశ్లేషిస్తోంది...',
        'enter_key_prompt': 'దయచేసి సెట్టింగ్స్‌లో మీ Gemini API కీని నమోదు చేయండి.',
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

class AiSignalCard {
  final String action; // BUY, SELL, WAIT, AVOID
  final String confidence; // Low, Medium, High
  final String reasonLine;
  final String entryPrice;
  final String shares;
  final String stopLoss;
  final String target;
  final String squareOffNote;
  final String techReason;
  final String fundReason;
  final String newsReason;
  final String invalidation;
  final String dataGaps;

  AiSignalCard({
    required this.action,
    required this.confidence,
    required this.reasonLine,
    required this.entryPrice,
    required this.shares,
    required this.stopLoss,
    required this.target,
    required this.squareOffNote,
    required this.techReason,
    required this.fundReason,
    required this.newsReason,
    required this.invalidation,
    required this.dataGaps,
  });
}

class StockQuote {
  final double price;
  final DateTime tradeTimeIst;
  final DateTime fetchTimeIst;
  final int delayMinutes;
  final bool isDelayedOver5Min;
  final List<OhlcvBar> bars;
  AiSignalCard? signalCard;
  bool isAiLoading;
  String aiError;

  StockQuote({
    required this.price,
    required this.tradeTimeIst,
    required this.fetchTimeIst,
    required this.delayMinutes,
    required this.isDelayedOver5Min,
    required this.bars,
    this.signalCard,
    this.isAiLoading = false,
    this.aiError = '',
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
          final barTime = DateTime.fromMillisecondsSinceEpoch(
                  (timestamps[i] as int) * 1000,
                  isUtc: true)
              .add(const Duration(hours: 5, minutes: 30));
          parsedBars.add(
            OhlcvBar(
              timeIst: barTime,
              open: (o as num).toDouble(),
              high: (h as num).toDouble(),
              low: (l as num).toDouble(),
              close: (c as num).toDouble(),
              volume: (volumes?[i] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
    }

    final recentBars = parsedBars.length > 40
        ? parsedBars.sublist(parsedBars.length - 40)
        : parsedBars;

    return StockQuote(
      price: currentPrice,
      tradeTimeIst: tradeTimeIst,
      fetchTimeIst: nowIst,
      delayMinutes: diffMinutes < 0 ? 0 : diffMinutes,
      isDelayedOver5Min: diffMinutes > 5,
      bars: recentBars,
    );
  }
}

class StockItem {
  final String symbol;
  final String name;
  StockQuote? quote;
  bool isLoading;
  String errorMessage;

  StockItem({
    required this.symbol,
    required this.name,
    this.quote,
    this.isLoading = true,
    this.errorMessage = '',
  });
}

class Stage3Screen extends StatefulWidget {
  final bool isDarkMode;
  final String language;
  final String geminiApiKey;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onApiKeyChanged;

  const Stage3Screen({
    super.key,
    required this.isDarkMode,
    required this.language,
    required this.geminiApiKey,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onApiKeyChanged,
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

  Future<void> _generateAiSignal(StockItem stock) async {
    final quote = stock.quote;
    if (quote == null) return;

    if (widget.geminiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.get(widget.language, 'enter_key_prompt'))),
      );
      return;
    }

    setState(() {
      quote.isAiLoading = true;
      quote.aiError = '';
    });

    try {
      // Build summary of recent bars for Gemini
      final barsSummary = quote.bars
          .map((b) =>
              "O:${b.open} H:${b.high} L:${b.low} C:${b.close} Vol:${b.volume}")
          .join("\n");

      final prompt = """
You are a disciplined intraday analyst for Indian penny stocks (NSE/BSE).
LANGUAGE: ${widget.language == 'TE' ? 'Telugu (తెలుగు script where natural, keep symbols, numbers, and BUY/SELL/WAIT/AVOID in English)' : 'English'}.
INPUT DATA:
Symbol: ${stock.symbol} (${stock.name})
Price: Rs ${quote.price}
Delay minutes: ${quote.delayMinutes}
Recent OHLCV Bars:
$barsSummary

RULES:
- Max loss Rs 100 per trade.
- Minimum 1:2 risk-reward or AVOID.
- Return ONLY valid JSON format with these exact keys:
{
  "action": "BUY" or "SELL" or "WAIT" or "AVOID",
  "confidence": "Low" or "Medium" or "High",
  "reason_line": "one line summary",
  "entry_price": "Rs X.XX",
  "shares": "X shares (for Rs 100 max loss)",
  "stop_loss": "Rs X.XX",
  "target": "Rs X.XX",
  "square_off": "square off before 3:25 PM IST",
  "tech": "technical reason",
  "fund": "fundamental reason",
  "news": "news reason",
  "invalidation": "what proves this wrong",
  "data_gaps": "any missing data"
}
""";

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${widget.geminiApiKey}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean markdown code blocks if Gemini returns ```json ... ```
        final cleanedJson = rawText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final parsedMap = jsonDecode(cleanedJson);

        final card = AiSignalCard(
          action: parsedMap['action'] ?? 'WAIT',
          confidence: parsedMap['confidence'] ?? 'Low',
          reasonLine: parsedMap['reason_line'] ?? '',
          entryPrice: parsedMap['entry_price'] ?? '',
          shares: parsedMap['shares'] ?? '',
          stopLoss: parsedMap['stop_loss'] ?? '',
          target: parsedMap['target'] ?? '',
          squareOffNote: parsedMap['square_off'] ?? '',
          techReason: parsedMap['tech'] ?? '',
          fundReason: parsedMap['fund'] ?? '',
          newsReason: parsedMap['news'] ?? '',
          invalidation: parsedMap['invalidation'] ?? '',
          dataGaps: parsedMap['data_gaps'] ?? '',
        );

        setState(() {
          quote.signalCard = card;
          quote.isAiLoading = false;
        });
      } else {
        setState(() {
          quote.aiError = 'AI API Error: ${response.statusCode}';
          quote.isAiLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        quote.aiError = 'Failed to generate signal ($e)';
        quote.isAiLoading = false;
      });
    }
  }

  void _openSettingsSheet() {
    final keyController = TextEditingController(text: widget.geminiApiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final lang = widget.language;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(lang, 'settings'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(AppStrings.get(lang, 'theme_title')),
                    subtitle: Text(AppStrings.get(lang, 'theme_sub')),
                    value: widget.isDarkMode,
                    onChanged: (val) {
                      widget.onThemeChanged(val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(lang, 'key_title'),
                      hintText: AppStrings.get(lang, 'key_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      widget.onApiKeyChanged(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppStrings.get(lang, 'close')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
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

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final selectedStock = _stocks[_selectedIndex];
    final quote = selectedStock.quote;
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  // Stock Price & Chart Card
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 12),
                          if (selectedStock.isLoading)
                            const SizedBox(
                              height: 180,
                              child:
                                  Center(child: CircularProgressIndicator()),
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
                              height: 180,
                              child: Center(
                                child: Text(AppStrings.get(lang, 'no_candles')),
                              ),
                            ),
                          const SizedBox(height: 14),
                          if (quote != null) ...[
                            Text(
                              '${AppStrings.get(lang, 'trade_time')}: ${timeFormatter.format(quote.tradeTimeIst)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // AI Signal Trigger & Action Card
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: quote != null && quote.isAiLoading
                          ? null
                          : () => _generateAiSignal(selectedStock),
                      icon: const Icon(Icons.psychology),
                      label: Text(
                        AppStrings.get(lang, 'get_ai_signal'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (quote != null && quote.isAiLoading)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(AppStrings.get(lang, 'analyzing')),
                          ],
                        ),
                      ),
                    )
                  else if (quote != null && quote.aiError.isNotEmpty)
                    Card(
                      color: Colors.red.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          quote.aiError,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else if (quote != null && quote.signalCard != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: _getActionColor(quote.signalCard!.action),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getActionColor(
                                        quote.signalCard!.action),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    quote.signalCard!.action,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Confidence: ${quote.signalCard!.confidence}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              quote.signalCard!.reasonLine,
                              style: const TextStyle(
                                  fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                            const Divider(height: 20),
                            if (quote.signalCard!.action == 'BUY' ||
                                quote.signalCard!.action == 'SELL') ...[
                              Text('Entry Price: ${quote.signalCard!.entryPrice}'),
                              Text('Max Loss Shares: ${quote.signalCard!.shares}'),
                              Text('Stop-Loss: ${quote.signalCard!.stopLoss}'),
                              Text('Target: ${quote.signalCard!.target}'),
                              Text(quote.signalCard!.squareOffNote,
                                  style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold)),
                              const Divider(height: 20),
                            ],
                            Text('Technical: ${quote.signalCard!.techReason}'),
                            Text('Fundamental: ${quote.signalCard!.fundReason}'),
                            Text('News: ${quote.signalCard!.newsReason}'),
                            const SizedBox(height: 8),
                            Text(
                                'Invalidation: ${quote.signalCard!.invalidation}',
                                style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 12),
                            const Text(
                              'Educational analysis, not financial advice. Paper trading only.',
                              style: TextStyle(
                                  fontSize: 10, fontStyle: FontStyle.italic),
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
