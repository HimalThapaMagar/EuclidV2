import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:euclidv2/helpers/painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final GlobalKey _globalKey = GlobalKey();
  List<List<DrawingPoint>> strokes = []; // List of strokes
  List<DrawingPoint> currentStroke = []; // Current stroke being drawn
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drawing Calculator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final image = await _captureCanvasAsImage();
              if (image != null) {
                // TODO: Send to Go backend for processing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drawing captured! Ready to process.'))
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Drawing Canvas
          Positioned.fill(
            child: RepaintBoundary(
              key: _globalKey,
              child: Container(
                color: Colors.white,
                child: Listener(
                  onPointerDown: (details) {
                    setState(() {
                      // Start a new stroke
                      currentStroke = [];
                      
                      // Add first point
                      currentStroke.add(
                        DrawingPoint(
                          offset: details.localPosition,
                          paint: Paint()
                            ..color = selectedColor
                            ..isAntiAlias = true
                            ..strokeWidth = strokeWidth
                            ..strokeCap = StrokeCap.round,
                        ),
                      );
                      
                      // Add the new stroke to the list of strokes
                      strokes.add(currentStroke);
                    });
                  },
                  onPointerMove: (details) {
                    setState(() {
                      // Add point to current stroke
                      currentStroke.add(
                        DrawingPoint(
                          offset: details.localPosition,
                          paint: Paint()
                            ..color = selectedColor
                            ..isAntiAlias = true
                            ..strokeWidth = strokeWidth
                            ..strokeCap = StrokeCap.round,
                        ),
                      );
                      
                      // Update the reference in the strokes list
                      strokes[strokes.length - 1] = currentStroke;
                    });
                  },
                  onPointerUp: (details) {
                    // Stroke is complete, no need to do anything special
                  },
                  child: CustomPaint(
                    painter: DrawingPainter(strokes: strokes),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          
          // Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.grey.withOpacity(0.2),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Color Picker
                  _buildColorButton(Colors.black),
                  _buildColorButton(Colors.red),
                  _buildColorButton(Colors.blue),
                  _buildColorButton(Colors.green),
                  
                  // Stroke Width Slider
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 20,
                      value: strokeWidth,
                      onChanged: (val) {
                        setState(() {
                          strokeWidth = val;
                        });
                      },
                    ),
                  ),
                  
                  // Clear Button
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        strokes.clear();
                        currentStroke = [];
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _captureCanvasAsImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print("Error capturing canvas: $e");
      return null;
    }
  }
}