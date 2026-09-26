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
