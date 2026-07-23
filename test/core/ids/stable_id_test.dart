import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';

void main() {
  test('same document ID and path always produce the same ID', () {
    expect(
      stableNodeId('doc-1', [0, 2, 5]),
      equals(stableNodeId('doc-1', [0, 2, 5])),
    );
  });

  test('different paths under the same document produce different IDs', () {
    expect(
      stableNodeId('doc-1', [0, 2, 5]),
      isNot(equals(stableNodeId('doc-1', [0, 2, 6]))),
    );
  });

  test('the same path under different documents produces different IDs', () {
    expect(
      stableNodeId('doc-1', [0, 2, 5]),
      isNot(equals(stableNodeId('doc-2', [0, 2, 5]))),
    );
  });
}
