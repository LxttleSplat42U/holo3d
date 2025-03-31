import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
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
        
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600, //Show Label if enough space ex. Rotated
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
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
      }
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
            Icon(Icons.favorite, color: theme.primaryColor,),
            SizedBox(width: 10,),
            Text('You have ${appState.fav.length} favourites:', style: style,),
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
      body:     
       Column(
        mainAxisAlignment: MainAxisAlignment.center,
        
         children: [
          SizedBox(
            
              height: 150,
            child: ListView(
              controller: appState._scrollController,
              children: [
                for (var msg in appState.allWordPairs)
                if (appState.fav.contains(msg))
                ListTile(title: Text(msg.asPascalCase), leading: Icon(Icons.favorite),)
                else ListTile(title: Text(msg.asPascalCase))
              ],
            ),   
            ), 

           Center(        
            child: 
            Column(
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
