import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import './stations.dart';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;

main() {
  runApp(new HotRestartController(child: new MyApp()));
}

final String apiKey = '4f62534574626c613132315a4565564f';
String stationNameInput = '';
String requestUrl =
    'http://swopenapi.seoul.go.kr/api/subway/$apiKey/xml/realtimeStationArrival/1/5/$stationNameInput';

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

ThemeData _darkThemeData = new ThemeData(
    accentColor: Color(0x2AFFFFFF),
    brightness: Brightness.dark,
    accentColorBrightness: Brightness.dark,
    bottomNavigationBarTheme:
        BottomNavigationBarThemeData(backgroundColor: Colors.black),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.black38, foregroundColor: Colors.white));

ThemeData _lightThemeData = new ThemeData(
    primarySwatch: Colors.indigo,
    accentColor: Colors.white,
    brightness: Brightness.light,
    accentColorBrightness: Brightness.light,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo, foregroundColor: Colors.white));

int _themeModes;

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext mainContext) {
    print("MyApp Building..");
    _themeSettingsGetter();
    return MaterialApp(
        key: keyApp,
        home: MainPage(),
        themeMode: _themeMode,
        theme: _lightThemeData,
        darkTheme: _darkThemeData);
  }

  SharedPreferences sharedPrefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() => sharedPrefs = prefs);
      var brightness = SchedulerBinding.instance.window.platformBrightness;

      if (prefs.getInt('themeModes') == 0) {
        if (brightness == Brightness.dark) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        }
        if (brightness == Brightness.light) {
          SystemChrome.setSystemUIOverlayStyle(new SystemUiOverlayStyle(
              systemNavigationBarColor: Color(0x10000000),
              systemNavigationBarIconBrightness: Brightness.dark));
        }
      }
      if (prefs.getInt('themeModes') == 1) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      }
      if (prefs.getInt('themeModes') == 2) {
        SystemChrome.setSystemUIOverlayStyle(new SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0x10000000),
            systemNavigationBarIconBrightness: Brightness.dark));
      }
    });
  }
}

final GlobalKey<ScaffoldState> keyApp = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldState> keyMain = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldState> keySettings = GlobalKey<ScaffoldState>();

final SnackBar snackBarSuccess =
    const SnackBar(content: Text('데이터를 불러오는데 성공하였습니다.'));

ThemeMode _themeMode;

class MainPage extends StatefulWidget {
  const MainPage({Key key}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

List<String> stationsList = [];

class MainPageState extends State<MainPage> {
  final textBoxController = TextEditingController();

  @override
  void dispose() {
    textBoxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('mainPage Building..');
    return Scaffold(
      key: keyMain,
      appBar: AppBar(
        title: Text('Quick Subway'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsPage()));
              }),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(5), children: stationsList.map((e) {
        return Container(
          height: 50,
          child: Card(
            child: Center(child: Text(e)
            ),
          ),
        );
      }).toList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMyDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  final Text msgNoMatch = Text(
    '잘못된 역 이름입니다.',
    style: TextStyle(color: Colors.red),
  );

  final Text msgFailConnection = Text(
    '서버 연결에 실패하였습니다.',
    style: TextStyle(color: Colors.red),
  );


  Future<void> addStations() async{
    stationNameInput = textBoxController.text;
    print(requestUrl);
    var rawData = await http.get(requestUrl);
    var data = xml.XmlDocument.parse(rawData.body);
    stationsList.add(data.text);
  }

  _showMyDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('역 추가'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      msgFailConnection,
                      TextField(
                        controller: textBoxController,
                      )
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('취소'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      textBoxController.clear();
                    },
                  ),
                  TextButton(
                    child: Text('추가'),
                    onPressed: () {
                      setState(() {

                        addStations();
                        textBoxController.clear();
                      });
                    },
                  ),
                ],
              );
            },
          );
        });
  }
}



_themeSettingsGetter() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  _themeModes = prefs.getInt('themeModes');
  if (_themeModes == null) {
    print('thememode is null');
    _themeMode = ThemeMode.system;
    await prefs.setInt('themeModes', 0);
  }
  print('thememode is $_themeModes');
  if (_themeModes == 0) _themeMode = ThemeMode.system;
  if (_themeModes == 1) _themeMode = ThemeMode.dark;
  if (_themeModes == 2) _themeMode = ThemeMode.light;
}

_themeSettingsSetter(int value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print('setting prefs $value');
  await prefs.setInt('themeModes', value);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  SettingsState createState() => SettingsState();
}

int dropDownValue;

class SettingsState extends State<SettingsPage> {
  @override
  Widget build(BuildContext settingsContext) {
    print("SettingsPage Building..");

    return Scaffold(
        key: keySettings,
        appBar: AppBar(
          title: Text('Settings'),
          key: UniqueKey(),
        ),
        body: Material(
            child: Card(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            ListTile(
              title: Text('테마 모드'),
              trailing: DropdownButton(
                value: _themeModes,
                items: [
                  DropdownMenuItem(
                    child: Text('시스템 모드'),
                    value: 0,
                  ),
                  DropdownMenuItem(
                    child: Text('다크 모드'),
                    value: 1,
                  ),
                  DropdownMenuItem(
                    child: Text('라이트 모드'),
                    value: 2,
                  )
                ],
                onChanged: (value) {
                  setState(() {
                    _themeModes = value;
                    _themeSettingsSetter(value);
                    var brightness = MediaQuery.of(context).platformBrightness;
                    if (value == 0) {
                      if (brightness == Brightness.dark) {
                        SystemChrome.setSystemUIOverlayStyle(
                            SystemUiOverlayStyle.dark);
                      }
                      if (brightness == Brightness.light) {
                        SystemChrome.setSystemUIOverlayStyle(
                            new SystemUiOverlayStyle(
                                systemNavigationBarColor: Color(0x10000000),
                                systemNavigationBarIconBrightness:
                                    Brightness.dark));
                      }
                    }
                    if (value == 1) {
                      SystemChrome.setSystemUIOverlayStyle(
                          SystemUiOverlayStyle.dark);
                    }
                    if (value == 2) {
                      SystemChrome.setSystemUIOverlayStyle(
                          new SystemUiOverlayStyle(
                              systemNavigationBarColor: Color(0x10000000),
                              systemNavigationBarIconBrightness:
                                  Brightness.dark));
                    }
                    HotRestartController.performHotRestart(context);
                  });
                },
              ),
            ),
          ]),
        )));
  }
}

class HotRestartController extends StatefulWidget {
  final Widget child;

  HotRestartController({this.child});

  static performHotRestart(BuildContext context) {
    final _HotRestartControllerState state = context.findAncestorStateOfType();
    state.performHotRestart();
  }

  @override
  _HotRestartControllerState createState() => new _HotRestartControllerState();
}

class _HotRestartControllerState extends State<HotRestartController> {
  Key key = new UniqueKey();

  void performHotRestart() {
    this.setState(() {
      key = new UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      key: key,
      child: widget.child,
    );
  }
}
