import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'settings_screen.dart';

class NavigationScreen extends StatefulWidget {
  final CameraController cameraController;
  final String destination;

  NavigationScreen({required this.cameraController, required this.destination});

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isDetecting = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadModel();
    await _loadLabels();
    _startImageStream();
  }

  // Load Model
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('detect.tflite');
      debugPrint('Model load successfully'); // To make sure the model is truly loaded
      debugPrint('Input tensor shape: ${_interpreter!.getInputTensor(0).shape}'); // To check the input tensor shape
      debugPrint('Input tensor type: ${_interpreter!.getInputTensor(0).type}'); // To check the input tensor type
    } catch (e) {
      debugPrint('Error loading model: $e'); // Error Message
    }
  }

  // Load the object's labels
  Future<void> _loadLabels() async {
    try {
      final labelsData = await DefaultAssetBundle.of(context).loadString('assets/labelmap.txt');
      _labels = labelsData.split('\n');
    } catch (e) {
      debugPrint('Error loading labels: $e'); // Error Message
    }
  }
  
  // To start image stream
  Future<void> _startImageStream() async {
    widget.cameraController.startImageStream((CameraImage image) async {
      if (_isDetecting || _labels.isEmpty || _interpreter == null || !mounted) return;
      _isDetecting = true;

      try {
        final convertedImage = _convertCameraImageToRGB(image);
        final tensorImage = _preprocessImageWithHelper(convertedImage);
        final input = tensorImage.buffer;

        var outputBoxes = List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
        var outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
        var outputScores = List.generate(1, (_) => List.filled(10, 0.0));
        var outputCount = List.filled(1, 0.0);

        final outputs = {
          0: outputBoxes,
          1: outputClasses,
          2: outputScores,
          3: outputCount
        };

        _interpreter!.runForMultipleInputs([input], outputs);

        final results = <Map<String, dynamic>>[];
        int count = outputCount[0].toInt();
        double inputSize = 300;

        for (int i = 0; i < count; i++) {
          final score = outputScores[0][i];
          if (score > 0.6) {
            final classIndex = outputClasses[0][i].toInt();
            final label = _labels[classIndex];
            final box = outputBoxes[0][i];

            final rect = Rect.fromLTWH(
              box[1] * inputSize,
              box[0] * inputSize,
              (box[3] - box[1]) * inputSize,
              (box[2] - box[0]) * inputSize,
            );

            results.add({
              'rect': rect,
              'label': label,
              'confidence': score,
            });
          }
        }

        if (mounted) setState(() => _results = results);
      } catch (e) {
        debugPrint("Detection error: $e");
      }

      await Future.delayed(Duration(milliseconds: 300));
      _isDetecting = false;
    });
  }

  // Convert camera view to RGB
  img.Image _convertCameraImageToRGB(CameraImage image) {
    final img.Image rgbImage = img.Image(image.width, image.height);
    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final uvIndex = (y ~/ 2) * planeU.bytesPerRow + (x ~/ 2);
        final indexY = y * planeY.bytesPerRow + x;
        final yVal = planeY.bytes[indexY];
        final uVal = planeU.bytes[uvIndex];
        final vVal = planeV.bytes[uvIndex];

        final r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).clamp(0, 255).toInt();
        final b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();

        rgbImage.setPixel(x, y, img.getColor(r, g, b));
      }
    }

    final resized = img.copyResize(rgbImage, width: 300, height: 300);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return isPortrait ? img.copyRotate(resized, 90) : resized;
  }

  // Preprocess Image by converting it to uint8
  TensorImage _preprocessImageWithHelper(img.Image image) {
    TensorImage tensorImage = TensorImage(TfLiteType.uint8);
    tensorImage.loadImage(image);

    final ImageProcessor imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(300, 300, ResizeMethod.BILINEAR))
        .build();

    return imageProcessor.process(tensorImage);
  }

  // Object Detection overlay to camera image
  Widget _buildDetectionsOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final previewWidth = constraints.maxWidth;
      final previewHeight = constraints.maxHeight;

      return Stack(
        children: _results.map((obj) {
          final rect = obj['rect'] as Rect;

          final left = rect.left / 300 * previewWidth;
          final top = rect.top / 300 * previewHeight;
          final width = rect.width / 300 * previewWidth;
          final height = rect.height / 300 * previewHeight;

          return Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    "${obj['label']} ${(obj['confidence'] * 100).toStringAsFixed(0)}%",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      // AppBar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Container(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          height: 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF383838), 
                Color(0x80000000),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // Back Button
              Material(
                shape: CircleBorder(),
                color: CupertinoColors.white.withOpacity(0.8),
                elevation: 4,
                child: InkWell(
                  customBorder: CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: SizedBox(
                    width: 60, 
                    height: 60,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: CupertinoColors.black,
                        size: 45,
                      ),
                    ),
                  ),
                ),
              ),

              // Menu button
              Container(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(CupertinoIcons.line_horizontal_3, color: CupertinoColors.white, size: 70),
                      onPressed: () {
                        if (widget.cameraController.value.isInitialized) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(
                                cameraController: widget.cameraController,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),   
            ],
          ),
        ),
      ),

      // Body
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(widget.cameraController),
          ),
          _buildDetectionsOverlay(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  // Bottom Content
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(CupertinoIcons.location_circle_fill, size: 70, color: Colors.black87),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Destination to', style: TextStyle(fontSize: 18, color: Colors.black87)),
                            SizedBox(height: 7),
                            Row(
                              children: [
                                Text(
                                  widget.destination,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 85),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '5 m',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Starting Waypoint:',
                        style: TextStyle(fontSize: 20, color: Colors.black54),
                      ),
                      Text(
                        'Main Lobby',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}