import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'selectdestination_screen.dart';
import 'settings_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool loading = false;
  bool showBottomContent = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  // Initialize Camera
  Future<void> initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted && cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera Permission Denied")),
      );
    }
  }

  // When the camera is closed
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Handle when the user clicked the camera button
  void _onCameraButtonClicked() async {
    setState(() {
      loading = true;
      showBottomContent = true;
    });

    // Simulate a delay animation for localization
    await Future.delayed(Duration(seconds: 6));

    // Navigate to the next screen only if the widget is still mounted
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelectDestinationScreen(cameraController: _controller!),),
      );
    }

    // Reset loading state and hide bottom content
    setState(() {
      loading = false;
      showBottomContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_isInitialized) {
      return Scaffold(
        backgroundColor: CupertinoColors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Appbar
    return Scaffold(
      extendBodyBehindAppBar: true,
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
              SizedBox(width: 60), // Placeholder
              IconButton(
                icon: Icon(
                  CupertinoIcons.line_horizontal_3,
                  color: CupertinoColors.white,
                  size: 70,
                ),
                onPressed: () {
                  if (_controller != null && _controller!.value.isInitialized) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          cameraController: _controller!,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),

      // Body
      body: Stack(
        children: [
          // Live camera preview as background
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          
          // Instruction box
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 250,
                height: 250,
                padding: EdgeInsets.all(16),
                color: CupertinoColors.white.withOpacity(0.4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.camera_viewfinder,
                      size: 64,
                      color: CupertinoColors.white,
                      shadows: [
                        Shadow(
                          color: CupertinoColors.black.withOpacity(0.5),
                          offset: Offset(2, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "Tap the shutter button below to start scanning your surroundings.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              color: CupertinoColors.black.withOpacity(0.5),
                              offset: Offset(2, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Camera button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF383838), 
                    Color(0x80000000), 
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: GestureDetector(
                onTap: _onCameraButtonClicked,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: CupertinoColors.black, width: 3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),


          // Background blur
          if (loading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: CupertinoColors.black.withOpacity(0.1),
                ),
              ),
            ),

          // Loading indicator
          if (loading)
            Center(child: 
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(CupertinoColors.black),
              ),
            ),

          // Bottom content
          if (showBottomContent)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: BottomContent(),
              ),
            ),
        ],
      ),
    );
  }
}

class BottomContent extends StatefulWidget {
  @override
  _BottomContentState createState() => _BottomContentState();
}

class _BottomContentState extends State<BottomContent> {
  // Initial text and detection status
  String text1 = "Localization in Progress...";
  String text2 = "Please hold your device still for a moment while we try to find your location";
  bool detectionStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      localizationProgress();
    });
  }

  Future<void> localizationProgress() async {
    await Future.delayed(Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      detectionStatus = true;
      text1 = "Location detected!";
      text2 = "You are in Main Lobby.";
    });
    await Future.delayed(const Duration(seconds: 3)); // delayed 2 more seconds
    if (!mounted) return;
  }
  

// Bottom content widget
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Text(
            text1,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          Text(
            text2,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
