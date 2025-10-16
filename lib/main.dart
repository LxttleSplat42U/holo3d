import 'dart:async';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; //Use for WebSocket
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// Enable sensors
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

int USER_WS_ID = 255; //Global variable to store user ID for WebSocket

bool Fan1_LED = true; //Global variable to store LED state
bool DemoMode =
    false; //Used to override and show fan controls without connecting to Holo3D fan system

void main() {
  //runApp(MyApp());
  runApp(Holo3D());
}

class Holo3D extends StatelessWidget {
  const Holo3D({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Holo3D',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor:
                  const Color.fromARGB(255, 0, 255, 255)), //Global Theme color
        ),
        home: MyHomePage(),
      ),
    );
  }
}

//Methods
class MyAppState extends ChangeNotifier {
  final ScrollController _scrollController = ScrollController();

// Function to scroll to the bottom
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  var current = WordPair.random();
  var allWordPairs = <WordPair>[];

//tutorial methods
// Get next word
  void getNext() {
    current = WordPair.random();
    allWordPairs.add(current);
    _scrollToBottom();
    notifyListeners();
  }

  //Favourites
  var fav = <WordPair>[]; //Make list which only takes WordPair types

  void toggleFavourite() {
    //Add or remove favourite
    if (fav.contains(current)) {
      fav.remove(current);
    } else {
      fav.add(current);
    }

    notifyListeners();
  }
////////////////////////////////
}

//Home Page
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//Navigation Rail
class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = WelcomePage();

      case 1:
        page = Fan();

      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >=
                    600, //Show Label if enough space ex. Rotated
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Symbols.mode_fan),
                    label: Text('Fan Controls'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class Fan extends StatefulWidget {
  const Fan({super.key});

  @override
  State<Fan> createState() => _FanState();
}

class _FanState extends State<Fan> {
  static const List<String> displayOptions = [
    'Circle',
    'Arc',
    'Custom circle',
    'E'
  ];
  double motorSpeed = 0;
  double fan1CirclePosition = 18;
  double fan2CirclePosition = 18;
  Color fan1SelectedColor = Colors.blue; // currently selected colour
  Color fan2SelectedColor = Colors.blue; // currently selected colour
  String fan1Display =
      displayOptions[0]; //Global variable to store Fan1 display image
  bool fan1On = false;
  String fan2Display =
      displayOptions[0]; //Global variable to store Fan2 display image
  bool fan2On = false;
  bool enableFanStop =
      false; // Global variable to enable fan stop on accel event
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  final double accelThreshold =
      1.5; // m/s^2 magnitude of acceleration needed to trigger e-stop
  bool fanShutdown =
      false; // Track if fans have been shut down due to accel event

  // throttle helpers: only send color update at most once per second
  DateTime? _fan1LastColorSent;
  DateTime? _fan2LastColorSent;
  Timer? _fan1ColorSendTimer;
  Timer? _fan2ColorSendTimer;

  //Connect to WebSocket
  WebSocketChannel? channel; // Make nullable
  bool isConnected = false;
  bool isConnecting = false;
  String connectionStatus = 'Not connected';

  Timer?
      connectionTimeout; // Add timeout timer to keep from freezing when wifi networks are switched

  void connectToWebSocket() {
    if (isConnecting || isConnected) return; // Prevent multiple connections

    setState(() {
      isConnecting = true;
      connectionStatus = 'Connecting...';
    });

    // Set connection timeout
    connectionTimeout = Timer(Duration(seconds: 5), () {
      if (isConnecting && mounted) {
        print('Connection timeout reached');
        _handleConnectionFailure('Connection timeout');
      }
    });

    try {
      print('About to create WebSocket connection');

      // Create connection directly
      channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.4.1/ws'),
      );

      print('WebSocket connection created');
      // Send registration message immediately
      channel!.sink.add('REGISTER:$USER_WS_ID');
      print('Sent registration: REGISTER:$USER_WS_ID');

      // Set up stream listener
      channel!.stream.listen(
        (data) {
          print('Received from ESP32: $data');
          if (mounted) {
            setState(() {
              isConnected = true;
              isConnecting = false;
              connectionStatus = 'Connected';
            });
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          if (mounted) {
            setState(() {
              isConnected = false;
              isConnecting = false;
              connectionStatus = 'Connection failed: $error';
            });
          }
        },
        onDone: () {
          print('WebSocket connection closed');
          if (mounted) {
            setState(() {
              isConnected = false;
              isConnecting = false;
              connectionStatus = 'Connection closed';
            });
          }
        },
        cancelOnError: true, // Important: cancel stream on error
      );
    } catch (e) {
      print('Immediate connection exception: $e');
      _handleConnectionFailure('Connection failed: $e');
      if (mounted) {
        setState(() {
          isConnected = false;
          isConnecting = false;
          connectionStatus = 'Connection failed: $e';
        });
      }
    }
  }

  // Helper method to handle connection failures
  void _handleConnectionFailure(String errorMessage) {
    connectionTimeout?.cancel();

    if (mounted) {
      setState(() {
        isConnected = false;
        isConnecting = false;
        connectionStatus = errorMessage;
      });
    }

    // Clean up the channel
    try {
      channel?.sink.close();
    } catch (e) {
      print('Error closing channel: $e');
    }
    channel = null;
  }

// Update Fan 1 display
  void _updateSelectedColorFan1(Color color) {
    setState(() => fan1SelectedColor = color);
    final now = DateTime.now();

    if (_fan1LastColorSent == null ||
        now.difference(_fan1LastColorSent!) >= Duration(milliseconds: 200)) {
      _fan1ColorSendTimer?.cancel();
      if (displayOptions.indexOf(fan1Display) == 2) {
        // Display custom circle only if selected
        final hex =
            '11:DISPLAY:${displayOptions.indexOf(fan1Display)}:0x${fan1SelectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}:${fan1CirclePosition.toInt() - 1}:';
        try {
          channel?.sink.add(hex);
          print('Sent color: COLOR:$hex');
        } catch (e) {
          print('Failed sending color: $e');
        }
      } else {
        // Display normal preloaded image
        try {
          channel?.sink
              .add('11:DISPLAY:${displayOptions.indexOf(fan1Display)}:');
        } catch (e) {
          print('Failed sending color: $e');
        }
      }
      _fan1LastColorSent = DateTime.now();
    }
  }

  // Update Fan 2 display
  void _updateSelectedColorFan2(Color color) {
    setState(() => fan2SelectedColor = color);
    final now = DateTime.now();

    if (_fan2LastColorSent == null ||
        now.difference(_fan2LastColorSent!) >= Duration(milliseconds: 200)) {
      _fan2ColorSendTimer?.cancel();
      if (displayOptions.indexOf(fan2Display) == 2) {
        // Display custom circle only if selected
        final hex =
            '21:DISPLAY:${displayOptions.indexOf(fan2Display)}:0x${fan2SelectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}:${fan2CirclePosition.toInt() - 1}:';
        try {
          channel?.sink.add(hex);
          print('Sent color: COLOR:$hex');
        } catch (e) {
          print('Failed sending color: $e');
        }
      } else {
        // Display normal preloaded image
        try {
          channel?.sink
              .add('21:DISPLAY:${displayOptions.indexOf(fan2Display)}:');
        } catch (e) {
          print('Failed sending color: $e');
        }
      }
      _fan2LastColorSent = DateTime.now();
    }
  }

  // Show color wheel when fan 1 custom circle is selected
  void _showColorPickerDialogFan1() {
    Color tempColorFan1 = fan1SelectedColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColorFan1,
              onColorChanged: (Color color) {
                // update dialog preview
                setState(() => tempColorFan1 = color);
                // store & send as the value changes
                _updateSelectedColorFan1(color);
              },
              enableAlpha: false, // Enable alpha slider
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  fan1SelectedColor = tempColorFan1;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show color wheel when fan 1 custom circle is selected
  void _showColorPickerDialogFan2() {
    Color tempColorFan2 = fan2SelectedColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColorFan2,
              onColorChanged: (Color color) {
                // update dialog preview
                setState(() => tempColorFan2 = color);
                // store & send as the value changes
                _updateSelectedColorFan2(color);
              },
              enableAlpha: false, // Enable alpha slider
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  fan2SelectedColor = tempColorFan2;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

void _RestartFan() {
  // Reinitialise all variables
    motorSpeed = 0;
    fan1CirclePosition = 18;
    fan2CirclePosition = 18;
    fan1SelectedColor = Colors.blue; // currently selected colour
    fan2SelectedColor = Colors.blue; // currently selected colour
    fan1Display =
        displayOptions[0]; //Global variable to store Fan1 display image
    fan1On = false;
    fan2Display =
        displayOptions[0]; //Global variable to store Fan2 display image
    fan2On = false;
    enableFanStop = false;
    fanShutdown = false; // Track if fans have been shut down due to accel event
    enableFanStop = false;
    channel!.sink.add('RESTART');
}


////////////////////////////////////////////////////////
////The following section implements accelerometer support to trigger fan shut-off for safety to prevent accidental injury
  // accelerometer helpers

  @override
  void initState() {
    super.initState();
    // start listening but don't block UI
    _accelSub = userAccelerometerEventStream().listen((event) {
      final mag = sqrt(event.x * event.x +
          event.y * event.y +
          event.z *
              event.z); // Calculate magnitude of acceleration accross all axes
      print('Accel magnitude: $mag'); // Check in debug console
      if (mag > accelThreshold) {
        _onAccelerated(mag);        
      }
    }, onError: (err) {
      print('Accelerometer error: $err');
    });
  }

  void _onAccelerated(double magnitude) {
    if (!enableFanStop) return; // Only trigger if enabled
    try {
      channel!.sink.add('${-1}');
      setState(() {
        fanShutdown = true;
      });
      
      print('Sent accel message: ${-1}');
    } catch (e) {
      print('Failed to send accel message: $e');
    }
  }
  /////////////////////////////////////////////////////////////////////

  @override
  void dispose() {
    _accelSub?.cancel();
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Build start');
    final theme = Theme.of(context); //Get global theme

    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.primary, //Set text style color
      fontWeight: FontWeight.bold,
    );

    //Limit text overflow in dropdowns
    final bool layoutExpanded = MediaQuery.of(context).size.width >= 600;

    print('Scaffold start');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Connection Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(connectionStatus),
              ],
            ),
            SizedBox(height: 20),
            if (!isConnected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    //Connect to server
                    onPressed: isConnecting ? null : connectToWebSocket,
                    child: Text(isConnecting ? 'Connecting...' : 'Connect'),
                  ),
                ],
              ),
            ],          

            if (isConnected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!fanShutdown) ...[
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          enableFanStop = !enableFanStop;
                        });
                      },
                      child: Text(enableFanStop
                          ? 'Disable Fan Stop'
                          : 'Enable Fan Stop'),
                    ),
                  ] else ... [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _RestartFan();
                        });
                      },
                      child: Text('Restart fan system'),
                    ),
                  ],

                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      //Disconnect from server
                      channel?.sink.close();
                      setState(() {
                        isConnected = false;
                        isConnecting = false;
                        connectionStatus = 'Lost connection';
                      });
                    },
                    child: Text('Disconnect'),
                  ),
                ],
              ),
              if (!fanShutdown) ...[
                SizedBox(height: 20),
                //Fan 1 Controls
                IntrinsicHeight(
                  // Wrap Row with IntrinsicHeight
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 20),
                          Text("Fan 1 Controls"),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.center, // Add this line
                            children: [
                              Text("Image:"),
                              SizedBox(
                                width: 5,
                              ),
                              SizedBox(
                                width: layoutExpanded ? 200 : 75,
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: fan1Display,
                                  items: displayOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        overflow: layoutExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        maxLines: 5,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      fan1Display = newValue!;
                                      fan1On =
                                          true; // Auto turn on fan when changing display
                                    });
                                    _updateSelectedColorFan1(fan1SelectedColor);
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: (!fan1On)
                                ? () {
                                    setState(() {
                                      fan1On = true;
                                    });
                                    _updateSelectedColorFan1(fan1SelectedColor);
                                  }
                                : null,
                            child: Text('Turn ON'),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: (fan1On)
                                ? () {
                                    setState(() {
                                      fan1On = false;
                                    });
                                    channel!.sink.add('11:DISPLAY:${-1}:');
                                  }
                                : null,
                            child: Text('Turn OFF'),
                          ),
                          if (displayOptions.indexOf(fan1Display) == 2) ...[
                            SizedBox(height: 20),
                            Text('Circle Radius'),
                            SizedBox(
                              width: 100,
                              child: Slider(
                                value: fan1CirclePosition,
                                min: 1,
                                max: 18,
                                divisions: 18,
                                label: (fan1CirclePosition).toInt().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    fan1CirclePosition = value;
                                  });
                                  _updateSelectedColorFan1(fan1SelectedColor);
                                },
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showColorPickerDialogFan1,
                              icon: Icon(Icons.color_lens,
                                  color: fan1SelectedColor),
                              label: Text(
                                'Color',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Vertical line between columns - now auto stretches
                      Container(
                        width: 1,
                        color: Colors.grey,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                      ),
                      //Fan 2 Controls
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 20),
                          Text("Fan 2 Controls"),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.center, // Add this line
                            children: [
                              Text("Image:"),
                              SizedBox(
                                width: 5,
                              ),
                              SizedBox(
                                width: layoutExpanded ? 200 : 75,
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: fan2Display,
                                  items: displayOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        overflow: layoutExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        maxLines: 5,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      fan2Display = newValue!;
                                      fan2On =
                                          true; // Auto turn on fan when changing display
                                    });
                                    _updateSelectedColorFan2(fan2SelectedColor);
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: (!fan2On)
                                ? () {
                                    setState(() {
                                      fan2On = true;
                                    });
                                    _updateSelectedColorFan2(fan2SelectedColor);
                                  }
                                : null,
                            child: Text('Turn ON'),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: (fan2On)
                                ? () {
                                    setState(() {
                                      fan2On = false;
                                    });
                                    channel!.sink.add('21:DISPLAY:${-1}:');
                                  }
                                : null,
                            child: Text('Turn OFF'),
                          ),
                          // custom circle controls for Fan 2 (match Fan 1 behavior)
                          if (displayOptions.indexOf(fan2Display) == 2) ...[
                            SizedBox(height: 20),
                            Text('Circle Radius'),
                            SizedBox(
                              width: 100,
                              child: Slider(
                                value: fan2CirclePosition,
                                min: 1,
                                max: 18,
                                divisions: 18,
                                label: (fan2CirclePosition).toInt().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    fan2CirclePosition = value;
                                  });
                                  _updateSelectedColorFan2(fan2SelectedColor);
                                },
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showColorPickerDialogFan2,
                              icon: Icon(Icons.color_lens,
                                  color: fan2SelectedColor),
                              label: Text(
                                'Color',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 30),
                        Text('Fan Speed', style: style),
                        Slider(
                          value: motorSpeed,
                          min: 0,
                          max: 100,
                          divisions: 50,
                          label: (motorSpeed).toInt().toString(),
                          onChanged: (value) {
                            setState(() {
                              motorSpeed = value;
                            });
                            channel!.sink.add(
                                'MOTOR_SPEED:${(motorSpeed.toInt() / 100) * 150}'); //Send and Convert to lower range for safety (speed limit max 1800 rpm no load)
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              textAlign: TextAlign.center,
              'Welcome to your Holo3D Fan System',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                children: [
                  TextSpan(
                      text:
                          "Please connect to the \"Holo3D\" Wi-Fi hotspot after switching on the fan system.\n\nTo control the fans, press the \""),
                  WidgetSpan(
                      child: Icon(Symbols.mode_fan,
                          size: theme.textTheme.bodyMedium?.fontSize)),
                  TextSpan(
                      text:
                          "\" icon from the navigation rail on the left.\n\n"),
                ],
              ),
            ),
            Expanded(
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }
}
