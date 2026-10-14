import 'package:offline_geofence_demo/geofence.dart';
import 'package:test/test.dart';

const square = [LatLng(0, 0), LatLng(0, 10), LatLng(10, 10), LatLng(10, 0)];

// An "L" shape: concave, so a simple bounding-box check would get it wrong.
const lShape = [LatLng(0, 0), LatLng(0, 10), LatLng(4, 10), LatLng(4, 4), LatLng(10, 4), LatLng(10, 0)];

const geoJson = '''
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"id":"a1","name":"Avalanche Warning Zone"},
   "geometry":{"type":"Polygon","coordinates":[[[-111.0,40.0],[-110.0,40.0],[-110.0,41.0],[-111.0,41.0],[-111.0,40.0]]]}},
  {"type":"Feature","properties":{"name":"Not a polygon"},"geometry":{"type":"Point","coordinates":[0,0]}}
]}''';

void main() {
  group('isPointInPolygon', () {
    test('inside and outside a square', () {
      expect(isPointInPolygon(const LatLng(5, 5), square), isTrue);
      expect(isPointInPolygon(const LatLng(15, 5), square), isFalse);
      expect(isPointInPolygon(const LatLng(5, -1), square), isFalse);
    });

    test('concave shape: the notch is outside', () {
      expect(isPointInPolygon(const LatLng(2, 8), lShape), isTrue); // in the arm
      expect(isPointInPolygon(const LatLng(8, 2), lShape), isTrue); // in the other arm
      expect(isPointInPolygon(const LatLng(8, 8), lShape), isFalse); // in the notch
    });

    test('degenerate polygons contain nothing', () {
      expect(isPointInPolygon(const LatLng(1, 1), const []), isFalse);
      expect(isPointInPolygon(const LatLng(1, 1), const [LatLng(0, 0), LatLng(2, 2)]), isFalse);
    });
  });

  group('zonesFromGeoJson', () {
    test('reads polygons and swaps GeoJSON [lng, lat] into latitude/longitude', () {
      final zones = zonesFromGeoJson(geoJson);
      expect(zones, hasLength(1)); // the Point feature is skipped
      expect(zones.single.id, 'a1');
      expect(zones.single.name, 'Avalanche Warning Zone');
      expect(zones.single.polygon.first.latitude, 40.0);
      expect(zones.single.polygon.first.longitude, -111.0);
    });

    test('a point inside the parsed zone is detected', () {
      final zone = zonesFromGeoJson(geoJson).single;
      expect(isPointInPolygon(const LatLng(40.5, -110.5), zone.polygon), isTrue);
      expect(isPointInPolygon(const LatLng(40.5, -112), zone.polygon), isFalse);
    });
  });

  group('GeofenceMonitor', () {
    final zone = const HazardZone(id: 'z', name: 'Zone', polygon: square);

    test('fires entered once, stays quiet while inside, then fires exited', () {
      final m = GeofenceMonitor([zone]);
      expect(m.update(const LatLng(20, 20)), isEmpty);

      final enter = m.update(const LatLng(5, 5));
      expect(enter.map((e) => e.type), [GeofenceEventType.entered]);

      expect(m.update(const LatLng(6, 6)), isEmpty);
      expect(m.update(const LatLng(7, 7)), isEmpty);

      final exit = m.update(const LatLng(20, 20));
      expect(exit.map((e) => e.type), [GeofenceEventType.exited]);
    });

    test('tracks several zones independently', () {
      const other = HazardZone(id: 'o', name: 'Other', polygon: [LatLng(20, 20), LatLng(20, 30), LatLng(30, 30), LatLng(30, 20)]);
      final m = GeofenceMonitor([zone, other]);
      expect(m.update(const LatLng(5, 5)).single.zone.id, 'z');
      final move = m.update(const LatLng(25, 25));
      expect(move.map((e) => '${e.zone.id}:${e.type.name}').toSet(), {'z:exited', 'o:entered'});
    });
  });
}
