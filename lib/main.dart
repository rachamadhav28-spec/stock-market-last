import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
  bool _isDarkMode = true; // Fast, high-contrast dark theme by default
  String _language = 'EN'; // 'EN' = English, 'TE' = Telugu

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
      home: Stage2Screen(
        isDarkMode: _isDarkMode,
        language: _language,
        onThemeChanged: _updateTheme,
        onLanguageChanged: _updateLanguage,
      ),
    );
  }
}

// Bilingual Dictionary (English & Telugu)
class AppStrings {
  static String get(String lang, String key) {
    const Map<String, Map<String, String>> dict = {
      'EN': {
        'app_title': 'Penny Trader - Stage 2',
        'market_open': 'NSE Market OPEN (9:15-3:30 IST) • 10s Live Update',
        'market_closed': 'Market CLOSED • Showing Last Session Data',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA',
        'ltp': 'Last Traded Price (NSE)',
        'trade_time': 'Exchange Trade Time (IST)',
        'fetch_time': 'Phone Fetch Time (IST)',
        'chart_line': 'Line Graph',
        'chart_candle': 'Candlestick',
        'no_candles': 'No intraday candles available',
        'settings': 'Settings',
        'theme_title': 'Dark Theme',
        'theme_sub': 'Switch between Dark and Light screen mode',
        'lang_title': 'App & AI Language',
        'lang_sub': 'Choose English or Telugu (తెలుగు)',
        'close': 'Close',
        'verify_title': 'Same-Minute Google Finance Test:',
        'candles_count': '5-Min Intraday Bars Shown:',
      },
      'TE': {
        'app_title': 'పెన్నీ ట్రేడర్ - దశ 2',
        'market_open': 'NSE మార్కెట్ తెరిచి ఉంది (9:15-3:30 IST) • 10s లైవ్',
        'market_closed': 'మార్కెట్ మూసివేయబడింది • చివరి సెషన్ డేటా',
        'delayed_badge': 'PRACTICE ONLY - DELAYED DATA (ఆలస్యమైన డేటా)',
        'ltp': 'చివరి ట్రేడ్ ధర (NSE)',
        'trade_time': 'ఎక్స్ఛేంజ్ ట్రేడ్ సమయం (IST)',
        'fetch_time': 'ఫోన్ సేకరించిన సమయం (IST)',
        'chart_line': 'లైన్ గ్రాఫ్',
        'chart_candle': 'కాండిల్ స్టిక్',
        'no_candles': 'ఇంట్రాడే కాండిల్ డేటా అందుబాటులో లేదు',
        'settings': 'సెట్టింగ్‌లు (Settings)',
        'theme_title': 'డార్క్ థీమ్ (Dark Theme)',
        'theme_sub': 'డార్క్ లేదా లైట్ స్క్రీన్ మోడ్ మార్చండి',
        'lang_title': 'భాష (Language)',
        'lang_sub': 'ఇంగ్లీష్ లేదా తెలుగు ఎంచుకోండి',
        'close': 'మూసివేయి',
        'verify_title': 'గూగుల్ ఫైనాన్స్ ధర తనిఖీ:',
        'candles_count': '5-నిమిషాల కాండిల్స్:',
      },
    };
    return dict[lang]?[key] ?? dict['EN']![key]!;
  }
}

// Single OHLCV Bar for Line & Candlestick Chart
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

class StockQuote {
  final double price;
  final DateTime tradeTimeIst;
  final DateTime fetchTimeIst;
  final int delayMinutes;
  final bool isDelayedOver5Min;
  final List<OhlcvBar> bars;

  StockQuote({
    required this.price,
    required this.tradeTimeIst,
    required this.fetchTimeIst,
    required this.delayMinutes,
    required this.isDelayedOver5Min,
    required this.bars,
  });
}

// Swappable Data Layer Interface
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

    // Parse OHLCV bars for Line & Candlestick Chart
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

    // Keep the most recent 40 bars so candlesticks are clear and readable on a phone screen
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

class Stage2Screen extends StatefulWidget {
  final bool isDarkMode;
  final String language;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const Stage2Screen({
    super.key,
    required this.isDarkMode,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<Stage2Screen> createState() => _Stage2ScreenState();
}

class _Stage2ScreenState extends State<Stage2Screen> {
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
  bool _showCandlestick = true; // Switchable: true = Candlestick, false = Line
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

          // 3. Main Price & Switchable Chart Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14.0),
              child: Card(
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
                                    fontSize: 22, fontWeight: FontWeight.bold),
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

                      // Chart Mode Switch (Line vs Candlestick)
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
                                label: Text(AppStrings.get(lang, 'chart_line'),
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

                      // Chart Box
                      if (selectedStock.isLoading)
                        const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (selectedStock.errorMessage.isNotEmpty)
                        SizedBox(
                          height: 220,
                          child: Center(
                            child: Text(
                              selectedStock.errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else if (quote != null && quote.bars.isNotEmpty)
                        Container(
                          height: 220,
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
                          height: 220,
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
                        const SizedBox(height: 2),
                        Text(
                          '${AppStrings.get(lang, 'fetch_time')}: ${timeFormatter.format(quote.fetchTimeIst)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(),
                      Text(
                        '${AppStrings.get(lang, 'verify_title')} google.com/finance/quote/$googleSymbol',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Fast, zero-animation CustomPainter for Line & Candlestick Charts
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

    // Draw 3 horizontal guide lines + right-side Rupee labels
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
      // Draw Line Graph
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
      // Draw Candlestick Chart
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

        // Draw high-low wick
        final wickPaint = Paint()
          ..color = color
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), wickPaint);

        // Draw open-close body
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
