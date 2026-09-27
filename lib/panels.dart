import 'package:flutter/material.dart';
import 'models.dart';
import 'piece_painter.dart';

class SetupPanel extends StatefulWidget {
  final GameState state;
  final PieceTheme pieceTheme;
  final String? selectedPiece;
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
  State<SetupPanel> createState() => _SetupPanelState();
}

class _SetupPanelState extends State<SetupPanel> {
  late final TextEditingController _epController;

  @override
  void initState() {
    super.initState();
    _epController = TextEditingController(
      text: widget.state.ep == '-' ? '' : widget.state.ep,
    );
  }

  @override
  void dispose() {
    _epController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SetupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newValue = widget.state.ep == '-' ? '' : widget.state.ep;

    if (_epController.text != newValue &&
        !_epController.selection.isValid) {
      _epController.text = newValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    const order = ['K', 'Q', 'R', 'B', 'N', 'P'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعداد الوضعية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            // قطع الأبيض والأسود
            for (final color in ['w', 'b'])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (final type in order)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.onSelectPiece('$color$type');
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 46,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    widget.selectedPiece == '$color$type'
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : Colors.grey.shade400,
                                width:
                                    widget.selectedPiece == '$color$type'
                                        ? 2
                                        : 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SizedBox.expand(
                              child: widget.pieceTheme.assetFolder != null
                                  ? Image.asset(
                                      widget.pieceTheme.assetPath(
                                        color,
                                        type,
                                      ),
                                      fit: BoxFit.contain,
                                    )
                                  : CustomPaint(
                                      painter: PiecePainter(
                                        type,
                                        color,
                                        widget.pieceTheme,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // أداة المسح
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: widget.onToggleErase,
                  style: widget.eraseMode
                      ? FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                        )
                      : null,
                  child: Text(
                    widget.eraseMode ? 'المسح مفعل' : 'أداة المسح',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الدور
            Row(
              children: [
                const Text('الدور: '),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: widget.state.setupTurn,
                  items: const [
                    DropdownMenuItem(
                      value: 'w',
                      child: Text('الأبيض'),
                    ),
                    DropdownMenuItem(
                      value: 'b',
                      child: Text('الأسود'),
                    ),
                  ],
                  onChanged: (value) {
                    widget.state.setupTurn = value ?? 'w';
                    widget.state.refresh();
                    widget.onChanged();
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            // التبييت
            const Text(
              'التبييت:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 4),

            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _castleCheck(
                  context,
                  'K',
                  widget.state.ck,
                  (v) => widget.state.ck = v,
                ),
                _castleCheck(
                  context,
                  'Q',
                  widget.state.cq,
                  (v) => widget.state.cq = v,
                ),
                _castleCheck(
                  context,
                  'k',
                  widget.state.ckb,
                  (v) => widget.state.ckb = v,
                ),
                _castleCheck(
                  context,
                  'q',
                  widget.state.cqb,
                  (v) => widget.state.cqb = v,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // En Passant
            TextField(
              controller: _epController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'En Passant',
                hintText: 'e3 أو -',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                final v = value.trim();

                widget.state.ep = v.isEmpty ? '-' : v;
                widget.state.refresh();
                widget.onChanged();
              },
            ),

            const SizedBox(height: 8),

            // حالة الوضعية
            Text(
              widget.state.legalMessage,
              style: TextStyle(
                color: widget.state.legal
                    ? Colors.grey.shade700
                    : Colors.red,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _castleCheck(
    BuildContext context,
    String label,
    bool value,
    void Function(bool) set,
  ) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (v) {
        set(v);
        widget.state.refresh();
        widget.onChanged();
      },
    );
  }
}


// ============================================================
// لوحة تحليل Stockfish
// ============================================================

class AnalysisPanel extends StatelessWidget {
  final String engineStatus;
  final bool engineReady;
  final bool analyzing;
  final int depth;
  final int multiPv;
  final Map<int, PvLineDisplay> lines;

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

    final sortedKeys = lines.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تحليل Stockfish 19',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              engineStatus,
              style: TextStyle(
                fontSize: 13,
                color: engineReady
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),

            const SizedBox(height: 10),

            // العمق
            Row(
              children: [
                const Text('العمق: '),

                Expanded(
                  child: Slider(
                    min: 1,
                    max: 60,
                    divisions: 59,
                    value: depth
                        .clamp(1, 60)
                        .toDouble(),
                    label: '$depth',
                    onChanged: analyzing
                        ? null
                        : (value) {
                            onDepthChanged(value.round());
                          },
                  ),
                ),

                SizedBox(
                  width: 30,
                  child: Text(
                    '$depth',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // MultiPV
            Row(
              children: [
                const Text('عدد أفضل النقلات: '),

                const SizedBox(width: 8),

                DropdownButton<int>(
                  value: [1, 2, 3, 4, 5].contains(multiPv)
                      ? multiPv
                      : 3,
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('1'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('2'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('3'),
                    ),
                    DropdownMenuItem(
                      value: 4,
                      child: Text('4'),
                    ),
                    DropdownMenuItem(
                      value: 5,
                      child: Text('5'),
                    ),
                  ],
                  onChanged: analyzing
                      ? null
                      : (value) {
                          onMultiPvChanged(value ?? 3);
                        },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // أزرار التحليل
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        engineReady && !analyzing
                            ? onAnalyze
                            : null,
                    icon: const Icon(Icons.analytics),
                    label: const Text('تحليل الوضعية'),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        analyzing ? onStop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('إيقاف'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // التقييم الرئيسي
            if (top != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التقييم: ${top.evalLabel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'العمق: ${top.depth}',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'أفضل نقلة: '
                      '${top.moves.isNotEmpty ? top.moves.first : '—'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],

            Text(
              'أفضل $multiPv نقلات',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            if (sortedKeys.isEmpty)
              const Text(
                'لا توجد نتائج تحليل بعد.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

            for (final idx in sortedKeys)
              _pvRow(
                context,
                idx,
                lines[idx]!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _pvRow(
    BuildContext context,
    int index,
    PvLineDisplay line,
  ) {
    return InkWell(
      onTap: () => onSelectLine(index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 6,
        ),
        margin: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$index',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: Text(
                line.moves.take(8).join(' '),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                ),
              ),
            ),

            const SizedBox(width: 6),

            Text(
              line.evalLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// بيانات سطر MultiPV
// ============================================================

class PvLineDisplay {
  final int depth;
  final String evalLabel;

  /// النقلات بصيغة SAN.
  final List<String> moves;

  /// المربع الذي تبدأ منه أفضل نقلة.
  final String bestFrom;

  /// المربع الذي تنتهي إليه أفضل نقلة.
  final String bestTo;

  const PvLineDisplay({
    required this.depth,
    required this.evalLabel,
    required this.moves,
    required this.bestFrom,
    required this.bestTo,
  });
}


// ============================================================
// قائمة النقلات
// ============================================================

class MoveListPanel extends StatelessWidget {
  final List<MoveEntry> history;

  const MoveListPanel({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    int moveNumber = 0;

    for (final move in history) {
      if (move.color == 'w') {
        moveNumber++;
      }

      rows.add(
        Text(
          '${move.color == 'w' ? '$moveNumber. ' : ''}'
          '${move.san}',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'قائمة النقلات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            if (rows.isEmpty)
              const Text(
                'لا توجد نقلات بعد.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

            if (rows.isNotEmpty)
              SizedBox(
                height: 160,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children: rows,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
