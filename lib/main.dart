import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import 'models.dart';
import 'engine_service.dart';
import 'board_widget.dart';
import 'panels.dart';

void main() => runApp(const ChessAnalyzerApp());

class ChessAnalyzerApp extends StatelessWidget {
  const ChessAnalyzerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محلل وضعيات الشطرنج',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Directionality(textDirection: TextDirection.rtl, child: const HomeScreen()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameState state = GameState();
  final EngineService engine = EngineService();

  int boardThemeIdx = 0;
  int pieceThemeIdx = 0;

  String engineStatus = '🟡 جاري تشغيل Stockfish...';
  bool engineReady = false;
  int depth = 18;
  int multiPv = 3;
  final Map<int, PvLineDisplay> pvLines = {};
  String? _analysisFen;
  String? _lastKnownFen;

  String? selectedSetupPiece;
  bool eraseMode = false;
  Set<String> targets = {};

  final fenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    state.addListener(_onStateChanged);
    engine.onStatus = (s) => setState(() {
          engineStatus = s;
          engineReady = s.startsWith('🟢');
        });
    engine.onInfo = (mpv, raw) {
      if (_analysisFen != state.currentFen) return; // stale: board changed mid-search
      final display = _convertPv(_analysisFen!, raw);
      setState(() => pvLines[mpv] = display);
    };
    engine.onBestMove = (uci) {
      // bestmove marks completion; nothing further to compute here.
    };
    engine.init();
  }

  void _onStateChanged() {
    final fen = state.currentFen;
    if (fen != _lastKnownFen) {
      _lastKnownFen = fen;
      if (engine.analyzing) engine.stop();
      setState(() {
        pvLines.clear();
        _analysisFen = null;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    state.removeListener(_onStateChanged);
    engine.dispose();
    super.dispose();
  }

  PvLineDisplay _convertPv(String fen, PvLine raw) {
    final c = ch.Chess();
    c.load(fen);
    final sans = <String>[];
    for (final uci in raw.uciMoves) {
      if (uci.length < 4) break;
      final from = uci.substring(0, 2);
      final to = uci.substring(2, 4);
      final promo = uci.length > 4 ? uci.substring(4, 5) : null;
      int legalCount = 0;
      try {
        legalCount = (c.moves() as List).length;
      } catch (_) {}
      final args = <String, dynamic>{'from': from, 'to': to};
      if (promo != null) args['promotion'] = promo;
      final res = c.move(args);
      if (res == null || res == false) break;
      String san = '$from$to';
      try {
        final hist = c.getHistory({'verbose': false}) as List;
        if (hist.isNotEmpty) san = hist.last.toString();
      } catch (_) {}
      sans.add(legalCount == 1 ? '$san (إجبارية)' : san);
      if (sans.length >= 8) break;
    }
    final first = raw.uciMoves.isNotEmpty ? raw.uciMoves.first : '';
    return PvLineDisplay(
      depth: raw.depth,
      evalLabel: raw.evalLabel,
      moves: sans,
      bestFrom: first.length >= 2 ? first.substring(0, 2) : '',
      bestTo: first.length >= 4 ? first.substring(2, 4) : '',
    );
  }

  void _analyze() {
    _analysisFen = state.currentFen;
    setState(() => pvLines.clear());
    engine.analyze(_analysisFen!, depth: depth, multiPv: multiPv);
  }

  Future<String?> _askPromotion() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر قطعة الترقية'),
        content: Wrap(
          spacing: 8,
          children: [
            for (final p in ['q', 'r', 'b', 'n'])
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, p),
                child: Text({'q': 'وزير', 'r': 'رخ', 'b': 'فيل', 'n': 'حصان'}[p]!),
              ),
          ],
        ),
      ),
    );
  }

  void _onBoardTap(String sq) async {
    if (state.mode == 'setup') {
      if (eraseMode) {
        state.eraseSetupSquare(sq);
        return;
      }
      if (selectedSetupPiece != null) {
        state.placeSetupPiece(sq, selectedSetupPiece!);
        return;
      }
      state.tapSetupSelect(sq == state.selectedSquare ? null : sq);
      return;
    }
    // play mode
    if (state.selectedSquare == null) {
      final board = GameState.parseBoard(state.currentFen.split(' ')[0]);
      final piece = board[sq];
      final turn = state.currentFen.split(' ')[1];
      if (piece != null && piece.startsWith(turn)) {
        state.tapSetupSelect(sq);
        setState(() => targets = state.legalTargets(sq).toSet());
      }
      return;
    }
    if (sq == state.selectedSquare) {
      state.tapSetupSelect(null);
      setState(() => targets = {});
      return;
    }
    if (!targets.contains(sq)) {
      final board = GameState.parseBoard(state.currentFen.split(' ')[0]);
      final piece = board[sq];
      final turn = state.currentFen.split(' ')[1];
      if (piece != null && piece.startsWith(turn)) {
        state.tapSetupSelect(sq);
        setState(() => targets = state.legalTargets(sq).toSet());
      } else {
        state.tapSetupSelect(null);
        setState(() => targets = {});
      }
      return;
    }
    final from = state.selectedSquare!;
    final board = GameState.parseBoard(state.currentFen.split(' ')[0]);
    final movingPiece = board[from];
    final isPromo = movingPiece != null &&
        movingPiece.substring(1) == 'P' &&
        ((movingPiece.startsWith('w') && sq.endsWith('8')) ||
            (movingPiece.startsWith('b') && sq.endsWith('1')));
    setState(() => targets = {});
    if (isPromo) {
      final promo = await _askPromotion();
      state.tryMove(from, sq, promotion: promo ?? 'q');
    } else {
      state.tryMove(from, sq);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bTheme = boardThemes[boardThemeIdx];
    final pTheme = pieceThemes[pieceThemeIdx];
    final top = pvLines[1];

    return Scaffold(
      appBar: AppBar(title: const Text('محلل وضعيات الشطرنج ♟️')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'ثيم الرقعة'),
                      value: boardThemeIdx,
                      items: [
                        for (int i = 0; i < boardThemes.length; i++)
                          DropdownMenuItem(value: i, child: Text(boardThemes[i].name)),
                      ],
                      onChanged: (v) => setState(() => boardThemeIdx = v ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'ثيم القطع'),
                      value: pieceThemeIdx,
                      items: [
                        for (int i = 0; i < pieceThemes.length; i++)
                          DropdownMenuItem(value: i, child: Text(pieceThemes[i].name)),
                      ],
                      onChanged: (v) => setState(() => pieceThemeIdx = v ?? 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: BoardWidget(
                  state: state,
                  boardTheme: bTheme,
                  pieceTheme: pTheme,
                  onTap: _onBoardTap,
                  targets: targets,
                  arrowFrom: top?.bestFrom.isNotEmpty == true ? top!.bestFrom : null,
                  arrowTo: top?.bestTo.isNotEmpty == true ? top!.bestTo : null,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      state.enterPlayModeFromSetup();
                    },
                    child: const Text('وضع اللعب'),
                  ),
                  OutlinedButton(
                    onPressed: () => state.enterSetupModeFromCurrent(),
                    child: const Text('إعداد الوضعية'),
                  ),
                  OutlinedButton(onPressed: () => state.flipBoard(), child: const Text('قلب الرقعة')),
                  OutlinedButton(
                      onPressed: () => state.startPosition(), child: const Text('الوضعية الابتدائية')),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => state.clearBoardForSetup(),
                    child: const Text('مسح الرقعة'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.mode == 'setup')
                SetupPanel(
                  state: state,
                  pieceTheme: pTheme,
                  selectedPiece: selectedSetupPiece,
                  eraseMode: eraseMode,
                  onSelectPiece: (p) => setState(() {
                    selectedSetupPiece = p;
                    eraseMode = false;
                  }),
                  onToggleErase: () => setState(() {
                    eraseMode = !eraseMode;
                    selectedSetupPiece = null;
                  }),
                  onChanged: () {},
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FEN', style: TextStyle(fontWeight: FontWeight.bold)),
                      SelectableText(state.currentFen,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: fenController,
                        decoration: InputDecoration(
                          labelText: 'الصق FEN هنا',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              if (!state.loadFen(fenController.text)) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('FEN غير صالح')));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              MoveListPanel(history: state.history),
              const SizedBox(height: 12),
              AnalysisPanel(
                engineStatus: engineStatus,
                engineReady: engineReady,
                analyzing: engine.analyzing,
                depth: depth,
                multiPv: multiPv,
                lines: pvLines,
                onAnalyze: _analyze,
                onStop: () => engine.stop(),
                onDepthChanged: (d) => setState(() => depth = d),
                onMultiPvChanged: (m) => setState(() => multiPv = m),
                onSelectLine: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
