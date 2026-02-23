import 'package:configurator/globals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('cloneSector copies all configurable addresses and flags', () {
    final source = Sector(
      name: 'Sektor 1',
      orientation: 123.4,
      horizonLimit: true,
      louvreTracking: true,
      louvreSpacing: 11,
      louvreDepth: 22,
      louvreAngleAtZero: 33,
      louvreAngleAtHundred: 44,
      louvreMinimumChange: 55,
      louvreBuffer: 66,
      brightnessAddress: '1/1/1',
      heightAddress: '1/1/2',
      louvreAngleAddress: '1/1/3',
      sunBoolAddress: '1/1/4',
      useBrightness: false,
      useIrradiance: false,
      brightnessDynamicDelay: true,
      irradianceDynamicDelay: true,
      irradianceAddress: '1/1/5',
      brightnessIrradianceLink: 'Or',
      onAutoAddress: '1/1/6',
      onAutoBehavior: 'Ein',
      offAutoAddress: '1/1/7',
      offAutoBehavior: 'Aus',
      facadeAddress: '1/1/8',
      facadeStart: const LatLng(47.0, 8.0),
      facadeEnd: const LatLng(47.1, 8.1),
      horizonPoints: [Point(x: 1, y: 2)],
      ceilingPoints: [Point(x: 3, y: 4)],
      brightnessHighDelayPoints: [DelayPoint(brightness: 10, seconds: 20)],
      brightnessLowDelayPoints: [DelayPoint(brightness: 30, seconds: 40)],
      irradianceHighDelayPoints: [DelayPoint(brightness: 50, seconds: 60)],
      irradianceLowDelayPoints: [DelayPoint(brightness: 70, seconds: 80)],
    );
    source.brightnessUpperThreshold = 100;
    source.brightnessUpperDelay = 101;
    source.brightnessLowerThreshold = 102;
    source.brightnessLowerDelay = 103;
    source.irradianceUpperThreshold = 104;
    source.irradianceUpperDelay = 105;
    source.irradianceLowerThreshold = 106;
    source.irradianceLowerDelay = 107;

    final cloned = cloneSector(source);

    expect(cloned.guid, isNot(source.guid));
    expect(cloned.name, source.name);
    expect(cloned.orientation, source.orientation);
    expect(cloned.horizonLimit, source.horizonLimit);
    expect(cloned.louvreTracking, source.louvreTracking);
    expect(cloned.louvreSpacing, source.louvreSpacing);
    expect(cloned.louvreDepth, source.louvreDepth);
    expect(cloned.louvreAngleAtZero, source.louvreAngleAtZero);
    expect(cloned.louvreAngleAtHundred, source.louvreAngleAtHundred);
    expect(cloned.louvreMinimumChange, source.louvreMinimumChange);
    expect(cloned.louvreBuffer, source.louvreBuffer);
    expect(cloned.brightnessAddress, source.brightnessAddress);
    expect(cloned.heightAddress, source.heightAddress);
    expect(cloned.louvreAngleAddress, source.louvreAngleAddress);
    expect(cloned.sunBoolAddress, source.sunBoolAddress);
    expect(cloned.useBrightness, source.useBrightness);
    expect(cloned.useIrradiance, source.useIrradiance);
    expect(cloned.brightnessDynamicDelay, source.brightnessDynamicDelay);
    expect(cloned.irradianceDynamicDelay, source.irradianceDynamicDelay);
    expect(cloned.irradianceAddress, source.irradianceAddress);
    expect(cloned.brightnessIrradianceLink, source.brightnessIrradianceLink);
    expect(cloned.onAutoAddress, source.onAutoAddress);
    expect(cloned.onAutoBehavior, source.onAutoBehavior);
    expect(cloned.offAutoAddress, source.offAutoAddress);
    expect(cloned.offAutoBehavior, source.offAutoBehavior);
    expect(cloned.facadeAddress, source.facadeAddress);
    expect(cloned.facadeStart, source.facadeStart);
    expect(cloned.facadeEnd, source.facadeEnd);
    expect(cloned.brightnessUpperThreshold, source.brightnessUpperThreshold);
    expect(cloned.brightnessUpperDelay, source.brightnessUpperDelay);
    expect(cloned.brightnessLowerThreshold, source.brightnessLowerThreshold);
    expect(cloned.brightnessLowerDelay, source.brightnessLowerDelay);
    expect(cloned.irradianceUpperThreshold, source.irradianceUpperThreshold);
    expect(cloned.irradianceUpperDelay, source.irradianceUpperDelay);
    expect(cloned.irradianceLowerThreshold, source.irradianceLowerThreshold);
    expect(cloned.irradianceLowerDelay, source.irradianceLowerDelay);

    expect(cloned.horizonPoints, isNot(same(source.horizonPoints)));
    expect(cloned.ceilingPoints, isNot(same(source.ceilingPoints)));
    expect(
      cloned.brightnessHighDelayPoints,
      isNot(same(source.brightnessHighDelayPoints)),
    );
    expect(cloned.horizonPoints.first, isNot(same(source.horizonPoints.first)));
    expect(
      cloned.brightnessHighDelayPoints.first,
      isNot(same(source.brightnessHighDelayPoints.first)),
    );
  });

  test('cloneSector can preserve guid for clipboard snapshots', () {
    final source = Sector(name: 'Sektor 1');
    final cloned = cloneSector(source, keepGuid: true);
    expect(cloned.guid, source.guid);
  });
}
