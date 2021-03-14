import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math';

ThemeMode _themeMode;

final dataCount = GetStorage();

void main() async {
  await GetStorage.init();
  dataCount.getKeys();
  var themeMode = dataCount.read('themeMode');
  if (themeMode == 0) {
    _themeMode = ThemeMode.system;
    _themeModes = 0;
  } else if (themeMode == 1) {
    _themeMode = ThemeMode.dark;
    _themeModes = 1;
  } else if (themeMode == 2) {
    _themeMode = ThemeMode.light;
    _themeModes = 2;
  } else {
    _themeMode = ThemeMode.system;
    _themeModes = 0;
  }
  runApp(GetMaterialApp(
      home: MainPage(),
      themeMode: _themeMode,
      theme: _lightThemeData,
      darkTheme: _darkThemeData));
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

int _themeModes;
bool locTrigger = true;
SharedPreferences sharedPrefs;

ThemeData _darkThemeData = new ThemeData(
  accentColor: Color(0x2AFFFFFF),
  brightness: Brightness.dark,
  accentColorBrightness: Brightness.dark,
  bottomNavigationBarTheme:
      BottomNavigationBarThemeData(backgroundColor: Colors.black),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.black38, foregroundColor: Colors.white),
);

ThemeData _lightThemeData = new ThemeData(
    primarySwatch: Colors.indigo,
    accentColor: Colors.white,
    brightness: Brightness.light,
    accentColorBrightness: Brightness.light,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo, foregroundColor: Colors.white));

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext mainContext) {
    print("MyApp Building..");
    // _themeSettingsGetter();

    return MaterialApp(
        key: keyApp,
        home: MainPage(),
        themeMode: _themeMode,
        theme: _lightThemeData,
        darkTheme: _darkThemeData);
  }
}

List<Station> stations = [];
List<Station> newStations = [];
List<Station> mainCardStations = [];

final GlobalKey<ScaffoldState> keyApp = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldState> keyMain = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldState> keySettings = GlobalKey<ScaffoldState>();

final SnackBar snackBarSuccess =
    const SnackBar(content: Text('데이터를 불러오는데 성공하였습니다.'));

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
  double dist;

  Station(this.line, this.name, this.code, this.lat, this.lng, this.dist);
}

List<Stations> parseStations(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Stations>((json) => Stations.fromJson(json)).toList();
}

var lightNavBar = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0x10000000),
    systemNavigationBarIconBrightness: Brightness.dark);
var darkNavBar = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light);

class MainPageState extends State<MainPage> {
  final textBoxController = TextEditingController();
  bool isFired = false;
  bool isLocAllowed = false;
  SharedPreferences sharedPrefs;
  Future _getLocalStations;
  Future _getMainCards;
  Future _getLocations;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() => sharedPrefs = prefs);
      isFired = false;
      _getLocations = getLocation();
      //TODO: iOS Doesn't load newstations and display them, needs debug.
      _getLocalStations = getLocalStations();
      _getMainCards = getMainCards();
    });
  }

  LocationPermission locationPermission = LocationPermission.denied;
  StreamSubscription<Position> _positionStreamSubscription;
  Position _position;
  var firstStationName = '';

  double getDistanceNum(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<List<Station>> getMainCards() async {
    if (_position != null && newStations[0] != null) {
      if (firstStationName != newStations[0].name) {
        firstStationName = newStations[0].name;
        mainCardStations = [];
        for (var station in stations) {
          if (station.name == firstStationName) {
            mainCardStations.add(station);
            mainCardStations.last.dist = getDistanceNum(_position.latitude,
                _position.longitude, newStations[0].lat, newStations[0].lng);
          }
        }
        return mainCardStations;
      }
    }
    return mainCardStations;
  }

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
      }).listen((position) {
        setState(() {
          _position = position;
          print('${_position.longitude}, ${_position.latitude}');
        });
      });
    }
    setState(() {});
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

  Future<List<Station>> getLocalStations() async {
    if (!isFired) {
      isFired = true;
      print('0');
      if (stations.length == 0) {
        var data = await rootBundle.loadString('res/stations_data.json');
        var jsonData = json.decode(data);
        for (var i in jsonData) {
          Station station = Station(
              i['line'], i['name'], i['code'], i['lat'], i['lng'], i['']);
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
    // newStations.sort();
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

  String getDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    var b = 12742 * asin(sqrt(a));
    var c = "";
    if (b >= 1)
      c = b.toStringAsFixed(1) + 'km';
    else if (b < 1) c = b.toStringAsFixed(3).replaceRange(0, 2, "") + 'm';
    return c;
  }

  @override
  Widget build(BuildContext context) {
    var navBarColor = Color(0x10000000);
    Brightness navBarIconBrightness = Brightness.dark;
    var brightness = MediaQuery.platformBrightnessOf(context);
    if (_themeModes == 0 && brightness == Brightness.dark) {
      navBarColor = darkNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.light;
    } else if (_themeModes == 0 && brightness == Brightness.light) {
      navBarColor = lightNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.dark;
    } else if (_themeModes == 1) {
      navBarColor = darkNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.light;
    } else if (_themeModes == 2) {
      navBarColor = lightNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.dark;
    }
    print('mainPage Building..');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
          systemNavigationBarColor: navBarColor,
          systemNavigationBarIconBrightness: navBarIconBrightness),
      child: Scaffold(
          key: keyMain,
          appBar: AppBar(
            title: Text('Quick Subway'),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsPage()));
                  }),
            ],
          ),
          body: Column(children: [
            Expanded(
                child: FutureBuilder(
                    future: getMainCards(),
                    builder:
                        (BuildContext mainCardContext, AsyncSnapshot snapshot) {
                      if (snapshot.data == null) {
                        return Text('not loaded');
                      } else {
                        return ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder:
                                (BuildContext mainCardBuildContext, int index) {
                              return Card(
                                  child: Container(
                                      child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                          snapshot.data[index].name +
                                              '    ' +
                                              snapshot.data[index].line,
                                          style: TextStyle(fontSize: 16)),
                                      Spacer(),
                                      if (snapshot.data[index] ==
                                          snapshot.data[0])
                                        Card(
                                            //this will only add distances in the first maincard section.
                                            child: Text(
                                                getDistance(
                                                    _position.latitude,
                                                    _position.longitude,
                                                    snapshot.data[index].lat,
                                                    snapshot.data[index].lng),
                                                style: TextStyle(fontSize: 16)))
                                    ],
                                  ),
                                ],
                              )));
                            });
                      }
                    })),
            Expanded(
                child: FutureBuilder(
                    future: _getLocalStations,
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
                            itemBuilder:
                                (BuildContext buildContext, int index) {
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
                                      title: Text(snapshot.data[index].name,
                                          style: TextStyle(fontSize: 16)),
                                      subtitle: Text(snapshot.data[index].line,
                                          style: TextStyle(fontSize: 16)),
                                      trailing: Text(
                                        getDistance(
                                            _position.latitude,
                                            _position.longitude,
                                            snapshot.data[index].lat,
                                            snapshot.data[index].lng),
                                        style: TextStyle(fontSize: 16),
                                      )));
                            });
                      }
                    })),
          ]),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showMyDialog();
            },
            child: Icon(Icons.add),
          )),
    );
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  SettingsState createState() => SettingsState();
}

int dropDownValue;

class SettingsState extends State<SettingsPage> {
  @override
  Widget build(context) {
    var navBarColor = Color(0x10000000);
    Brightness navBarIconBrightness = Brightness.dark;
    var brightness = MediaQuery.platformBrightnessOf(context);
    if (_themeModes == 0 && brightness == Brightness.dark) {
      navBarColor = darkNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.light;
    } else if (_themeModes == 0 && brightness == Brightness.light) {
      navBarColor = lightNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.dark;
    } else if (_themeModes == 1) {
      navBarColor = darkNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.light;
    } else if (_themeModes == 2) {
      navBarColor = lightNavBar.systemNavigationBarColor;
      navBarIconBrightness = Brightness.dark;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
            systemNavigationBarColor: navBarColor,
            systemNavigationBarIconBrightness: navBarIconBrightness),
        child: Scaffold(
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
                        var brightness =
                            MediaQuery.of(context).platformBrightness;
                        if (value == 0) {
                          if (brightness == Brightness.dark) {
                            Get.changeThemeMode(ThemeMode.dark);
                            dataCount.write('themeMode', 0);
                            _themeModes = 0;
                            SystemChrome.setSystemUIOverlayStyle(darkNavBar);
                          } else if (brightness == Brightness.light) {
                            Get.changeThemeMode(ThemeMode.light);
                            dataCount.write('themeMode', 0);
                            _themeModes = 0;
                            SystemChrome.setSystemUIOverlayStyle(lightNavBar);
                          }
                        }
                        if (value == 1) {
                          Get.changeThemeMode(ThemeMode.dark);
                          dataCount.write('themeMode', 1);
                          _themeModes = 1;
                          SystemChrome.setSystemUIOverlayStyle(darkNavBar);
                        }
                        if (value == 2) {
                          Get.changeThemeMode(ThemeMode.light);
                          dataCount.write('themeMode', 2);
                          _themeModes = 2;
                          SystemChrome.setSystemUIOverlayStyle(lightNavBar);
                        }
                      });
                    },
                  ),
                ),
              ]),
            ))));
  }
}
