import 'dart:async';

import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';

/// سطر واحد من MultiPV صادر مباشرة من Stockfish.
class PvLine {
  final int depth;
  final double evalPawns;
  final String evalLabel;
  final List<String> uciMoves;

  const PvLine({
    required this.depth,
    required this.evalPawns,
    required this.evalLabel,
    required this.uciMoves,
  });
}

class EngineService {
  Stockfish? _sf;
  StreamSubscription<String>? _sub;

  bool ready = false;
  bool analyzing = false;

  String _analyzedFen = '';

  int _analysisId = 0;
  int _activeAnalysisId = 0;

  bool _waitingForReady = false;

  int _requestedDepth = 18;
  int _requestedMultiPv = 3;

  void Function(String status)? onStatus;
  void Function(int multipv, PvLine line)? onInfo;
  void Function(String bestUci)? onBestMove;

  // ------------------------------------------------------------
  // تشغيل Stockfish
  // ------------------------------------------------------------

  Future<void> init() async {
    onStatus?.call('🟡 جاري تشغيل Stockfish...');

    try {
      final sf = Stockfish();

      _sf = sf;

      _sub = sf.stdout.listen(
        _handleLine,
        onError: (error) {
          ready = false;
          analyzing = false;
          onStatus?.call('🔴 خطأ في محرك Stockfish: $error');
        },
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      _send('uci');
    } catch (e) {
      ready = false;
      analyzing = false;

      onStatus?.call(
        '🔴 فشل تشغيل Stockfish: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // إرسال أمر إلى Stockfish
  // ------------------------------------------------------------

  void _send(String command) {
    final sf = _sf;

    if (sf == null) {
      return;
    }

    try {
      sf.stdin = command;
    } catch (e) {
      onStatus?.call(
        '🔴 فشل إرسال أمر للمحرك: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // استقبال UCI
  // ------------------------------------------------------------

  void _handleLine(String raw) {
    final line = raw.trim();

    if (line.isEmpty) {
      return;
    }

    // بداية بروتوكول UCI
    if (line == 'uciok') {
      _send('isready');
      return;
    }

    // Stockfish أصبح جاهزًا.
    if (line == 'readyok') {
      ready = true;

      onStatus?.call(
        '🟢 Stockfish جاهز',
      );

      // إذا كان لدينا تحليل ينتظر الجاهزية،
      // نبدأه الآن من الـFEN الصحيح.
      if (_waitingForReady) {
        _waitingForReady = false;

        _send(
          'setoption name MultiPV value $_requestedMultiPv',
        );

        _send(
          'position fen $_analyzedFen',
        );

        _send(
          'go depth $_requestedDepth',
        );

        onStatus?.call(
          '🔵 جاري تحليل الوضعية...',
        );
      }

      return;
    }

    // معلومات التحليل.
    if (line.startsWith('info')) {
      if (!analyzing) {
        return;
      }

      _parseInfo(line);
      return;
    }

    // أفضل نقلة.
    if (line.startsWith('bestmove')) {
      // إذا كنا ننتظر readyok فلا نسمح لـbestmove
      // قديم بإلغاء التحليل الجديد.
      if (_waitingForReady) {
        return;
      }

      if (!analyzing) {
        return;
      }

      final parts = line.split(RegExp(r'\s+'));

      final bestMove =
          parts.length > 1 ? parts[1] : '';

      analyzing = false;

      onBestMove?.call(bestMove);

      return;
    }
  }

  // ------------------------------------------------------------
  // تحليل info
  // ------------------------------------------------------------

  void _parseInfo(String line) {
    final parts = line.split(RegExp(r'\s+'));

    int? depth;
    int multipv = 1;

    String? scoreType;
    int? scoreVal;

    final List<String> pv = [];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (part == 'depth' && i + 1 < parts.length) {
        depth = int.tryParse(parts[i + 1]);
      }

      if (part == 'multipv' && i + 1 < parts.length) {
        multipv =
            int.tryParse(parts[i + 1]) ?? 1;
      }

      if (part == 'score' && i + 2 < parts.length) {
        scoreType = parts[i + 1];
        scoreVal =
            int.tryParse(parts[i + 2]);
      }

      if (part == 'pv') {
        if (i + 1 < parts.length) {
          pv.addAll(
            parts.sublist(i + 1),
          );
        }

        break;
      }
    }

    if (depth == null) {
      return;
    }

    if (scoreType == null || scoreVal == null) {
      return;
    }

    if (pv.isEmpty) {
      return;
    }

    final fenParts =
        _analyzedFen.split(RegExp(r'\s+'));

    final turn =
        fenParts.length > 1
            ? fenParts[1]
            : 'w';

    final sign =
        turn == 'w' ? 1 : -1;

    double evalPawns;
    String label;

    if (scoreType == 'mate') {
      final mateForSideToMove =
          scoreVal * sign > 0;

      if (mateForSideToMove) {
        label =
            'M${scoreVal.abs()}';
        evalPawns = 100.0;
      } else {
        label =
            'M-${scoreVal.abs()}';
        evalPawns = -100.0;
      }
    } else {
      final cp =
          scoreVal * sign;

      evalPawns =
          cp / 100.0;

      label =
          '${evalPawns >= 0 ? '+' : ''}'
          '${evalPawns.toStringAsFixed(2)}';
    }

    // منع إرسال نتيجة من تحليل قديم.
    if (_activeAnalysisId != _analysisId) {
      return;
    }

    onInfo?.call(
      multipv,
      PvLine(
        depth: depth,
        evalPawns: evalPawns,
        evalLabel: label,
        uciMoves: List<String>.unmodifiable(pv),
      ),
    );
  }

  // ------------------------------------------------------------
  // بدء تحليل FEN
  // ------------------------------------------------------------

  void analyze(
    String fen, {
    required int depth,
    required int multiPv,
  }) {
    final cleanFen = fen.trim();

    if (cleanFen.isEmpty) {
      onStatus?.call(
        '🔴 FEN فارغ',
      );
      return;
    }

    if (!ready) {
      onStatus?.call(
        '🟡 Stockfish لم يصبح جاهزًا بعد',
      );
      return;
    }

    // رقم جديد للتحليل.
    _analysisId++;
    _activeAnalysisId = _analysisId;

    _requestedDepth = depth.clamp(1, 60);
    _requestedMultiPv =
        multiPv.clamp(1, 10);

    _analyzedFen = cleanFen;

    // إذا كان هناك تحليل سابق، أوقفه أولًا.
    if (analyzing) {
      _send('stop');
    }

    analyzing = true;

    // مهم جدًا عند تحليل FEN خاص:
    // نبدأ لعبة UCI جديدة حتى لا يحتفظ Stockfish
    // بحالة البحث السابقة.
    _send('ucinewgame');

    // انتظر readyok قبل position/go.
    _waitingForReady = true;

    _send('isready');
  }

  // ------------------------------------------------------------
  // إيقاف التحليل
  // ------------------------------------------------------------

  void stop() {
    if (!analyzing) {
      return;
    }

    _analysisId++;
    _activeAnalysisId = _analysisId;

    _waitingForReady = false;

    _send('stop');

    analyzing = false;

    onStatus?.call(
      '🟡 تم إيقاف التحليل',
    );
  }

  // ------------------------------------------------------------
  // تنظيف
  // ------------------------------------------------------------

  void dispose() {
    _analysisId++;
    _activeAnalysisId = _analysisId;

    _waitingForReady = false;
    analyzing = false;
    ready = false;

    _sub?.cancel();
    _sub = null;

    try {
      _sf?.dispose();
    } catch (_) {}

    _sf = null;
  }
}
import 'dart:async';
import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';

/// One MultiPV line reported by the real Stockfish engine (never fabricated).
class PvLine {
  final int depth;
  final double evalPawns;
  final String evalLabel;
  final List<String> uciMoves; // raw UCI moves, e.g. e2e4, e7e8q
  const PvLine({
    required this.depth,
    required this.evalPawns,
    required this.evalLabel,
    required this.uciMoves,
  });
}

class EngineService {
  Stockfish? _sf;
  StreamSubscription<String>? _sub;
  bool ready = false;
  bool analyzing = false;
  String _analyzedFen = '';

  void Function(String status)? onStatus;
  void Function(int multipv, PvLine line)? onInfo;
  void Function(String bestUci)? onBestMove;

  Future<void> init() async {
    onStatus?.call('🟡 جاري تشغيل Stockfish...');
    try {
      _sf = Stockfish();
      _sub = _sf!.stdout.listen(_handleLine);
      // Give the native isolate a moment to spin up before the handshake.
      await Future.delayed(const Duration(milliseconds: 400));
      _send('uci');
    } catch (e) {
      onStatus?.call('🔴 فشل تشغيل Stockfish: $e');
    }
  }

  void _send(String cmd) {
    _sf?.stdin = cmd;
  }

  void _handleLine(String raw) {
    final line = raw.trim();
    if (line == 'uciok') {
      _send('isready');
      return;
    }
    if (line == 'readyok') {
      ready = true;
      onStatus?.call('🟢 Stockfish جاهز (Stockfish 17، NNUE حقيقي)');
      return;
    }
    if (line.startsWith('info') && analyzing) {
      _parseInfo(line);
      return;
    }
    if (line.startsWith('bestmove')) {
      if (!analyzing) return;
      analyzing = false;
      final parts = line.split(' ');
      onBestMove?.call(parts.length > 1 ? parts[1] : '');
      return;
    }
  }

  void _parseInfo(String line) {
    final parts = line.split(' ');
    int? depth;
    int multipv = 1;
    String? scoreType;
    int? scoreVal;
    List<String> pv = [];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == 'depth') depth = int.tryParse(parts[i + 1]);
      if (parts[i] == 'multipv') multipv = int.tryParse(parts[i + 1]) ?? 1;
      if (parts[i] == 'score') {
        scoreType = parts[i + 1];
        scoreVal = int.tryParse(parts[i + 2]);
      }
      if (parts[i] == 'pv') {
        pv = parts.sublist(i + 1);
        break;
      }
    }
    if (depth == null || pv.isEmpty || scoreVal == null) return;
    final fenParts = _analyzedFen.split(' ');
    final turn = fenParts.length > 1 ? fenParts[1] : 'w';
    final sign = turn == 'w' ? 1 : -1;
    double evalPawns;
    String label;
    if (scoreType == 'mate') {
      final favor = scoreVal * sign > 0;
      label = favor ? 'M${scoreVal.abs()}' : 'M-${scoreVal.abs()}';
      evalPawns = favor ? 100 : -100;
    } else {
      final cp = scoreVal * sign;
      evalPawns = cp / 100;
      label = (evalPawns >= 0 ? '+' : '') + evalPawns.toStringAsFixed(2);
    }
    onInfo?.call(
      multipv,
      PvLine(depth: depth, evalPawns: evalPawns, evalLabel: label, uciMoves: pv),
    );
  }

  /// depth has NO fixed ceiling of 30: caller may pass up to [maxDepth]
  /// (the UI exposes a slider from 1 to 60).
  void analyze(String fen, {required int depth, required int multiPv}) {
    if (!ready) return;
    analyzing = true;
    _analyzedFen = fen;
    _send('setoption name MultiPV value $multiPv');
    _send('position fen $fen');
    _send('go depth $depth');
  }

  void stop() {
    if (analyzing) _send('stop');
  }

  void dispose() {
    _sub?.cancel();
    _sf?.dispose();
  }
}
