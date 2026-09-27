import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;

/// ---------- Themes ----------

class BoardTheme {
  final String name;
  final Color light;
  final Color dark;
  final Color lastMove;
  final Color checkColor;
  final Color selected;
  final Color target;
  final Color border;

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
  final Color whiteFill;
  final Color whiteStroke;
  final Color blackFill;
  final Color blackStroke;
  final String? assetFolder;

  const PieceTheme({
    required this.name,
    required this.whiteFill,
    required this.whiteStroke,
    required this.blackFill,
    required this.blackStroke,
    this.assetFolder,
  });

  String assetPath(
    String colorLetter,
    String typeLetter,
  ) {
    return 'assets/pieces/$assetFolder/'
        '$colorLetter$typeLetter.png';
  }
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
  BoardTheme(
    name: 'أخضر (المجموعة المرفقة)',
    light: Color(0xFFFFF2D4),
    dark: Color(0xFF8CC936),
    lastMove: Color(0x55FFD54A),
    checkColor: Color(0xFFDC2626),
    selected: Color(0x552563EB),
    target: Color(0x552563EB),
    border: Color(0xFF2E3B25),
  ),
  BoardTheme(
    name: 'بني (المجموعة المرفقة)',
    light: Color(0xFFFFF2D4),
    dark: Color(0xFFDE925A),
    lastMove: Color(0x552AA198),
    checkColor: Color(0xFFDC2626),
    selected: Color(0x552563EB),
    target: Color(0x552563EB),
    border: Color(0xFF3A2E22),
  ),
  BoardTheme(
    name: 'أزرق (المجموعة المرفقة)',
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF96DBFF),
    lastMove: Color(0x55FFD54A),
    checkColor: Color(0xFFDC2626),
    selected: Color(0x552563EB),
    target: Color(0x552563EB),
    border: Color(0xFF23303A),
  ),
];

const List<PieceTheme> pieceThemes = [
  PieceTheme(
    name: 'قطع حقيقية — كلاسيكي',
    whiteFill: Color(0xFFFCFCFC),
    whiteStroke: Color(0xFF222222),
    blackFill: Color(0xFF161616),
    blackStroke: Color(0xFFEAEAEA),
    assetFolder: 'classic',
  ),
  PieceTheme(
    name: 'قطع حقيقية — مسطح',
    whiteFill: Color(0xFFFCFCFC),
    whiteStroke: Color(0xFF222222),
    blackFill: Color(0xFF161616),
    blackStroke: Color(0xFFEAEAEA),
    assetFolder: 'flat',
  ),
  PieceTheme(
    name: 'قطع حقيقية — خشبي',
    whiteFill: Color(0xFFFCFCFC),
    whiteStroke: Color(0xFF222222),
    blackFill: Color(0xFF161616),
    blackStroke: Color(0xFFEAEAEA),
    assetFolder: 'wood',
  ),
  PieceTheme(
    name: 'مرسومة — كلاسيكي أبيض/أسود',
    whiteFill: Color(0xFFFCFCFC),
    whiteStroke: Color(0xFF222222),
    blackFill: Color(0xFF161616),
    blackStroke: Color(0xFFEAEAEA),
  ),
  PieceTheme(
    name: 'مرسومة — خشبي',
    whiteFill: Color(0xFFF3E1C2),
    whiteStroke: Color(0xFF5C3A21),
    blackFill: Color(0xFF6B4226),
    blackStroke: Color(0xFFF3E1C2),
  ),
  PieceTheme(
    name: 'مرسومة — نيون',
    whiteFill: Color(0xFFB6FFF5),
    whiteStroke: Color(0xFF0891B2),
    blackFill: Color(0xFF7C3AED),
    blackStroke: Color(0xFFE9D5FF),
  ),
  PieceTheme(
    name: 'مرسومة — ذهبي/فضي',
    whiteFill: Color(0xFFE5E7EB),
    whiteStroke: Color(0xFF4B5563),
    blackFill: Color(0xFFB8860B),
    blackStroke: Color(0xFFFFF3CD),
  ),
];

/// ---------- Game state ----------

class MoveEntry {
  final String san;
  final String color;

  const MoveEntry(
    this.san,
    this.color,
  );
}

class GameState extends ChangeNotifier {
  ch.Chess chess = ch.Chess();

  String mode = 'play';

  /// لوحة الإعداد مستقلة عن chess.Chess.
  Map<String, String> setupBoard = {};

  String setupTurn = 'w';

  bool ck = true;
  bool cq = true;
  bool ckb = true;
  bool cqb = true;

  String ep = '-';

  String? lastFrom;
  String? lastTo;
  String? selectedSquare;

  bool flipped = false;

  List<MoveEntry> history = [];

  String legalMessage = 'وضعية قانونية';
  bool legal = true;

  static const files = 'abcdefgh';

  // ------------------------------------------------------------
  // الوضعية الابتدائية
  // ------------------------------------------------------------

  void startPosition() {
    chess = ch.Chess();

    mode = 'play';

    setupBoard = {};
    setupTurn = 'w';

    ck = true;
    cq = true;
    ckb = true;
    cqb = true;

    ep = '-';

    lastFrom = null;
    lastTo = null;
    selectedSquare = null;

    history = [];

    _validate();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // مسح الرقعة وبدء وضع الإعداد
  // ------------------------------------------------------------

  void clearBoardForSetup() {
    setupBoard = {};

    mode = 'setup';

    setupTurn = 'w';

    ck = false;
    cq = false;
    ckb = false;
    cqb = false;

    ep = '-';

    lastFrom = null;
    lastTo = null;
    selectedSquare = null;

    history = [];

    _validate();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // الدخول إلى إعداد الوضعية من الوضع الحالي
  // ------------------------------------------------------------

  void enterSetupModeFromCurrent() {
    final fen = chess.fen;
    final parts = fen.split(RegExp(r'\s+'));

    if (parts.isEmpty) {
      return;
    }

    setupBoard =
        _boardPartToMap(parts[0]);

    setupTurn =
        parts.length > 1 &&
                (parts[1] == 'b')
            ? 'b'
            : 'w';

    final castle =
        parts.length > 2
            ? parts[2]
            : '-';

    ck = castle.contains('K');
    cq = castle.contains('Q');
    ckb = castle.contains('k');
    cqb = castle.contains('q');

    ep = parts.length > 3
        ? parts[3]
        : '-';

    _sanitizeSetupRights();

    mode = 'setup';

    selectedSquare = null;

    _validate();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // العودة من الإعداد إلى اللعب
  // ------------------------------------------------------------

  bool enterPlayModeFromSetup() {
    _sanitizeSetupRights();

    final fen = buildSetupFen();

    final test = ch.Chess();

    try {
      final result = test.load(fen);

      if (result == false) {
        legal = false;
        legalMessage =
            'الوضعية غير صالحة';
        notifyListeners();
        return false;
      }
    } catch (_) {
      legal = false;
      legalMessage =
          'تعذر تحميل الوضعية';
      notifyListeners();
      return false;
    }

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

  // ------------------------------------------------------------
  // تحميل FEN
  // ------------------------------------------------------------

  bool loadFen(String fen) {
    final cleanFen =
        fen.trim();

    if (cleanFen.isEmpty) {
      return false;
    }

    final test = ch.Chess();

    try {
      final result =
          test.load(cleanFen);

      if (result == false) {
        legal = false;
        legalMessage =
            'FEN غير صالح';
        notifyListeners();
        return false;
      }
    } catch (_) {
      legal = false;
      legalMessage =
          'FEN غير صالح';
      notifyListeners();
      return false;
    }

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

  // ------------------------------------------------------------
  // تحويل FEN board إلى Map
  // ------------------------------------------------------------

  static Map<String, String> parseBoard(
    String boardPart,
  ) {
    final map =
        <String, String>{};

    final ranks =
        boardPart.split('/');

    if (ranks.length != 8) {
      return map;
    }

    for (int r = 0; r < 8; r++) {
      int fIdx = 0;

      for (final c
          in ranks[r].split('')) {
        final n =
            int.tryParse(c);

        if (n != null) {
          fIdx += n;
          continue;
        }

        if (fIdx < 0 ||
            fIdx >= 8) {
          continue;
        }

        final color =
            c == c.toUpperCase()
                ? 'w'
                : 'b';

        final type =
            c.toUpperCase();

        final sq =
            files[fIdx] +
                (8 - r).toString();

        map[sq] =
            color + type;

        fIdx++;
      }
    }

    return map;
  }

  Map<String, String>
      _boardPartToMap(
    String boardPart,
  ) {
    return parseBoard(
      boardPart,
    );
  }

  // ------------------------------------------------------------
  // تنظيف حقوق التبييت
  // ------------------------------------------------------------

  void _sanitizeSetupRights() {
    // التبييت الأبيض يحتاج:
    // الملك e
