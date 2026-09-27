import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'piece_painter.dart';

class BoardWidget extends StatelessWidget {
  final GameState state;
  final BoardTheme boardTheme;
  final PieceTheme pieceTheme;
  final String? arrowFrom;
  final String? arrowTo;
  final Set<String> targets;
  final void Function(String square) onTap;

  const BoardWidget({
    super.key,
    required this.state,
    required this.boardTheme,
    required this.pieceTheme,
    required this.onTap,
    this.arrowFrom,
    this.arrowTo,
    this.targets = const {},
  });

  static const files = 'abcdefgh';

  @override
  Widget build(BuildContext context) {
    final fenParts = state.currentFen.split(' ');
    final boardFen = fenParts.isNotEmpty ? fenParts[0] : '';

    final board = GameState.parseBoard(boardFen);
    final flipped = state.flipped;

    bool isCheckSquare(String sq) {
      if (state.mode != 'play') return false;

      bool inCheck = false;

      try {
        inCheck = state.chess.in_check == true;
      } catch (_) {}

      if (!inCheck) return false;

      final turn = fenParts.length > 1 ? fenParts[1] : 'w';
      final piece = board[sq];

      return piece != null && piece == '${turn}K';
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: boardTheme.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: GridView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                    ),
                    itemCount: 64,
                    itemBuilder: (context, index) {
                      final col = index % 8;
                      final row = index ~/ 8;

                      final f = flipped ? 7 - col : col;
                      final r = flipped ? row : 7 - row;

                      final sq =
                          files[f] + (r + 1).toString();

                      final isDark =
                          (f + r) % 2 != 0;

                      final piece = board[sq];

                      final isLast =
                          sq == state.lastFrom ||
                          sq == state.lastTo;

                      final isSel =
                          sq == state.selectedSquare;

                      final isTarget =
                          targets.contains(sq);

                      final isCheck =
                          isCheckSquare(sq);

                      return GestureDetector(
                        onTap: () => onTap(sq),
                        child: Container(
                          color: isDark
                              ? boardTheme.dark
                              : boardTheme.light,
                          child: Stack(
                            children: [
                              if (isLast)
                                Positioned.fill(
                                  child: Container(
                                    color:
                                        boardTheme.lastMove,
                                  ),
                                ),

                              if (isSel)
                                Positioned.fill(
                                  child: Container(
                                    color:
                                        boardTheme.selected,
                                  ),
                                ),

                              if (isCheck)
                                Positioned.fill(
                                  child: Container(
                                    decoration:
                                        BoxDecoration(
                                      border: Border.all(
                                        color:
                                            boardTheme.checkColor,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),

                              if (piece != null)
                                Positioned.fill(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(4),
                                    child: pieceTheme
                                                .assetFolder !=
                                            null
                                        ? Image.asset(
                                            pieceTheme.assetPath(
                                              piece.substring(
                                                0,
                                                1,
                                              ),
                                              piece.substring(
                                                1,
                                              ),
                                            ),
                                            fit: BoxFit.contain,
                                          )
                                        : CustomPaint(
                                            size: Size.infinite,
                                            painter:
                                                PiecePainter(
                                              piece.substring(1),
                                              piece.substring(0, 1),
                                              pieceTheme,
                                            ),
                                          ),
                                  ),
                                ),

                              if (isTarget)
                                Align(
                                  alignment:
                                      Alignment.center,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          boardTheme.target,
                                      shape:
                                          BoxShape.circle,
                                    ),
                                  ),
                                ),

                              if (col == 0)
                                Positioned(
                                  top: 2,
                                  left: 2,
                                  child: Text(
                                    '${r + 1}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: boardTheme.border
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),

                              if (row == 7)
                                Positioned(
                                  bottom: 1,
                                  right: 3,
                                  child: Text(
                                    files[f],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: boardTheme.border
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // السهم فوق الرقعة
              if (_validSquare(arrowFrom) &&
                  _validSquare(arrowTo) &&
                  arrowFrom != arrowTo)
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _ArrowPainter(
                      arrowFrom!,
                      arrowTo!,
                      flipped,
                      Colors.blueAccent,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static bool _validSquare(String? square) {
    if (square == null || square.length != 2) {
      return false;
    }

    final file = square.codeUnitAt(0);
    final rank = square.codeUnitAt(1);

    return file >= 97 &&
        file <= 104 &&
        rank >= 49 &&
        rank <= 56;
  }
}

class _ArrowPainter extends CustomPainter {
  final String from;
  final String to;
  final bool flipped;
  final Color color;

  _ArrowPainter(
    this.from,
    this.to,
    this.flipped,
    this.color,
  );

  Offset _center(
    String sq,
    double cell,
  ) {
    final f =
        BoardWidget.files.indexOf(sq[0]);

    final r =
        int.parse(sq.substring(1)) - 1;

    if (f < 0 || f > 7 || r < 0 || r > 7) {
      return Offset.zero;
    }

    final col =
        flipped ? 7 - f : f;

    final row =
        flipped ? r : 7 - r;

    return Offset(
      col * cell + cell / 2,
      row * cell + cell / 2,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final cell = size.width / 8;

    final p1 = _center(from, cell);
    final p2 = _center(to, cell);

    final delta = p2 - p1;
    final distance = delta.distance;

    if (distance < 1) {
      return;
    }

    final direction =
        delta / distance;

    final angle =
        math.atan2(
      direction.dy,
      direction.dx,
    );

    // نترك مسافة من القطعة في البداية والنهاية
    // حتى لا يغطي السهم القطع.
    final startPadding =
        cell * 0.22;

    final endPadding =
        cell * 0.30;

    final start =
        p1 + direction * startPadding;

    final end =
        p2 - direction * endPadding;

    // جسم السهم
    final shaft = Paint()
      ..color =
          color.withOpacity(0.82)
      ..strokeWidth =
          cell * 0.12
      ..strokeCap =
          StrokeCap.round
      ..style =
          PaintingStyle.stroke;

    canvas.drawLine(
      start,
      end,
      shaft,
    );

    // رأس السهم
    final arrowLength =
        cell * 0.34;

    final arrowWidth =
        cell * 0.20;

    final tip = end +
        direction *
            (cell * 0.12);

    final left = Offset(
      tip.dx -
          arrowLength *
              math.cos(angle - 0.48),
      tip.dy -
          arrowLength *
              math.sin(angle - 0.48),
    );

    final right = Offset(
      tip.dx -
          arrowLength *
              math.cos(angle + 0.48),
      tip.dy -
          arrowLength *
              math.sin(angle + 0.48),
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        left.dx,
        left.dy,
      )
      ..lineTo(
        right.dx,
        right.dy,
      )
      ..close();

    final headPaint = Paint()
      ..color =
          color.withOpacity(0.90)
      ..style =
          PaintingStyle.fill;

    canvas.drawPath(
      path,
      headPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _ArrowPainter oldDelegate,
  ) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.flipped != flipped ||
        oldDelegate.color != color;
  }
}
