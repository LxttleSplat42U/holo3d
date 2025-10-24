# Holo3D mobile companion app

Created by: SP Botes for my 2025 skripsie project

This application is used to control the Holo3D fan system.

To download the standalone Android application, install the `app-release.apk` file in the `Android_APK` folder.

If the fan system is unavailable or cannot be connected to, you can install the Demo application's `app-release.apk` from the `Android_APK` folder in the Demo branch:
https://github.com/LxttleSplat42U/holo3d/tree/Demo-mode
This Demo application lets you explore the UI without connecting to the actual fan system.

For the main source code, please navigate to `lib->main.dart` or click the link https://github.com/LxttleSplat42U/holo3d/blob/main/lib/main.dart

# UI Showcase 1: Auto fit to device aspect ratio

https://github.com/user-attachments/assets/cd5323ba-ea31-4f86-bab2-348c7ad43074

# UI Schowcase 2: App navigation

# Holo3D Fan Controller v1.0.0

## Features
- Dual fan control (Fan 1 & Fan 2)
- Multiple display modes (Circle, Arc, Custom Circle, Text, etc.)
- Custom color picker for circle displays when the "Custom Circle" image is selected
- Dual-linked motor speed control
- Bluetooth remote support to toggle both fan displays on/off
- Accelerometer-based emergency stop (using the "Enable fan E-Stop" button) that shuts off the fan system when sufficient movement/acceleration is detected
- Wi‑Fi connectivity check (verifies that the mobile application is connected to the "Holo3D" Wi‑Fi network)
- Real-time RPM monitoring of both fans

## Installation
1. Download `app-release.apk`
2. Enable "Install from unknown sources" on your Android device
3. Install the APK
4. Connect to the "Holo3D" Wi‑Fi network
5. Open the app and tap "Connect" after navigating to the "Fan controls" section in the left navigation rail

## Requirements
- Android 5.0 (Lollipop) or higher
- Holo3D fan system with a Wi‑Fi hotspot (not required if using the Holo3D Demo from https://github.com/LxttleSplat42U/holo3d/tree/Demo-mode)

