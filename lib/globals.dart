import 'timeswitch.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

double latitude = 0;
double longitude = 0;

String version = '1.1.0';

// Azimuth/Elevation settings
String azElOption = 'Internet';
String timeAddress = '';
String dateAddress = '';
String azimuthAddress = '';
String elevationAddress = '';
String azimuthDPT = '5.003';
String elevationDPT = '5.003';
String azElTimezone = 'Europe/Zurich';

// KNX connection
String knxConnectionType = 'ROUTING';
String knxIndividualAddress = '';
String knxGatewayIp = '';
String knxGatewayPort = '';
String knxMulticastGroup = '';
String knxMulticastPort = '';
bool knxAutoReconnect = false;
String knxAutoReconnectWait = '5';

// Threshold linkage
bool linkBrightnessIrradiance = false;

List<Sector> sectors = [];

// Weekly time switch programs
List<TimeProgram> timePrograms = [];

const double kLockedAzimuthTolerance = 1e-6;

class LockedPointSpec {
  final double azimuth;
  final double defaultElevation;

  const LockedPointSpec({
    required this.azimuth,
    required this.defaultElevation,
  });
}

const List<LockedPointSpec> horizonLockedPointSpecs = [
  LockedPointSpec(azimuth: -90, defaultElevation: 0),
  LockedPointSpec(azimuth: 90, defaultElevation: 0),
];

const List<LockedPointSpec> ceilingLockedPointSpecs = [
  LockedPointSpec(azimuth: -90, defaultElevation: 90),
  LockedPointSpec(azimuth: 90, defaultElevation: 90),
];

class Sector {
  String guid;
  String id;
  late final ValueNotifier<String> nameNotifier;
  double orientation;
  bool horizonLimit;
  List<Point> horizonPoints;
  List<Point> ceilingPoints;
  bool louvreTracking;
  double louvreSpacing;
  double louvreDepth;
  double louvreAngleAtZero;
  double louvreAngleAtHundred;
  double louvreMinimumChange;
  double louvreBuffer;
  String brightnessAddress;
  String heightAddress;
  String louvreAngleAddress;
  String sunBoolAddress;
  bool useBrightness;
  bool useIrradiance;
  bool brightnessDynamicDelay;
  bool irradianceDynamicDelay;
  List<DelayPoint> brightnessHighDelayPoints;
  List<DelayPoint> brightnessLowDelayPoints;
  List<DelayPoint> irradianceHighDelayPoints;
  List<DelayPoint> irradianceLowDelayPoints;
  int? brightnessUpperThreshold;
  int? brightnessUpperDelay;
  int? brightnessLowerThreshold;
  int? brightnessLowerDelay;
  String irradianceAddress;
  int? irradianceUpperThreshold;
  int? irradianceUpperDelay;
  int? irradianceLowerThreshold;
  int? irradianceLowerDelay;
  String brightnessIrradianceLink;
  String onAutoAddress;
  String onAutoBehavior;
  String offAutoAddress;
  String offAutoBehavior;
  String facadeAddress;
  LatLng? facadeStart;
  LatLng? facadeEnd;

  Sector({
    String? guid,
    this.id = '',
    String name = '',
    this.orientation = 0,
    this.useBrightness = true,
    this.useIrradiance = true,
    this.brightnessDynamicDelay = false,
    this.irradianceDynamicDelay = false,
    List<DelayPoint>? brightnessHighDelayPoints,
    List<DelayPoint>? brightnessLowDelayPoints,
    List<DelayPoint>? irradianceHighDelayPoints,
    List<DelayPoint>? irradianceLowDelayPoints,
    this.horizonLimit = false,
    List<Point>? horizonPoints,
    List<Point>? ceilingPoints,
    this.louvreTracking = false,
    this.louvreSpacing = 0,
    this.louvreDepth = 0,
    this.louvreAngleAtZero = 90,
    this.louvreAngleAtHundred = 0,
    this.louvreMinimumChange = 20,
    this.louvreBuffer = 5,
    this.brightnessAddress = '',
    this.heightAddress = '',
    this.louvreAngleAddress = '',
    this.sunBoolAddress = '',
    this.irradianceAddress = '',
    this.brightnessIrradianceLink = 'And',
    this.onAutoAddress = '',
    this.onAutoBehavior = 'Auto',
    this.offAutoAddress = '',
    this.offAutoBehavior = 'Auto',
    this.facadeAddress = '',
    this.facadeStart,
    this.facadeEnd,
  }) : guid = guid ?? const Uuid().v4(),
       horizonPoints = ensureDefaultHorizonPoints(
         horizonPoints != null
             ? horizonPoints.map(clonePoint).toList()
             : <Point>[],
       ),
       ceilingPoints = ensureDefaultCeilingPoints(
         ceilingPoints != null
             ? ceilingPoints.map(clonePoint).toList()
             : <Point>[],
       ),
       brightnessHighDelayPoints = brightnessHighDelayPoints != null
           ? brightnessHighDelayPoints.map(cloneDelayPoint).toList()
           : <DelayPoint>[],
       brightnessLowDelayPoints = brightnessLowDelayPoints != null
           ? brightnessLowDelayPoints.map(cloneDelayPoint).toList()
           : <DelayPoint>[],
       irradianceHighDelayPoints = irradianceHighDelayPoints != null
           ? irradianceHighDelayPoints.map(cloneDelayPoint).toList()
           : <DelayPoint>[],
       irradianceLowDelayPoints = irradianceLowDelayPoints != null
           ? irradianceLowDelayPoints.map(cloneDelayPoint).toList()
           : <DelayPoint>[] {
    nameNotifier = ValueNotifier<String>(name);
  }

  String get name => nameNotifier.value;
  set name(String value) => nameNotifier.value = value;

  void ensureDefaultPoints() {
    horizonPoints = ensureDefaultHorizonPoints(horizonPoints);
    ceilingPoints = ensureDefaultCeilingPoints(ceilingPoints);
  }
}

class Point {
  double x;
  double y;
  bool isAzimuthLocked;
  bool isDefault;

  Point({
    this.x = 0,
    this.y = 0,
    this.isAzimuthLocked = false,
    this.isDefault = false,
  });
}

class DelayPoint {
  double brightness;
  double seconds;

  DelayPoint({this.brightness = 0, this.seconds = 0});
}

Point clonePoint(Point source) => Point(
  x: source.x,
  y: source.y,
  isAzimuthLocked: source.isAzimuthLocked,
  isDefault: source.isDefault,
);

DelayPoint cloneDelayPoint(DelayPoint source) =>
    DelayPoint(brightness: source.brightness, seconds: source.seconds);

LatLng cloneLatLng(LatLng source) => LatLng(source.latitude, source.longitude);

Sector cloneSector(Sector source, {bool keepGuid = false}) {
  final cloned = Sector(
    guid: keepGuid ? source.guid : null,
    id: source.id,
    name: source.name,
    orientation: source.orientation,
    useBrightness: source.useBrightness,
    useIrradiance: source.useIrradiance,
    brightnessDynamicDelay: source.brightnessDynamicDelay,
    irradianceDynamicDelay: source.irradianceDynamicDelay,
    brightnessHighDelayPoints: source.brightnessHighDelayPoints
        .map(cloneDelayPoint)
        .toList(),
    brightnessLowDelayPoints: source.brightnessLowDelayPoints
        .map(cloneDelayPoint)
        .toList(),
    irradianceHighDelayPoints: source.irradianceHighDelayPoints
        .map(cloneDelayPoint)
        .toList(),
    irradianceLowDelayPoints: source.irradianceLowDelayPoints
        .map(cloneDelayPoint)
        .toList(),
    horizonLimit: source.horizonLimit,
    horizonPoints: source.horizonPoints.map(clonePoint).toList(),
    ceilingPoints: source.ceilingPoints.map(clonePoint).toList(),
    louvreTracking: source.louvreTracking,
    louvreSpacing: source.louvreSpacing,
    louvreDepth: source.louvreDepth,
    louvreAngleAtZero: source.louvreAngleAtZero,
    louvreAngleAtHundred: source.louvreAngleAtHundred,
    louvreMinimumChange: source.louvreMinimumChange,
    louvreBuffer: source.louvreBuffer,
    brightnessAddress: source.brightnessAddress,
    heightAddress: source.heightAddress,
    louvreAngleAddress: source.louvreAngleAddress,
    sunBoolAddress: source.sunBoolAddress,
    irradianceAddress: source.irradianceAddress,
    brightnessIrradianceLink: source.brightnessIrradianceLink,
    onAutoAddress: source.onAutoAddress,
    onAutoBehavior: source.onAutoBehavior,
    offAutoAddress: source.offAutoAddress,
    offAutoBehavior: source.offAutoBehavior,
    facadeAddress: source.facadeAddress,
    facadeStart: source.facadeStart != null
        ? cloneLatLng(source.facadeStart!)
        : null,
    facadeEnd: source.facadeEnd != null ? cloneLatLng(source.facadeEnd!) : null,
  );
  cloned.brightnessUpperThreshold = source.brightnessUpperThreshold;
  cloned.brightnessUpperDelay = source.brightnessUpperDelay;
  cloned.brightnessLowerThreshold = source.brightnessLowerThreshold;
  cloned.brightnessLowerDelay = source.brightnessLowerDelay;
  cloned.irradianceUpperThreshold = source.irradianceUpperThreshold;
  cloned.irradianceUpperDelay = source.irradianceUpperDelay;
  cloned.irradianceLowerThreshold = source.irradianceLowerThreshold;
  cloned.irradianceLowerDelay = source.irradianceLowerDelay;
  return cloned;
}

List<Point> ensureDefaultHorizonPoints(List<Point> points) =>
    _ensureLockedPoints(points, horizonLockedPointSpecs);

List<Point> ensureDefaultCeilingPoints(List<Point> points) =>
    _ensureLockedPoints(points, ceilingLockedPointSpecs);

List<Point> _ensureLockedPoints(
  List<Point> points,
  List<LockedPointSpec> specs,
) {
  for (final spec in specs) {
    final matches = points
        .where((p) => isAzimuthClose(p.x, spec.azimuth))
        .toList();
    if (matches.isNotEmpty) {
      final anchor = matches.firstWhere(
        (p) => p.isDefault,
        orElse: () => matches.first,
      );
      for (final point in matches) {
        final isAnchor = identical(point, anchor);
        point.isDefault = isAnchor;
        point.isAzimuthLocked = isAnchor;
        if (isAnchor) {
          point.x = spec.azimuth;
        }
      }
    } else {
      points.add(
        Point(
          x: spec.azimuth,
          y: spec.defaultElevation,
          isAzimuthLocked: true,
          isDefault: true,
        ),
      );
    }
  }
  points.sort(_lockedPointComparator);
  return points;
}

bool isAzimuthClose(double a, double b) =>
    (a - b).abs() < kLockedAzimuthTolerance;

int _lockedPointComparator(Point a, Point b) {
  final cmp = a.x.compareTo(b.x);
  if (cmp != 0) return cmp;
  final isNeg90 = isAzimuthClose(a.x, -90);
  final isPos90 = isAzimuthClose(a.x, 90);

  if (isNeg90) {
    if (a.isDefault == b.isDefault) return 0;
    return a.isDefault ? 1 : -1;
  }
  if (isPos90) {
    if (a.isDefault == b.isDefault) return 0;
    return a.isDefault ? -1 : 1;
  }
  if (a.isDefault == b.isDefault) return 0;
  return a.isDefault ? -1 : 1;
}
