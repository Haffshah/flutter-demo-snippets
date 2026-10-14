import 'dart:convert';

class LatLng {
  const LatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// The ray-casting check from slide 5, unchanged in logic: is [point] inside [polygon]?
///
/// It counts how many polygon edges a ray from the point crosses. An odd count means inside.
/// Works for concave shapes. Points exactly on an edge may land on either side.
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  bool inside = false;
  int j = polygon.length - 1;
  for (int i = 0; i < polygon.length; i++) {
    if ((polygon[i].longitude > point.longitude) != (polygon[j].longitude > point.longitude) &&
        (point.latitude <
            (polygon[j].latitude - polygon[i].latitude) *
                    (point.longitude - polygon[i].longitude) /
                    (polygon[j].longitude - polygon[i].longitude) +
                polygon[i].latitude)) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

/// A hazard area, for example an avalanche warning zone.
class HazardZone {
  const HazardZone({required this.id, required this.name, required this.polygon});
  final String id;
  final String name;
  final List<LatLng> polygon;
}

/// Reads zones from a GeoJSON FeatureCollection of Polygon features (outer ring only).
///
/// GeoJSON stores coordinates as [longitude, latitude]. Each feature's `properties` should have
/// `id` and `name`; missing ones fall back to the feature's position in the list.
List<HazardZone> zonesFromGeoJson(String geoJson) {
  final root = jsonDecode(geoJson) as Map<String, dynamic>;
  final features = (root['features'] as List).cast<Map<String, dynamic>>();
  final zones = <HazardZone>[];
  for (var n = 0; n < features.length; n++) {
    final f = features[n];
    final geometry = f['geometry'] as Map<String, dynamic>;
    if (geometry['type'] != 'Polygon') continue;
    final ring = ((geometry['coordinates'] as List).first as List).cast<List>();
    final props = (f['properties'] as Map<String, dynamic>?) ?? const {};
    zones.add(HazardZone(
      id: (props['id'] ?? 'zone_$n').toString(),
      name: (props['name'] ?? 'Zone $n').toString(),
      polygon: [for (final c in ring) LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())],
    ));
  }
  return zones;
}

enum GeofenceEventType { entered, exited }

class GeofenceEvent {
  const GeofenceEvent(this.type, this.zone);
  final GeofenceEventType type;
  final HazardZone zone;
}

/// Feed it location updates; it tells you when the user enters or leaves a zone.
///
/// An event fires once per crossing, not on every update while inside. Turning an `entered` event into a
/// local notification is up to your app. That part needs no network.
class GeofenceMonitor {
  GeofenceMonitor(this.zones);

  final List<HazardZone> zones;
  final Set<String> _inside = {};

  List<GeofenceEvent> update(LatLng position) {
    final events = <GeofenceEvent>[];
    for (final zone in zones) {
      final nowInside = isPointInPolygon(position, zone.polygon);
      final wasInside = _inside.contains(zone.id);
      if (nowInside && !wasInside) {
        _inside.add(zone.id);
        events.add(GeofenceEvent(GeofenceEventType.entered, zone));
      } else if (!nowInside && wasInside) {
        _inside.remove(zone.id);
        events.add(GeofenceEvent(GeofenceEventType.exited, zone));
      }
    }
    return events;
  }
}
