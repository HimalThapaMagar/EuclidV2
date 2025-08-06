import 'dart:ui';
import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint>> strokes;

  DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      // Skip empty strokes
      if (stroke.isEmpty) continue;
      
      // Draw each stroke as a separate path
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(
          stroke[i].offset,
          stroke[i + 1].offset,
          stroke[i].paint,
        );
      }
      
      // If the stroke has only one point, draw it as a dot
      if (stroke.length == 1) {
        canvas.drawPoints(
          PointMode.points,
          [stroke[0].offset],
          stroke[0].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}