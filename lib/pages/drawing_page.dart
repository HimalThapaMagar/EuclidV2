import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:euclidv2/helpers/painter.dart';
import 'package:euclidv2/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final GlobalKey _globalKey = GlobalKey();
  List<List<DrawingPoint>> strokes = [];
  List<DrawingPoint> currentStroke = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  
  // Add state variables for calculation results
  bool _isProcessing = false;
  String? _resultExpression;
  String? _resultValue;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drawing Calculator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isProcessing ? null : _processDrawing,
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
                      // Clear any previous results when starting a new drawing
                      _resultExpression = null;
                      _resultValue = null;
                      _errorMessage = null;
                      
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
          
          // Results display (if available)
          if (_resultExpression != null || _errorMessage != null)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                color: _errorMessage != null ? Colors.red[100] : Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Text(
                          'Error: $_errorMessage',
                          style: TextStyle(fontSize: 16, color: Colors.red[900]),
                        )
                      else ...[
                        Text(
                          'Expression: $_resultExpression',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Result: $_resultValue',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          
          // Loading indicator
          if (_isProcessing)
            const Center(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing drawing...'),
                    ],
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
                        _resultExpression = null;
                        _resultValue = null;
                        _errorMessage = null;
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
  
  // New method to process the drawing
  Future<void> _processDrawing() async {
    final imageData = await _captureCanvasAsImage();
    
    if (imageData == null) {
      setState(() {
        _errorMessage = "Failed to capture the drawing";
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    
    try {
      // Send the image to the backend
      final result = await ApiService.uploadDrawing(imageData);
      
      setState(() {
        _isProcessing = false;
        _resultExpression = result['expression'];
        _resultValue = result['result'].toString();
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }
}