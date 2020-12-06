import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext mainContext) {
    print("MyApp Building..");
    return MaterialApp(
        key: keyApp,
        home: MainPage(),
        themeMode: _themeMode,
        theme: ThemeData(primarySwatch: Colors.indigo),
        darkTheme: ThemeData(primarySwatch: Colors.deepPurple));
  }
}

final GlobalKey<ScaffoldState> keyApp = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldState> keyMain = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldState> keySettings = GlobalKey<ScaffoldState>();
final SnackBar snackBar = const SnackBar(content: Text('Showing Snackbar'));

ThemeMode _themeMode = ThemeMode.light;

class MainPage extends StatefulWidget {
  const MainPage({Key key}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

bool _darkTheme = false;

class MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    print('mainPage Building..');
    return Scaffold(
      key: keyMain,
      appBar: AppBar(
        title: Text('Fast Subway'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsPage()));
              }),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(5), children: <Widget>[
        Container(
          height: 50,
          child: Card(
            color: Colors.white10,
            child: Center(child: Text('1231')),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<SettingsPage> {
  @override
  Widget build(BuildContext settingsContext) {
    print("SettingsPage Building..");
    print(_themeMode.toString());
    return Scaffold(
        key: keySettings,
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Material(
            child: Card(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            SwitchListTile(
              title: const Text('다크 모드'),
              value: ,
              onChanged: (bool value) {
                setState(() {
                  _darkTheme = value;
                  if (_darkTheme == true) {
                    _themeMode = ThemeMode.dark;
                    MyAppState().build(settingsContext);
                    MainPageState().build(settingsContext);
                    SettingsState().build(settingsContext);
                  }
                  if (_darkTheme == false) {
                    _themeMode = ThemeMode.light;
                    MyAppState().build(settingsContext);
                    MainPageState().build(settingsContext);
                    SettingsState().build(settingsContext);

                  }
                });
              },
            )
          ]),
        )));
  }
}
