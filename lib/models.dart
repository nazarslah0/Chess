import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;

/// ---------- Themes ----------

class BoardTheme {
  final String name;
  final Color light, dark, lastMove, checkColor, selected, target, border;
  const BoardTheme({
    required this.name,
    required this.light,
    required this.dark,
    required this.lastMove,
    required this.checkColor,
    required this.selected,
    required this.target,
    required this.border,
  });
}

class PieceTheme {
  final String name;
  final Color whiteFill, whiteStroke, blackFill, blackStroke;
  const PieceTheme({
    required this.name,
    required this.whiteFill,
    required this.whiteStroke,
    required this.blackFill,
    required this.blackStroke,
  });
}

const List<BoardTheme> boardThemes = [
  BoardTheme(
    name: 'كلاسيكي',
    light: Color(0xFFF0D9B5),
    dark: Color(0xFFB58863),
    lastMove: Color(0x552AA198),
    checkColor: Color(0xFFDC2626),
    selected: Color(0x552563EB),
    target: Color(0x552563EB),
    border: Color(0xFF3A2E22),
  ),
  BoardTheme(
    name: 'أخضر',
    light: Color(0xFFEEEED2),
    dark: Color(0xFF769656),
    lastMove: Color(0x55F6F669),
    checkColor: Color(0xFFDC2626),
    selected: Color(0x552563EB),
    target: Color(0x552563EB),
    border: Color(0xFF2E3B25),
  ),
  BoardTheme(
    name: 'أزرق',
    light: Color(0xFFDEE3E6),
    dark: Color(0xFF6E8CA0),
    lastMove: Color(0x55FFD54A),
    checkColor: Color(0xFFDC2626),
    selected: Color(0x552563EB),
    target: Color(0x552563EB),
    border: Color(0xFF23303A),
  ),
  BoardTheme(
    name: 'داكن',
    light: Color(0xFF4A4A4A),
    dark: Color(0xFF262626),
    lastMove: Color(0x556EE7B7),
    checkColor: Color(0xFFEF4444),
    selected: Color(0x554F86F7),
    target: Color(0x554F86F7),
    border: Color(0xFF141414),
  ),
  BoardTheme(
    name: 'رخامي',
    light: Color(0xFFEDEAE0),
    dark: Color(0xFF8C7B6B),
    lastMove: Color(0x55C9A25E),
    checkColor: Color(0xFFB3261E),
    selected: Color(0x556750A4),
    target: Color(0x556750A4),
    border: Color(0xFF463B30),
  ),
];

const List<PieceTheme> pieceThemes = [
  PieceTheme(
    name: 'كلاسيكي أبيض/أسود',
    whiteFill: Color(0xFFFCFCFC),
    whiteStroke: Color(0xFF222222),
    blackFill: Color(0xFF161616),
    blackStroke: Color(0xFFEAEAEA),
  ),
  PieceTheme(
    name: 'خشبي',
    whiteFill: Color(0xFFF3E1C2),
    whiteStroke: Color(0xFF5C3A21),
    blackFill: Color(0xFF6B4226),
    blackStroke: Color(0xFFF3E1C2),
  ),
  PieceTheme(
    name: 'نيون',
    whiteFill: Color(0xFFB6FFF5),
    whiteStroke: Color(0xFF0891B2),
    blackFill: Color(0xFF7C3AED),
    blackStroke: Color(0xFFE9D5FF),
  ),
  PieceTheme(
    name: 'ذهبي/فضي',
    whiteFill: Color(0xFFE5E7EB),
    whiteStroke: Color(0xFF4B5563),
    blackFill: Color(0xFFB8860B),
    blackStroke: Color(0xFFFFF3CD),
  ),
];

/// ---------- Game state ----------

class MoveEntry {
  final String san;
  final String color; // 'w' or 'b'
  const MoveEntry(this.san, this.color);
}


class GameState extends ChangeNotifier {
  ch.Chess chess = ch.Chess();
  String mode = 'play'; // 'setup' | 'play'

  // setup-mode board, independent of chess.Chess to avoid any ambiguity
  // about that package's put()/remove()/get() signatures.
  Map<String, String> setupBoard = {}; // e.g. 'e4' -> 'wP'
  String setupTurn = 'w';
  bool ck = true, cq = true, ckb = true, cqb = true;
  String ep = '-';

  String? lastFrom, lastTo, selectedSquare;
  bool flipped = false;

  List<MoveEntry> history = [];
  String legalMessage = 'وضعية قانونية';
  bool legal = true;

  static const files = 'abcdefgh';

  void startPosition() {
    chess = ch.Chess();
    mode = 'play';
    lastFrom = null;
    lastTo = null;
    selectedSquare = null;
    history = [];
    _validate();
    notifyListeners();
  }

  void clearBoardForSetup() {
    setupBoard = {};
    mode = 'setup';
    lastFrom = null;
    lastTo = null;
    selectedSquare = null;
    history = [];
    _validate();
    notifyListeners();
  }

  void enterSetupModeFromCurrent() {
    final parts = chess.fen.split(' ');
    setupBoard = _boardPartToMap(parts[0]);
    setupTurn = parts.length > 1 ? parts[1] : 'w';
    final castle = parts.length > 2 ? parts[2] : '-';
    ck = castle.contains('K');
    cq = castle.contains('Q');
    ckb = castle.contains('k');
    cqb = castle.contains('q');
    ep = (parts.length > 3 && parts[3] != '-') ? parts[3] : '-';
    mode = 'setup';
    selectedSquare = null;
    _validate();
    notifyListeners();
  }

  bool enterPlayModeFromSetup() {
    final fen = buildSetupFen();
    final test = ch.Chess();
    final ok = test.load(fen);
    if (ok != false) {
      chess = test;
      mode = 'play';
      lastFrom = null;
      lastTo = null;
      selectedSquare = null;
      history = [];
      _validate();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool loadFen(String fen) {
    final test = ch.Chess();
    final ok = test.load(fen.trim());
    if (ok != false) {
      chess = test;
      mode = 'play';
      lastFrom = null;
      lastTo = null;
      selectedSquare = null;
      history = [];
      _validate();
      notifyListeners();
      return true;
    }
    return false;
  }

  static Map<String, String> parseBoard(String boardPart) {
    final map = <String, String>{};
    final ranks = boardPart.split('/');
    for (int r = 0; r < 8; r++) {
      int fIdx = 0;
      for (final c in ranks[r].split('')) {
        final n = int.tryParse(c);
        if (n != null) {
          fIdx += n;
        } else {
          final color = c == c.toUpperCase() ? 'w' : 'b';
          final type = c.toUpperCase();
          final sq = files[fIdx] + (8 - r).toString();
          map[sq] = color + type;
          fIdx += 1;
        }
      }
    }
    return map;
  }

  Map<String, String> _boardPartToMap(String boardPart) => parseBoard(boardPart);

  String buildSetupFen() {
    final rows = <String>[];
    for (int rank = 8; rank >= 1; rank--) {
      String row = '';
      int empty = 0;
      for (int f = 0; f < 8; f++) {
        final sq = files[f] + rank.toString();
        final piece = setupBoard[sq];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            row += empty.toString();
            empty = 0;
          }
          final letter = piece.substring(1, 2);
          row += piece.startsWith('w') ? letter : letter.toLowerCase();
        }
      }
      if (empty > 0) row += empty.toString();
      rows.add(row);
    }
    String castle = '';
    if (ck) castle += 'K';
    if (cq) castle += 'Q';
    if (ckb) castle += 'k';
    if (cqb) castle += 'q';
    if (castle.isEmpty) castle = '-';
    return '${rows.join('/')} $setupTurn $castle $ep 0 1';
  }

  String get currentFen => mode == 'setup' ? buildSetupFen() : chess.fen;

  void placeSetupPiece(String square, String colorType) {
    setupBoard[square] = colorType;
    _validate();
    notifyListeners();
  }

  void eraseSetupSquare(String square) {
    setupBoard.remove(square);
    _validate();
    notifyListeners();
  }

  void tapSetupSelect(String? square) {
    selectedSquare = square;
    notifyListeners();
  }

  /// Returns list of legal destination squares for [from], using only the
  /// documented move()/undo() API to stay robust against Move-object shape.
  List<String> legalTargets(String from) {
    final targets = <String>[];
    for (final rf in files.split('')) {
      for (int rr = 1; rr <= 8; rr++) {
        final to = '$rf$rr';
        if (to == from) continue;
        final res = chess.move({'from': from, 'to': to, 'promotion': 'q'});
        if (res != null && res != false) {
          chess.undo();
          targets.add(to);
        }
      }
    }
    return targets;
  }

  /// Attempts to play from->to (with optional promotion). Returns the SAN
  /// string on success, or null if illegal.
  String? tryMove(String from, String to, {String? promotion}) {
    final mover = chess.fen.split(' ')[1];
    final args = <String, dynamic>{'from': from, 'to': to};
    if (promotion != null) args['promotion'] = promotion;
    final res = chess.move(args);
    if (res == null || res == false) return null;
    // chess.move() may return a bool or a Move-like object depending on
    // package version; derive SAN safely from the move history instead.
    String san;
    try {
      final hist = chess.getHistory({'verbose': false}) as List;
      san = hist.isNotEmpty ? hist.last.toString() : '$from$to';
    } catch (_) {
      san = '$from$to';
    }
    lastFrom = from;
    lastTo = to;
    selectedSquare = null;
    history.add(MoveEntry(san, mover));
    _validate();
    notifyListeners();
    return san;
  }

  void _validate() {
    if (mode == 'setup') {
      final test = ch.Chess();
      final ok = test.load(buildSetupFen());
      legal = ok != false;
      legalMessage = legal ? 'وضعية قانونية' : 'الوضعية غير قانونية';
    } else {
      legal = true;
      try {
        if (chess.in_checkmate == true) {
          legalMessage = 'كش مات';
        } else if (chess.in_stalemate == true) {
          legalMessage = 'تعادل (تجميد)';
        } else if (chess.in_check == true) {
          legalMessage = 'كش';
        } else if (chess.in_draw == true) {
          legalMessage = 'تعادل';
        } else {
          legalMessage = 'وضعية قانونية';
        }
      } catch (_) {
        legalMessage = 'وضعية قانونية';
      }
    }
  }

  void flipBoard() {
    flipped = !flipped;
    notifyListeners();
  }

  void refresh() {
    _validate();
    notifyListeners();
  }
}
