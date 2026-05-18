import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Paints bounding boxes, landmarks, and contours for each detected face.
class FacePainter extends CustomPainter {
  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.availableSize,
  });

  final List<Face> faces;
  final Size imageSize;
  final Size availableSize;

  // ── Paints ────────────────────────────────────────────────────────────────
  static final Paint _boxPaint = Paint()
    ..color = const Color(0xFF6C63FF)
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  static final Paint _landmarkPaint = Paint()
    ..color = const Color(0xFFFFD700)
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  static final Paint _contourPaint = Paint()
    ..color = const Color(0xFF00E5FF).withOpacity(0.7)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  // ── Scale helpers ─────────────────────────────────────────────────────────
  ({double scale, double dx, double dy}) _fitContain() {
    final scaleX = availableSize.width / imageSize.width;
    final scaleY = availableSize.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dx = (availableSize.width - imageSize.width * scale) / 2;
    final dy = (availableSize.height - imageSize.height * scale) / 2;
    return (scale: scale, dx: dx, dy: dy);
  }

  Offset _scalePoint(double x, double y, double scale, double dx, double dy) {
    return Offset(x * scale + dx, y * scale + dy);
  }

  // ── Paint ─────────────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    final fit = _fitContain();
    final s = fit.scale;
    final dx = fit.dx;
    final dy = fit.dy;

    for (final Face face in faces) {
      // Bounding box
      final rect = Rect.fromLTRB(
        face.boundingBox.left * s + dx,
        face.boundingBox.top * s + dy,
        face.boundingBox.right * s + dx,
        face.boundingBox.bottom * s + dy,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        _boxPaint,
      );

      // Label
      _drawLabel(canvas, rect, face);

      // Contours
      _drawContours(canvas, face, s, dx, dy);

      // Landmarks
      _drawLandmarks(canvas, face, s, dx, dy);
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, Face face) {
    final smileProb = face.smilingProbability;
    final label =
        smileProb != null ? '${(smileProb * 100).toStringAsFixed(0)}% 😊' : '';
    if (label.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: ' $label ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xFF6C63FF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(rect.left, rect.top - tp.height - 2));
  }

  void _drawContours(
      Canvas canvas, Face face, double scale, double dx, double dy) {
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour != null) {
      final path = Path();
      final points = faceContour.points;
      if (points.isNotEmpty) {
        path.moveTo(
          points.first.x.toDouble() * scale + dx,
          points.first.y.toDouble() * scale + dy,
        );
        for (final pt in points.skip(1)) {
          path.lineTo(
            pt.x.toDouble() * scale + dx,
            pt.y.toDouble() * scale + dy,
          );
        }
        path.close();
        canvas.drawPath(path, _contourPaint);
      }
    }
  }

  void _drawLandmarks(
      Canvas canvas, Face face, double scale, double dx, double dy) {
    const landmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
    ];

    for (final type in landmarks) {
      final lm = face.landmarks[type];
      if (lm != null) {
        canvas.drawCircle(
          _scalePoint(lm.position.x.toDouble(), lm.position.y.toDouble(), scale,
              dx, dy),
          4,
          _landmarkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FacePainter old) =>
      old.faces != faces ||
      old.imageSize != imageSize ||
      old.availableSize != availableSize;
}
