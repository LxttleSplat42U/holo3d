import 'dart:async';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; //Use for WebSocket

bool Fan1_LED = true; //Global variable to store LED state

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
        page = GeneratorPage();

      case 1:
        page = FavouritesPage();

      case 2:
        page = Fan1();

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
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Symbols.mode_fan),
                    label: Text('Fan1'),
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

class Fan1 extends StatefulWidget {
  const Fan1({Key? key}) : super(key: key);

  @override
  State<Fan1> createState() => _Fan1State();
}

class _Fan1State extends State<Fan1> {
  static const List<String> displayOptions = ['Circle', 'Spiral'];
  String fan1Display = displayOptions[0]; //Global variable to store Fan1 display image
  bool fan1On = false;
  String fan2Display = displayOptions[0]; //Global variable to store Fan2 display image
  bool fan2On = false;

  //Connect to WebSocket
  WebSocketChannel? channel; // Make nullable
  double motorSpeed = 0;
  bool isConnected = false; 
  bool isConnecting = false; 
  String connectionStatus = 'Not connected';

Timer? connectionTimeout; // Add timeout timer to keep from freezing when wifi networks are switched

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

  @override
  void dispose() {
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
                          SizedBox(width: 10),
                          DropdownButton<String>(
                            value: fan1Display,
                            items: displayOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                fan1Display = newValue!;
                                fan1On = true; // Auto turn on fan when changing display
                              });
                              channel!.sink.add('FAN_11:DISPLAY:${displayOptions.indexOf(fan1Display)}');
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),                      
                      ElevatedButton(
                        onPressed: (!fan1On) ? () {
                          setState(() {
                            fan1On = true;                        
                          });
                          channel!.sink.add('FAN_11:DISPLAY:${displayOptions.indexOf(fan1Display)}');
                        } : null,
                        child: Text('Turn ON'),
                      ),                      
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: (fan1On) ? () {
                          setState(() {
                            fan1On = false;
                          });
                          channel!.sink.add('FAN_11:DISPLAY:${-1}');
                        } : null,
                        child: Text('Turn OFF'),
                      ),
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
                          SizedBox(width: 10),
                          DropdownButton<String>(
                            value: fan2Display,
                            items: displayOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                fan2Display = newValue!;
                                fan2On = true; // Auto turn on fan when changing display
                              });                              
                              channel!.sink.add('FAN_12:DISPLAY:${displayOptions.indexOf(fan2Display)}');
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: (!fan2On) ? () {
                          setState(() {
                            fan2On = true;
                          });
                          channel!.sink.add('FAN_12:DISPLAY:${displayOptions.indexOf(fan2Display)}');
                        } : null,
                        child: Text('Turn ON'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: (fan2On) ? () {
                          setState(() {
                            fan2On = false;
                          });
                          channel!.sink.add('FAN_12:DISPLAY:${-1}');
                        } : null,
                        child: Text('Turn OFF'),
                      ),
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
                      divisions: 20,
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
        ),
      ),
    );
  }
}

class FavouritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); //Get global theme

    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.primary, //Set text style color
      fontWeight: FontWeight.bold,
    );

    var appState = context.watch<MyAppState>();

    return Scaffold(
        body: ListView(
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              color: theme.primaryColor,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'You have ${appState.fav.length} favourites:',
              style: style,
            ),
          ],
        ),
        for (var msg in appState.fav)
          ListTile(
            title: Text(msg.asPascalCase),
          ),
      ],
    ));
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    //Like Icon
    IconData likeIcon;
    if (appState.fav.contains(pair)) {
      likeIcon = Icons.favorite;
    } else {
      likeIcon = Icons.favorite_outline_outlined;
    }

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 150,
            child: ListView(
              controller: appState._scrollController,
              children: [
                for (var msg in appState.allWordPairs)
                  if (appState.fav.contains(msg))
                    ListTile(
                      title: Text(msg.asPascalCase),
                      leading: Icon(Icons.favorite),
                    )
                  else
                    ListTile(title: Text(msg.asPascalCase))
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BigCard(pair: pair),
                SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min, // Use minimum row space
                  children: [
                    //Next button
                    ElevatedButton(
                      onPressed: () {
                        appState.getNext();
                      },
                      child: Text('Next'),
                    ),

                    SizedBox(width: 20), //Some space

                    //Like Button
                    ElevatedButton.icon(
                      onPressed: appState.toggleFavourite,
                      label: Text('Like'),
                      icon: Icon(likeIcon),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); //Get global theme

    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary, //Set text style color
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Text(
          pair.asPascalCase,
          style: style,
          semanticsLabel:
              "${pair.first} ${pair.second}", //For screen readers, sepearates the words better
        ), //Display text and style
      ),
    );
  }
}
