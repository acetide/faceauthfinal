import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// MobileFaceNet input size (112×112 RGB).
const int _kInputSize = 112;

/// Cosine-similarity threshold that maps to ≥55% verification accuracy.
/// Tuned for MobileFaceNet embeddings; raise toward 0.6 for stricter matching.
const double _kVerifyThreshold = 0.55;

/// Result returned by [FaceNetService.verify].
class VerificationResult {
  const VerificationResult({
    required this.verified, // 1 = same person, 0 = different
    required this.similarity, // cosine similarity [-1, 1]
  });

  /// 1 if verified (same person), 0 otherwise.
  final int verified;

  /// Raw cosine similarity score between the two embeddings.
  final double similarity;

  @override
  String toString() =>
      'VerificationResult(verified: $verified, similarity: ${similarity.toStringAsFixed(4)})';
}

/// Wraps the MobileFaceNet TFLite model.
///
/// Usage:
/// ```dart
/// final svc = FaceNetService();
/// await svc.init();
///
/// // Register a reference face
/// final refEmb = await svc.embedFromImage(imageBytes, face);
///
/// // Verify a new face against it
/// final result = await svc.verify(probeEmb, refEmb); // result.verified == 1 or 0
/// ```
class FaceNetService {
  Interpreter? _interpreter;
  bool _isReady = false;

  bool get isReady => _isReady;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Loads the TFLite model from assets.
  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobile_face_net.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      _isReady = true;
    } catch (e) {
      _isReady = false;
      rethrow;
    }
  }

  void dispose() {
    _interpreter?.close();
    _isReady = false;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Crops [face] from [imageBytes], runs MobileFaceNet, and returns a
  /// 128-dimensional L2-normalised embedding.
  ///
  /// Returns `null` if the model is not ready or the bounding box is invalid.
  Future<List<double>?> embedFromImage(
    Uint8List imageBytes,
    Face face,
  ) async {
    if (!_isReady || _interpreter == null) return null;

    // Decode & crop
    final cropped = _cropFace(imageBytes, face.boundingBox);
    if (cropped == null) return null;

    // Preprocess → [1, 112, 112, 3] float32 tensor
    final input = _preprocess(cropped);

    // Output tensor: [1, 128]
    final output = List.generate(1, (_) => List<double>.filled(128, 0));

    _interpreter!.run(input, output);

    final embedding = output[0];
    return _l2Normalize(embedding);
  }

  /// Compares two embeddings with cosine similarity.
  ///
  /// Returns [VerificationResult] where [VerificationResult.verified] is:
  /// - **1** → same person (similarity ≥ [_kVerifyThreshold])
  /// - **0** → different people
  VerificationResult verify(
    List<double> embeddingA,
    List<double> embeddingB,
  ) {
    final sim = _cosineSimilarity(embeddingA, embeddingB);
    return VerificationResult(
      verified: sim >= _kVerifyThreshold ? 1 : 0,
      similarity: sim,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Decodes [imageBytes] and crops to [boundingBox] with a small padding.
  img.Image? _cropFace(Uint8List imageBytes, Rect boundingBox) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return null;

    // 10 % padding around the bounding box
    final pad = boundingBox.width * 0.10;
    final x = (boundingBox.left - pad).clamp(0, decoded.width - 1).toInt();
    final y = (boundingBox.top - pad).clamp(0, decoded.height - 1).toInt();
    final w = (boundingBox.width + pad * 2).clamp(1, decoded.width - x).toInt();
    final h =
        (boundingBox.height + pad * 2).clamp(1, decoded.height - y).toInt();

    final crop = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    return img.copyResize(crop, width: _kInputSize, height: _kInputSize);
  }

  /// Converts an [img.Image] (112×112) → float32 tensor [1, 112, 112, 3]
  /// normalised to [-1, 1] as MobileFaceNet expects.
  List<List<List<List<double>>>> _preprocess(img.Image face) {
    // shape: [1][112][112][3]
    final tensor = List.generate(
      1,
      (_) => List.generate(
        _kInputSize,
        (y) => List.generate(
          _kInputSize,
          (x) {
            final pixel = face.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );
    return tensor;
  }

  /// L2-normalises a vector so cosine similarity == dot product.
  List<double> _l2Normalize(List<double> v) {
    final norm = sqrt(v.fold(0.0, (sum, e) => sum + e * e));
    if (norm == 0) return v;
    return v.map((e) => e / norm).toList();
  }

  /// Cosine similarity ∈ [-1, 1].  Values ≥ [_kVerifyThreshold] → same person.
  double _cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Embedding lengths must match');
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    return denom == 0 ? 0 : dot / denom;
  }
}
