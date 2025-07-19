import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';

class SettingsScreen extends StatefulWidget {
  final CameraController cameraController;

  SettingsScreen({required this.cameraController});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isVoiceEnabled = false;
  bool isHapticEnabled = true;

  double voiceVolume = 1.0;
  double hapticStrength = 0.5;

  @override
  Widget build(BuildContext context) {

    // Appbar
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
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
            child: Container(
                color: CupertinoColors.black.withOpacity(0.1)
              ),
          ),

          // Overlay card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 300,
                height: 350,
                padding: EdgeInsets.all(16),
                color: CupertinoColors.white.withOpacity(0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Voice Section
                    SizedBox(height: 20),
                    _buildSettingRow(
                      title: 'Voice',
                      enabled: isVoiceEnabled,
                      color: CupertinoColors.activeBlue,
                      sliderValue: voiceVolume,
                      onToggle: (value) {
                        setState(() => isVoiceEnabled = value);
                      },
                      onSliderChanged: (value) {
                        setState(() => voiceVolume = value);
                      },
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 20),

                    // Haptic Section
                    _buildSettingRow(
                      title: 'Haptic',
                      enabled: isHapticEnabled,
                      color: CupertinoColors.systemGrey6,
                      sliderValue: hapticStrength,
                      onToggle: (value) {
                        setState(() => isHapticEnabled = value);
                      },
                      onSliderChanged: (value) {
                        setState(() => hapticStrength = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required bool enabled,
    required Color color,
    required double sliderValue,
    required Function(bool) onToggle,
    required Function(double) onSliderChanged,
  }){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400)),
            Switch(
              value: enabled,
              onChanged: (_) {},
              activeColor: Colors.white, // Thumb color when ON
              activeTrackColor: Colors.green, // Track color when ON
              inactiveThumbColor: Colors.grey, // Thumb color when OFF
              inactiveTrackColor: Colors.grey.shade300, // Track color when OFF
            ),
          ],
        ),
        SizedBox(height: 15),
        
        // Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.volume_off_rounded, size: 40),
            Expanded(
              child: Slider(
                value: sliderValue,
                onChanged: enabled ? onSliderChanged : null,
                activeColor: CupertinoColors.activeBlue,
                inactiveColor: Colors.grey.shade300,
              ),
            ),
            Icon(Icons.volume_up_rounded, size: 40),
          ],
        ),
      ],
    );
  }
}