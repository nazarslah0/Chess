import 'package:flutter/material.dart';
import 'models.dart';
import 'piece_painter.dart';

class SetupPanel extends StatelessWidget {
  final GameState state;
  final PieceTheme pieceTheme;
  final String? selectedPiece; // e.g. 'wP'
  final bool eraseMode;
  final void Function(String? colorType) onSelectPiece;
  final VoidCallback onToggleErase;
  final VoidCallback onChanged;

  const SetupPanel({
    super.key,
    required this.state,
    required this.pieceTheme,
    required this.selectedPiece,
    required this.eraseMode,
    required this.onSelectPiece,
    required this.onToggleErase,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const order = ['K', 'Q', 'R', 'B', 'N', 'P'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إعداد الوضعية', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final color in ['w', 'b'])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    for (final t in order)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onSelectPiece('$color$t'),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedPiece == '$color$t'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade400,
                                width: selectedPiece == '$color$t' ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SizedBox.expand(
                              child: pieceTheme.assetFolder != null
                                  ? Image.asset(pieceTheme.assetPath(color, t), fit: BoxFit.contain)
                                  : CustomPaint(painter: PiecePainter(t, color, pieceTheme)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onToggleErase,
                  style: eraseMode
                      ? FilledButton.styleFrom(backgroundColor: Colors.red.shade100)
                      : null,
                  child: const Text('أداة المسح'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('الدور: '),
                DropdownButton<String>(
                  value: state.setupTurn,
                  items: const [
                    DropdownMenuItem(value: 'w', child: Text('الأبيض')),
                    DropdownMenuItem(value: 'b', child: Text('الأسود')),
                  ],
                  onChanged: (v) {
                    state.setupTurn = v ?? 'w';
                    state.refresh();
                    onChanged();
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              children: [
                _castleCheck(context, 'K', state.ck, (v) => state.ck = v),
                _castleCheck(context, 'Q', state.cq, (v) => state.cq = v),
                _castleCheck(context, 'k', state.ckb, (v) => state.ckb = v),
                _castleCheck(context, 'q', state.cqb, (v) => state.cqb = v),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              decoration: const InputDecoration(labelText: 'En Passant (مثال: e3 أو -)'),
              controller: TextEditingController(text: state.ep == '-' ? '' : state.ep),
              onChanged: (v) {
                state.ep = v.trim().isEmpty ? '-' : v.trim();
                state.refresh();
                onChanged();
              },
            ),
            const SizedBox(height: 6),
            Text(state.legalMessage,
                style: TextStyle(color: state.legal ? Colors.grey : Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _castleCheck(BuildContext ctx, String label, bool value, void Function(bool) set) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (v) {
        set(v);
        state.refresh();
        onChanged();
      },
    );
  }
}

class AnalysisPanel extends StatelessWidget {
  final String engineStatus;
  final bool engineReady;
  final bool analyzing;
  final int depth;
  final int multiPv;
  final Map<int, PvLineDisplay> lines; // 1..3
  final VoidCallback onAnalyze;
  final VoidCallback onStop;
  final void Function(int) onDepthChanged;
  final void Function(int) onMultiPvChanged;
  final void Function(int multipv) onSelectLine;

  const AnalysisPanel({
    super.key,
    required this.engineStatus,
    required this.engineReady,
    required this.analyzing,
    required this.depth,
    required this.multiPv,
    required this.lines,
    required this.onAnalyze,
    required this.onStop,
    required this.onDepthChanged,
    required this.onMultiPvChanged,
    required this.onSelectLine,
  });

  @override
  Widget build(BuildContext context) {
    final top = lines[1];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تحليل Stockfish', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(engineStatus, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('العمق: '),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 60, // not capped at 30 — real practical ceiling for UCI "go depth"
                    divisions: 59,
                    value: depth.toDouble(),
                    label: '$depth',
                    onChanged: (v) => onDepthChanged(v.round()),
                  ),
                ),
                Text('$depth'),
              ],
            ),
            Row(
              children: [
                const Text('عدد أفضل النقلات: '),
                DropdownButton<int>(
                  value: multiPv,
                  items: const [1, 2, 3, 4, 5]
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) => onMultiPvChanged(v ?? 3),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                FilledButton(
                  onPressed: engineReady && !analyzing ? onAnalyze : null,
                  child: const Text('تحليل الوضعية'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: analyzing ? onStop : null,
                  child: const Text('إيقاف التحليل'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (top != null) ...[
              Text('التقييم: ${top.evalLabel}   (العمق ${top.depth})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('أفضل نقلة: ${top.moves.isNotEmpty ? top.moves.first : ''}'),
            ],
            const SizedBox(height: 10),
            const Text('أفضل ٣ نقلات', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final idx in lines.keys.toList()..sort())
              InkWell(
                onTap: () => onSelectLine(idx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '#$idx ${lines[idx]!.moves.take(6).join(' ')}   ${lines[idx]!.evalLabel}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// SAN-converted, forced-move-tagged display data for one MultiPV line.
class PvLineDisplay {
  final int depth;
  final String evalLabel;
  final List<String> moves; // SAN, with "(إجبارية)" suffix when forced
  final String bestFrom, bestTo;
  const PvLineDisplay({
    required this.depth,
    required this.evalLabel,
    required this.moves,
    required this.bestFrom,
    required this.bestTo,
  });
}

class MoveListPanel extends StatelessWidget {
  final List<MoveEntry> history;
  const MoveListPanel({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    int num = 0;
    for (final m in history) {
      if (m.color == 'w') num++;
      rows.add(Text(
        '${m.color == 'w' ? '$num. ' : ''}${m.san}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('قائمة النقلات', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SizedBox(
              height: 160,
              child: SingleChildScrollView(
                child: Wrap(spacing: 10, runSpacing: 4, children: rows),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
