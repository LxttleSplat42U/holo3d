# Holo3D mobile companion app
Created by: SP Botes for my 2025 skripsie project

This application can be used to control the Holo3D fan system.

To download the standalone andorid appication install the "app-release.apk" file under the "Android_APK" folder.

If the fan system is unavailable or can't be connected to. The branch Demo branch's  "app-release.apk" file under the "Android_APK" folder can be installed instead. @https://github.com/LxttleSplat42U/holo3d/tree/Demo-mode
This Demo application can be used to inspect the UI without requiring a connection to the actual fan system.

# Holo3D Fan Controller v1.0.0

## Features
- Dual fan control (Fan 1 & Fan 2)
- Multiple display modes (Circle, Arc, Custom Circle, Text, etc.)
- Custom color picker for circle displays when the image "Custom Circle" is selected
- Dual linked motor speed control
- Bluetooth remote support for turning both fan displays on/off
- Accelerometer emergency stop (using the "Enable fan E-Stop" button) which will shut-off the fan system if enough movement/acceleration is detected
- WiFi connectivity check (Checks if mobile application is connected to the "Holo3D" wifi network)
- Real-time RPM monitoring of both fans

## Installation
1. Download `app-release.apk`
2. Enable "Install from unknown sources" on your Android device
3. Install the APK
4. Connect to "Holo3D" WiFi network
5. Open the app and tap "Connect" after navigating to the "Fan controls" section using the left navigation rail

## Requirements
- Android 5.0 (Lollipop) or higher
- Holo3D fan system with WiFi hotspot (not required if Holo3D demo is used from https://github.com/LxttleSplat42U/holo3d/tree/Demo-mode)

