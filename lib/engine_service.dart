import 'dart:async';
import 'package:stockfish/stockfish.dart';

/// One MultiPV line reported directly by the real on-device Stockfish engine.
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
  StreamSubscription<String>? _stdoutSub;
  Timer? _startupTimer;

  bool ready = false;
  bool analyzing = false;
  String _analyzedFen = '';

  void Function(String status)? onStatus;
  void Function(int multipv, PvLine line)? onInfo;
  void Function(String bestUci)? onBestMove;

  Future<void> init() async {
    if (_sf != null) return;

    ready = false;
    analyzing = false;
    onStatus?.call('🟡 جاري تشغيل Stockfish 18 المضمّن...');

    try {
      final sf = Stockfish();
      _sf = sf;

      _stdoutSub = sf.stdout.listen(
        _handleLine,
        onError: (Object e, StackTrace st) {
          onStatus?.call('🔴 خطأ في Stockfish: $e');
        },
      );

      // The native engine is bundled inside the plugin and starts locally.
      // Give it enough time to initialize, then perform the normal UCI handshake.
      await Future.delayed(const Duration(milliseconds: 250));
      _send('uci');

      _startupTimer?.cancel();
      _startupTimer = Timer(const Duration(seconds: 10), () {
        if (!ready) {
          onStatus?.call('🔴 لم يستجب Stockfish خلال 10 ثوانٍ.');
        }
      });
    } catch (e) {
      onStatus?.call('🔴 فشل تشغيل Stockfish المضمّن: $e');
      await _cleanup();
    }
  }

  void _send(String cmd) {
    final sf = _sf;
    if (sf != null) sf.stdin = cmd;
  }

  void _handleLine(String raw) {
    final line = raw.trim();
    if (line.isEmpty) return;

    if (line == 'uciok') {
      _send('isready');
      return;
    }

    if (line == 'readyok') {
      ready = true;
      _startupTimer?.cancel();
      onStatus?.call('🟢 Stockfish 18 جاهز — محرك NNUE حقيقي مضمّن داخل التطبيق');
      return;
    }

    if (line.startsWith('info') && analyzing) {
      _parseInfo(line);
      return;
    }

    if (line.startsWith('bestmove')) {
      if (!analyzing) return;
      analyzing = false;
      final parts = line.split(RegExp(r'\s+'));
      onBestMove?.call(parts.length > 1 ? parts[1] : '');
    }
  }

  void _parseInfo(String line) {
    final parts = line.split(RegExp(r'\s+'));
    int? depth;
    int multipv = 1;
    String? scoreType;
    int? scoreVal;
    List<String> pv = [];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == 'depth' && i + 1 < parts.length) {
        depth = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'multipv' && i + 1 < parts.length) {
        multipv = int.tryParse(parts[i + 1]) ?? 1;
      } else if (parts[i] == 'score' && i + 2 < parts.length) {
        scoreType = parts[i + 1];
        scoreVal = int.tryParse(parts[i + 2]);
      } else if (parts[i] == 'pv') {
        pv = parts.sublist(i + 1);
        break;
      }
    }

    if (depth == null || pv.isEmpty || scoreVal == null) return;

    final fenParts = _analyzedFen.split(RegExp(r'\s+'));
    final turn = fenParts.length > 1 ? fenParts[1] : 'w';
    final sign = turn == 'w' ? 1 : -1;

    late double evalPawns;
    late String label;

    if (scoreType == 'mate') {
      final signedMate = scoreVal * sign;
      final favor = signedMate > 0;
      label = favor ? 'M${scoreVal.abs()}' : 'M-${scoreVal.abs()}';
      evalPawns = favor ? 100 : -100;
    } else {
      final cp = scoreVal * sign;
      evalPawns = cp / 100.0;
      label = '${evalPawns >= 0 ? '+' : ''}${evalPawns.toStringAsFixed(2)}';
    }

    onInfo?.call(
      multipv,
      PvLine(
        depth: depth,
        evalPawns: evalPawns,
        evalLabel: label,
        uciMoves: pv,
      ),
    );
  }

  void analyze(String fen, {required int depth, required int multiPv}) {
    if (!ready || _sf == null) return;

    if (analyzing) {
      _send('stop');
    }

    analyzing = true;
    _analyzedFen = fen;

    final safeMultiPv = multiPv.clamp(1, 10);
    final safeDepth = depth.clamp(1, 60);

    _send('setoption name MultiPV value $safeMultiPv');
    _send('isready');
    _send('position fen $fen');
    _send('go depth $safeDepth');
  }

  void stop() {
    if (analyzing) {
      _send('stop');
    }
  }

  Future<void> _cleanup() async {
    _startupTimer?.cancel();
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    _sf?.dispose();
    _sf = null;
    ready = false;
    analyzing = false;
  }

  void dispose() {
    _startupTimer?.cancel();
    _stdoutSub?.cancel();
    _sf?.dispose();
    _stdoutSub = null;
    _sf = null;
    ready = false;
    analyzing = false;
  }
}
