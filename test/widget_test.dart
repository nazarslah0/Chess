import 'package:flutter_test/flutter_test.dart';
import 'package:chess_analyzer/models.dart';

void main() {
  test('default chess position is valid', () {
    final state = GameState();
    expect(state.currentFen.split(' ')[0], contains('rnbqkbnr'));
    expect(state.currentFen.split(' ')[1], 'w');
  });
}
