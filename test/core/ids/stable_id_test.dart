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

  test(
    'contentDerivedDocumentId is the same for identical bytes regardless of prefix casing of the call site',
    () {
      final bytesA = [1, 2, 3, 4];
      final bytesB = [1, 2, 3, 4];
      expect(
        contentDerivedDocumentId('epub', bytesA),
        equals(contentDerivedDocumentId('epub', bytesB)),
      );
    },
  );

  test(
    'contentDerivedDocumentId differs for different bytes with the same prefix',
    () {
      expect(
        contentDerivedDocumentId('epub', [1, 2, 3]),
        isNot(equals(contentDerivedDocumentId('epub', [1, 2, 4]))),
      );
    },
  );

  test(
    'contentDerivedDocumentId differs across source-type prefixes even for identical bytes',
    () {
      final bytes = [1, 2, 3, 4];
      expect(
        contentDerivedDocumentId('epub', bytes),
        isNot(equals(contentDerivedDocumentId('pdfText', bytes))),
      );
    },
  );
}
