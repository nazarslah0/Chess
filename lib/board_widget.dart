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
    final board = GameState.parseBoard(state.currentFen.split(' ')[0]);
    final flipped = state.flipped;
    bool isCheckSquare(String sq) {
      if (state.mode != 'play') return false;
      bool inCheck = false;
      try {
        inCheck = state.chess.in_check == true;
      } catch (_) {}
      if (!inCheck) return false;
      final turn = state.currentFen.split(' ')[1];
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
                  border: Border.all(color: boardTheme.border, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                    itemCount: 64,
                    itemBuilder: (context, index) {
                      final col = index % 8;
                      final row = index ~/ 8;
                      final f = flipped ? 7 - col : col;
                      final r = flipped ? row : 7 - row;
                      final sq = files[f] + (r + 1).toString();
                      final isDark = (f + r) % 2 != 0;
                      final piece = board[sq];
                      final isLast = sq == state.lastFrom || sq == state.lastTo;
                      final isSel = sq == state.selectedSquare;
                      final isTarget = targets.contains(sq);
                      final isCheck = isCheckSquare(sq);
                      return GestureDetector(
                        onTap: () => onTap(sq),
                        child: Container(
                          color: isDark ? boardTheme.dark : boardTheme.light,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isLast) Container(color: boardTheme.lastMove),
                              if (isSel) Container(color: boardTheme.selected),
                              if (isCheck)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: boardTheme.checkColor, width: 3),
                                  ),
                                ),
                              if (piece != null)
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: CustomPaint(
                                    painter: PiecePainter(
                                        piece.substring(1), piece.substring(0, 1), pieceTheme),
                                  ),
                                ),
                              if (isTarget)
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: boardTheme.target,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (col == 0)
                                Positioned(
                                  top: 2,
                                  left: 2,
                                  child: Text('${r + 1}',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: boardTheme.border.withOpacity(0.7))),
                                ),
                              if (row == 7)
                                Positioned(
                                  bottom: 1,
                                  right: 3,
                                  child: Text(files[f],
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: boardTheme.border.withOpacity(0.7))),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (arrowFrom != null && arrowTo != null)
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _ArrowPainter(arrowFrom!, arrowTo!, flipped, Colors.blueAccent),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final String from, to;
  final bool flipped;
  final Color color;
  _ArrowPainter(this.from, this.to, this.flipped, this.color);

  Offset _center(String sq, double cell) {
    final f = BoardWidget.files.indexOf(sq[0]);
    final r = int.parse(sq.substring(1)) - 1;
    final col = flipped ? 7 - f : f;
    final row = flipped ? r : 7 - r;
    return Offset(col * cell + cell / 2, row * cell + cell / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final p1 = _center(from, cell);
    final p2 = _center(to, cell);
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = cell * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, paint);
    final angle = (p2 - p1).direction;
    final arrowSize = cell * 0.28;
    final path = Path()
      ..moveTo(p2.dx, p2.dy)
      ..lineTo(p2.dx - arrowSize * 1.3 * math.cos(angle - 0.5),
          p2.dy - arrowSize * 1.3 * math.sin(angle - 0.5))
      ..lineTo(p2.dx - arrowSize * 1.3 * math.cos(angle + 0.5),
          p2.dy - arrowSize * 1.3 * math.sin(angle + 0.5))
      ..close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to || oldDelegate.flipped != flipped;
}
