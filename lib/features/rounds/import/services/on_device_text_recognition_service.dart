import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OnDeviceTextRecognitionResult {
  const OnDeviceTextRecognitionResult({
    required this.text,
    required this.lineCount,
  });

  final String text;
  final int lineCount;
}

class OnDeviceTextRecognitionService {
  const OnDeviceTextRecognitionService();

  Future<OnDeviceTextRecognitionResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final elements = result.blocks
          .expand((block) => block.lines)
          .expand((line) => line.elements)
          .where((element) => element.text.trim().isNotEmpty)
          .toList();
      final rows = _groupIntoPhysicalRows(elements);
      final text = rows
          .map(
            (row) => row
                .map((element) => element.text.trim())
                .where((value) => value.isNotEmpty)
                .join(' '),
          )
          .where((row) => row.isNotEmpty)
          .join('\n');
      if (text.isEmpty) {
        throw const FormatException(
          'The offline reader did not find any text in this photo.',
        );
      }
      return OnDeviceTextRecognitionResult(text: text, lineCount: rows.length);
    } finally {
      await recognizer.close();
    }
  }

  List<List<TextElement>> _groupIntoPhysicalRows(List<TextElement> elements) {
    if (elements.isEmpty) return const [];
    final heights =
        elements
            .map((element) => element.boundingBox.height)
            .where((height) => height > 0)
            .toList()
          ..sort();
    final medianHeight = heights.isEmpty ? 16.0 : heights[heights.length ~/ 2];
    final tolerance = (medianHeight * 0.65).clamp(7.0, 28.0);
    final ordered = List<TextElement>.of(elements)
      ..sort(
        (left, right) =>
            left.boundingBox.center.dy.compareTo(right.boundingBox.center.dy),
      );
    final rows = <List<TextElement>>[];
    final centers = <double>[];
    for (final element in ordered) {
      final center = element.boundingBox.center.dy;
      var bestRow = -1;
      var bestDistance = double.infinity;
      for (var index = 0; index < centers.length; index++) {
        final distance = (centers[index] - center).abs();
        if (distance <= tolerance && distance < bestDistance) {
          bestRow = index;
          bestDistance = distance;
        }
      }
      if (bestRow < 0) {
        rows.add([element]);
        centers.add(center);
      } else {
        rows[bestRow].add(element);
        centers[bestRow] =
            rows[bestRow]
                .map((item) => item.boundingBox.center.dy)
                .reduce((left, right) => left + right) /
            rows[bestRow].length;
      }
    }
    final indexes = List.generate(rows.length, (index) => index)
      ..sort((left, right) => centers[left].compareTo(centers[right]));
    return indexes
        .map((index) {
          final row = rows[index]
            ..sort(
              (left, right) =>
                  left.boundingBox.left.compareTo(right.boundingBox.left),
            );
          return row;
        })
        .toList(growable: false);
  }
}
