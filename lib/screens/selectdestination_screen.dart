import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'settings_screen.dart';
import 'navigation_screen.dart';

class SelectDestinationScreen extends StatefulWidget {
  final CameraController cameraController;

  SelectDestinationScreen({required this.cameraController});

  @override
  _SelectDestinationScreenState createState() => _SelectDestinationScreenState();
}

class _SelectDestinationScreenState extends State<SelectDestinationScreen> {
  // List of destinations
  final items = [
    'Cafeteria',
    'Toilet Cafeteria (Male)',
    'Musola (Male)',
    'Additional Musola (Male)',
    'Cita Lab',
  ];
  String? value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    extendBodyBehindAppBar: true,
      //Appbar
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
                Color(0xFF383838), // #383838 full opacity
                Color(0x80000000), // #000000 at 50% opacity
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
          // Live camera preview as background
          Positioned.fill(
            child: CameraPreview(widget.cameraController),
          ),

          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: CupertinoColors.black.withOpacity(0.1)),
          ),

          // Main content
          Center(
            child: Container(
              width: 350,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

            // Display destination options
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                final isSelected = value == item;
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? CupertinoColors.black : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: () {
                      if (widget.cameraController.value.isInitialized) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NavigationScreen(
                                cameraController: widget.cameraController,
                                destination: item,
                              ),
                            ),
                          );
                        }
                    },

                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isSelected ? CupertinoColors.white : CupertinoColors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}