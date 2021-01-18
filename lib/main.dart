import 'dart:io';
import 'dart:ui';
import 'dart:async';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
// import 'package:location_permissions/location_permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import './stations.dart';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:location_permissions/location_permissions.dart' as loc;
import 'package:get/get.dart';

main() => runApp(GetMaterialApp(home: MyApp()));

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
        backgroundColor: Colors.indigo, foregroundColor: Colors.white)
);

int _themeModes;
// final Location location = Location();

bool locTrigger = true;

SharedPreferences sharedPrefs;
String _error;

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() => sharedPrefs = prefs);
      var brightness = SchedulerBinding.instance.window.platformBrightness;

      stations = [];
      newStations = [];

      if (prefs.getInt('themeModes') == 0) {
        if (brightness == Brightness.dark) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        }
        if (brightness == Brightness.light) {
          // SystemChrome.setSystemUIOverlayStyle(new SystemUiOverlayStyle(
          //     systemNavigationBarColor: Color(0x10000000),
          //     systemNavigationBarIconBrightness: Brightness.dark));
        }
      }
      if (prefs.getInt('themeModes') == 1) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      }
      if (prefs.getInt('themeModes') == 2) {
        // SystemChrome.setSystemUIOverlayStyle(new SystemUiOverlayStyle(
        //     systemNavigationBarColor: Color(0x10000000),
        //     systemNavigationBarIconBrightness: Brightness.dark));
      }
    });
  }
}

List<Station> stations = [];
List<Station> newStations = [];

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

final String apiKey = '4f62534574626c613132315a4565564f';

final Text msgNoMatch = Text(
  '해당 역을 찾지 못하였습니다.',
  style: TextStyle(color: Colors.red),
);

final Text msgFailConnection = Text(
  '서버 연결에 실패하였습니다.',
  style: TextStyle(color: Colors.red),
);

final Text msgNoInput = Text(
  '역 이름이 입력되지 않았습니다.',
  style: TextStyle(color: Colors.red),
);

final Text msgDuplicate = Text(
  '이미 추가된 역입니다.',
  style: TextStyle(color: Colors.red),
);

final Text defText = Text('역 이름을 \'역\' 글자를 빼고 입력해 주세요. (예:서울역 → 서울)');

Text statusMsg = defText;

Future<bool> addStation(String stationName) async {
  String stationNameInput = '';
  var parsed = json.decode(null);
  print(parsed.toString());
  if (stationName == '') return false;
  stationNameInput = stationName;

  // var rawData = await http.get(requestUrl);
  // var body = utf8.decode(rawData.bodyBytes);
  // var data = XmlDocument.parse(body);
  // var statCode = data
  //     .findAllElements('status')
  //     .first
  //     .text;
  // print(statCode);
  //
  // if (statCode == '200') {
  //   statusMsg = defText;
  //   return true;
  // }
  // else if (statCode == '500') {
  //   statusMsg = msgNoMatch;
  //   return false;
  // }
  // else if (statCode != '200' && statCode != '500') {
  //   statusMsg = msgFailConnection;
  //   return false;
  // }
  return true;
}

Future<bool> addStations(String stationName) async {
  String stationNameInput = '';
  if (stationName == '') return false;
  stationNameInput = stationName;
  String requestUrl =
      'http://swopenapi.seoul.go.kr/api/subway/$apiKey/xml/realtimeStationArrival/1/5/$stationNameInput';
  print(requestUrl);
  var rawData = await http.get(requestUrl);
  var body = utf8.decode(rawData.bodyBytes);
  var data = XmlDocument.parse(body);
  var statCode = data.findAllElements('status').first.text;
  print(statCode);

  if (statCode == '200') {
    statusMsg = defText;
    return true;
  } else if (statCode == '500') {
    statusMsg = msgNoMatch;
    return false;
  } else if (statCode != '200' && statCode != '500') {
    statusMsg = msgFailConnection;
    return false;
  }
  return true;
}

class Stations {
  final String lineNum;
  final String stationName;
  final int stationNum;
  final double latitude;
  final double longitude;

  Stations(
      {this.lineNum,
      this.stationName,
      this.stationNum,
      this.latitude,
      this.longitude});

  factory Stations.fromJson(Map<String, dynamic> json) {
    return Stations(
        lineNum: json['line'] as String,
        stationName: json['name'] as String,
        stationNum: json['code'] as int,
        latitude: json['lat'] as double,
        longitude: json['lng'] as double);
  }
}

class Station {
  final String line;
  final String name;
  final int code;
  final double lat;
  final double lng;

  Station(this.line, this.name, this.code, this.lat, this.lng);
}

List<Stations> parseStations(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Stations>((json) => Stations.fromJson(json)).toList();
}

class MainPageState extends State<MainPage> {
  final textBoxController = TextEditingController();

  // @override
  // void dispose() {
  //   super.dispose();
  //   textBoxController.dispose();
  //   _stopListen();
  // }

  bool isFired = false;
  bool isLocAllowed = false;

  SharedPreferences sharedPrefs;
  //
  // Future<void> _stopListen() async {
  //   _locationSubscription.cancel();
  // }

  Future _getLocalStations;

  // LocationData _location;

  @override
  void initState() {
    super.initState();
    // getLocPermission().then((value) {
    SharedPreferences.getInstance().then((prefs) {
      setState(() => sharedPrefs = prefs);
      isFired = false;
      _getLocalStations = getLocalStations();
      stations = [];
      newStations = [];
    });
    // });
  }

  // Future<void> getLocation() async {
  //   try {
  //     await location.serviceEnabled();
  //   } on Exception catch (_) {
  //     return null;
  //   }
  //   var result = await location.requestPermission();
  //   if (result == PermissionStatus.granted) {
  //     print(result);
  //     location.enableBackgroundMode();
  //     _locationSubscription =
  //         location.onLocationChanged.handleError((dynamic err) {
  //       setState(() {
  //         _error = err.code;
  //       });
  //     }).listen((LocationData currentLocation) {
  //       setState(() {
  //         _error = null;
  //         _location = currentLocation;
  //         print(_location.longitude.toString());
  //       });
  //     });
  //   }
  // }
  LocationPermission locationPermission = LocationPermission.denied;
  StreamSubscription<Position> _positionStreamSubscription;
  Position _position;

  Future<void> getLocation() async {
    locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied)
      await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.deniedForever)
      locationFailedDialog();
    if (locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse) {
      final _positionStream = Geolocator.getPositionStream();
      _positionStreamSubscription = _positionStream.handleError((onError) {
        _positionStreamSubscription.cancel();
        _positionStreamSubscription = null;
      }).listen((position) {setState(() {
        _position = position;
        print('${_position.longitude}, ${_position.latitude}');
      }); });
    }
  }

  void locationFailedDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('위치 오류'),
          content: Text('앱의 위치 권한이 거부되었습니다. 앱 설정에서 위치 권한을 허용해 주세요'),
          actions: [
            TextButton(
              child: Text('앱 설정으로 이동'),
              onPressed: () => Geolocator.openLocationSettings(),
            ),
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  // Future<void> getLocPermission() async {
  //   loc.PermissionStatus permission =
  //       await loc.LocationPermissions().checkPermissionStatus();
  //
  //   if (permission != loc.PermissionStatus.granted)
  //     await loc.LocationPermissions().requestPermissions();
  // }

  // StreamSubscription<LocationData> _locationSubscription;

  Future<List<Station>> getLocalStations() async {
    if (!isFired) {
      isFired = true;
      print('0');
      if (stations.length == 0) {
        var data = await rootBundle.loadString('res/stations_data.json');
        var jsonData = json.decode(data);
        for (var i in jsonData) {
          Station station =
              Station(i['line'], i['name'], i['code'], i['lat'], i['lng']);
          stations.add(station);
        }
      }
      print('number of newStations are ' + newStations.length.toString());
      print('number of stations are ' + stations.length.toString());
      print('1');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print('2');
      List<String> localStationsNameList = prefs.getStringList('stationName');
      if (localStationsNameList == null) {
        localStationsNameList = [];
        newStations = [];
        return newStations;
      }
      print('localstationnamelists are' +
          localStationsNameList.length.toString());
      for (var i in localStationsNameList) {
        for (var j in stations) {
          if (j.name == i) {
            newStations.add(j);
            break;
          }
        }
      }
    }
    if (newStations == null) newStations = [];
    print('returning');
    return newStations;
  }

  Future<List<Stations>> loadStations() async {
    final response = await rootBundle.loadString('res/stations_data.json');
    return compute(parseStations, response);
  }

  Future<void> removeStation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('removing station');
    List<String> stations = [];
    newStations.forEach((e) {
      stations.add(e.name);
    });
    prefs.setStringList('stationName', stations);
  }

  Future<int> setLocalStations(String stationName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('setting names');
    List<String> stationNames = [];
    stationNames = prefs.getStringList('stationName');
    if (stationNames == null) stationNames = [];
    for (var i in stationNames) if (i == stationName) return 1;

    for (var i in stations) {
      if (i.name == stationName) {
        newStations.add(i);
        stationNames.add(stationName);
        await prefs.setStringList('stationName', stationNames);
        print('setting names succeeded');
        return 0;
      }
    }
    return 2;
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
        body: Container(
            child: FutureBuilder(
                future: _getLocalStations.whenComplete(() => getLocation()),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.data == null) {
                    return Container(
                        child: Center(
                            child: CircularProgressIndicator(
                      backgroundColor: Colors.black12,
                    )));
                  } else {
                    return ListView.builder(
                        itemCount: snapshot.data.length,
                        itemBuilder: (BuildContext buildContext, int index) {
                          var item = newStations[index];
                          return Dismissible(
                              key: Key(item.name.toString()),
                              onDismissed: (direction) {
                                setState(() {
                                  newStations.removeAt(index);
                                  removeStation();
                                });
                              },
                              background: Container(color: Colors.red),
                              child: ListTile(
                                title: Text(snapshot.data[index].name),
                                trailing: Text(snapshot.data[index].line),
                                subtitle: Text('${_position.latitude}, ${_position.longitude}'),
                              ));
                        });
                  }
                })),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showMyDialog();
            keyMain.currentState.build(context);
          },
          child: Icon(Icons.add),
        ));
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
                      statusMsg,
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
                      statusMsg = defText;
                    },
                  ),
                  TextButton(
                    child: Text('추가'),
                    onPressed: () async {
                      var result =
                          await setLocalStations(textBoxController.text);
                      setState(() {
                        if (textBoxController.text == '')
                          statusMsg = msgNoInput;
                        else if (result == 1) {
                          statusMsg = msgDuplicate;
                        } else if (result == 2) {
                          statusMsg = msgNoMatch;
                        } else if (result == 0 &&
                            textBoxController.text != '') {
                          print('adding station successful');
                          Navigator.of(context).pop();
                          textBoxController.clear();
                          keyMain.currentState.build(context);
                        }
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
          title: Text('설정'),
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
                      Get.changeTheme(ThemeData.dark());
                      SystemChrome.setSystemUIOverlayStyle(
                          SystemUiOverlayStyle.dark);
                    }
                    if (value == 2) {
                      Get.changeTheme(ThemeData.light());
                      SystemChrome.setSystemUIOverlayStyle(
                          new SystemUiOverlayStyle(
                              systemNavigationBarColor: Color(0x10000000),
                              systemNavigationBarIconBrightness:
                                  Brightness.dark)

                      );
                    }

                  });
                },
              ),
            ),
          ]),
        )));
  }
}
