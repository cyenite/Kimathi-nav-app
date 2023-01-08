import 'dart:async';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_mapbox_navigation/library.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double userLatitude = 0;
  double userLongitude = 0;

  WayPoint _userLocation;

  String _instruction = "";

  final _stop1 = WayPoint(
      name: "Engineering Block",
      latitude: -0.3986761415323495,
      longitude: 36.962461463328836);

  MapBoxNavigation _directions;
  MapBoxOptions _options;

  bool _arrived = false;
  bool _isMultipleStop = false;
  double _distanceRemaining, _durationRemaining;
  MapBoxNavigationViewController _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;

  bool _isDestinationSelected = false;

  @override
  void initState() {
    super.initState();

    initialize();
    determineUserPosition();
  }

  Future<void> initialize() async {
    if (!mounted) return;

    _directions = MapBoxNavigation(onRouteEvent: _onEmbeddedRouteEvent);
    _options = MapBoxOptions(
        initialLatitude: 0,
        initialLongitude: 0,
        zoom: 15.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: false,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: false,
        animateBuildRoute: true,
        longPressDestinationEnabled: true,
        language: "en");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            showAnimatedDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return ClassicGeneralDialogWidget(
                  titleText: 'About App',
                  contentText:
                      'Dedan Kimathi Navigation App\n\n- Made by GEGIS & GIS 4.2, 2021 group.\n\n\ncopyright @2021',
                  negativeText: '',
                  positiveText: 'Close',
                  onPositiveClick: () {
                    Navigator.of(context).pop();
                  },
                  onNegativeClick: () {
                    Navigator.of(context).pop();
                  },
                );
              },
              animationType: DialogTransitionType.fadeScale,
              curve: Curves.fastOutSlowIn,
              duration: Duration(seconds: 1),
            );
          },
          child: Icon(Icons.info_outline, color: Colors.black54),
        ),
        centerTitle: true,
        shadowColor: Colors.grey,
        elevation: 10.0,
        backgroundColor: Colors.white,
        title: const Text(
          'Kimathi Navigation App',
          style: TextStyle(color: Colors.black54),
        ),
      ),
      body: Center(
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              color: Colors.grey,
              child: MapBoxNavigationView(
                  options: _options,
                  onRouteEvent: _onEmbeddedRouteEvent,
                  onCreated: (MapBoxNavigationViewController controller) async {
                    _controller = controller;
                    controller.initialize();
                  }),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownSearch<String>(
                  mode: Mode.MENU,
                  showSelectedItem: true,
                  items: [
                    "Mess",
                    "Engineering Block",
                    "School of Business",
                    "Main Gate",
                    "Resource Center"
                  ],
                  label: "Available places",
                  hint: "Choose navigation destination",
                  popupItemDisabled: (String s) => s.startsWith('I'),
                  onChanged: (value) {
                    setState(() {
                      _isDestinationSelected = true;
                    });
                  }),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () async {
                  if (_isDestinationSelected) {
                    List<WayPoint> wayPoints = [];
                    wayPoints.add(_userLocation);
                    wayPoints.add(_stop1);

                    await _directions.startNavigation(
                        wayPoints: wayPoints,
                        options: MapBoxOptions(
                            mode: MapBoxNavigationMode.walking,
                            simulateRoute: true,
                            language: "en",
                            units: VoiceUnits.metric));
                  } else {
                    Get.snackbar('error', 'Please select destination from menu',
                        snackPosition: SnackPosition.TOP);
                  }
                },
                child: Container(
                  height: 50.0,
                  width: 200.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      Icon(
                        Icons.navigation_outlined,
                        color: Colors.white,
                        size: 30.0,
                      )
                    ],
                  ),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color:
                          _isDestinationSelected ? Colors.blue : Colors.grey),
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }

  Future<void> _onEmbeddedRouteEvent(e) async {
    _distanceRemaining = await _directions.distanceRemaining;
    _durationRemaining = await _directions.durationRemaining;

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        _arrived = progressEvent.arrived;
        if (progressEvent.currentStepInstruction != null)
          _instruction = progressEvent.currentStepInstruction;
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        _arrived = true;
        if (!_isMultipleStop) {
          await Future.delayed(Duration(seconds: 3));
          await _controller.finishNavigation();
        } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      default:
        break;
    }
    setState(() {});
  }

  Future<Position> determineUserPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('error', 'Location services are disabled.');
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('error', 'Location permissions are denied.');
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('error',
          'Location permissions are permanently denied, we cannot request permissions.');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    var userLocation = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = WayPoint(
          name: 'User location',
          latitude: userLocation.latitude,
          longitude: userLocation.longitude);
    });
    return userLocation;
  }
}
