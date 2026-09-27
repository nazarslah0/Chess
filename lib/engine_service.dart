import 'dart:async';

import 'package:stockfish/stockfish.dart';

/// سطر واحد من MultiPV صادر مباشرة من Stockfish.
/// uciMoves هي النقلات الخام بصيغة UCI مثل:
/// e2e4, e7e5, g1f3, e7e8q
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

  int _requestedDepth = 18;
  int _requestedMultiPv = 3;

  void Function(String status)? onStatus;
  void Function(int multipv, PvLine line)? onInfo;
  void Function(String bestUci)? onBestMove;

  // ------------------------------------------------------------
  // تشغيل المحرك
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

          onStatus?.call(
            '🔴 خطأ في محرك Stockfish: $error',
          );
        },
      );

      void checkState() {
        if (sf.state.value == StockfishState.ready && !ready) {
          ready = true;

          onStatus?.call(
            '🟢 Stockfish جاهز',
          );
        }
      }

      sf.state.addListener(checkState);
      checkState();

      // إعطاء المحرك وقتًا لبدء الـ isolate.
      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      // إرسال UCI احتياطيًا.
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
  // إرسال أمر UCI
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

    // المحرك أصبح جاهزًا.
    if (line == 'readyok') {
      ready = true;

      onStatus?.call(
        '🟢 Stockfish جاهز',
      );

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
      if (!analyzing) {
        return;
      }

      final parts = line.split(RegExp(r'\s+'));

      final bestMove =
          parts.length > 1 ? parts[1] : '';

      analyzing = false;

      onBestMove?.call(bestMove);

      onStatus?.call(
        '🟢 اكتمل التحليل',
      );

      return;
    }
  }

  // ------------------------------------------------------------
  // تحليل info من Stockfish
  // ------------------------------------------------------------

  void _parseInfo(String line) {
    final parts = line.split(RegExp(r'\s+'));

    int? depth;
    int multipv = 1;

    String? scoreType;
    int? scoreValue;

    final List<String> pv = [];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      // depth
      if (part == 'depth' && i + 1 < parts.length) {
        depth = int.tryParse(parts[i + 1]);
      }

      // multipv
      if (part == 'multipv' && i + 1 < parts.length) {
        multipv =
            int.tryParse(parts[i + 1]) ?? 1;
      }

      // score cp / mate
      if (part == 'score' && i + 2 < parts.length) {
        scoreType = parts[i + 1];
        scoreValue =
            int.tryParse(parts[i + 2]);
      }

      // pv
      if (part == 'pv' && i + 1 < parts.length) {
        pv.addAll(
          parts.sublist(i + 1),
        );
        break;
      }
    }

    if (depth == null) {
      return;
    }

    if (scoreType == null ||
        scoreValue == null) {
      return;
    }

    if (pv.isEmpty) {
      return;
    }

    // منع وصول نتيجة من تحليل قديم.
    final currentId = _analysisId;

    if (_activeAnalysisId != currentId) {
      return;
    }

    // معرفة اللاعب الذي عليه الدور من FEN.
    final fenParts =
        _analyzedFen.split(RegExp(r'\s+'));

    final turn =
        fenParts.length > 1
            ? fenParts[1]
            : 'w';

    // Stockfish يعطي score من منظور اللاعب
    // الذي عليه الدور.
    final sign =
        turn == 'w' ? 1 : -1;

    double evalPawns;
    String label;

    // ----------------------------------------------------------
    // Mate
    // ----------------------------------------------------------

    if (scoreType == 'mate') {
      final mateForSideToMove =
          scoreValue * sign > 0;

      if (mateForSideToMove) {
        label =
            'M${scoreValue.abs()}';

        evalPawns = 100.0;
      } else {
        label =
            'M-${scoreValue.abs()}';

        evalPawns = -100.0;
      }
    }

    // ----------------------------------------------------------
    // Centipawn
    // ----------------------------------------------------------

    else if (scoreType == 'cp') {
      final cp =
          scoreValue * sign;

      evalPawns =
          cp / 100.0;

      label =
          '${evalPawns >= 0 ? '+' : ''}'
          '${evalPawns.toStringAsFixed(2)}';
    }

    // أي نوع score غير معروف.
    else {
      return;
    }

    onInfo?.call(
      multipv,
      PvLine(
        depth: depth,
        evalPawns: evalPawns,
        evalLabel: label,
        uciMoves:
            List<String>.unmodifiable(pv),
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

    // رقم تحليل جديد.
    _analysisId++;

    _activeAnalysisId =
        _analysisId;

    _requestedDepth =
        depth.clamp(1, 60);

    _requestedMultiPv =
        multiPv.clamp(1, 10);

    _analyzedFen =
        cleanFen;

    // إيقاف التحليل السابق.
    if (analyzing) {
      _send('stop');
    }

    analyzing = true;

    onStatus?.call(
      '🔵 جاري تحليل الوضعية...',
    );

    // بدء جلسة UCI جديدة.
    _send('ucinewgame');

    // تحديد MultiPV.
    _send(
      'setoption name MultiPV value $_requestedMultiPv',
    );

    // مهم جدًا للوضعيات الخاصة:
    // نرسل FEN كاملًا مباشرة للمحرك.
    _send(
      'position fen $_analyzedFen',
    );

    // بدء البحث.
    _send(
      'go depth $_requestedDepth',
    );
  }

  // ------------------------------------------------------------
  // إيقاف التحليل
  // ------------------------------------------------------------

  void stop() {
    if (!analyzing) {
      return;
    }

    _analysisId++;

    _activeAnalysisId =
        _analysisId;

    _send('stop');

    analyzing = false;

    onStatus?.call(
      '🟡 تم إيقاف التحليل',
    );
  }

  // ------------------------------------------------------------
  // تنظيف المحرك
  // ------------------------------------------------------------

  void dispose() {
    _analysisId++;

    _activeAnalysisId =
        _analysisId;

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
