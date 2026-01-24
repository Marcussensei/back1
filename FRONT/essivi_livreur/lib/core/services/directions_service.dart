import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final List<LatLng> points;
  final double duration; // in seconds
  final double distance; // in meters

  RouteInfo({
    required this.points,
    required this.duration,
    required this.distance,
  });

  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '${hours}h${remainingMinutes > 0 ? ' $remainingMinutes min' : ''}';
    }
  }

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
}

class DirectionsService {
  Future<RouteInfo> getRouteInfo(LatLng origin, LatLng destination) async {
    print(
        '🔍 [DirectionsService] Called with origin: ${origin.latitude},${origin.longitude} -> destination: ${destination.latitude},${destination.longitude}');
    try {
      // Using OSRM public routing service (free, no API key required)
      final url = Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson');

      print('🔍 [DirectionsService] Calling OSRM API: $url');

      final response = await http.get(url);

      print('📡 [DirectionsService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('🔍 [DirectionsService] OSRM Status: ${data['code']}');

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          final duration = route['duration'] as double; // in seconds
          final distance = route['distance'] as double; // in meters

          print(
              '✅ [DirectionsService] Route found with ${geometry.length} coordinates');
          print(
              '⏱️ [DirectionsService] Duration: ${duration}s, Distance: ${distance}m');

          // Convert OSRM coordinates [lng, lat] to LatLng [lat, lng]
          final points =
              geometry.map((coord) => LatLng(coord[1], coord[0])).toList();

          print('✅ [DirectionsService] Converted ${points.length} points');

          return RouteInfo(
            points: points,
            duration: duration,
            distance: distance,
          );
        } else {
          print(
              '❌ [DirectionsService] No valid routes found. Code: ${data['code']}');
        }
      } else {
        print('❌ [DirectionsService] HTTP error: ${response.statusCode}');
      }

      // Fallback to straight line if routing fails
      print('⚠️ [DirectionsService] Using fallback straight line');
      return RouteInfo(
        points: [origin, destination],
        duration: 0,
        distance: 0,
      );
    } catch (e) {
      print('❌ [DirectionsService] Exception: $e');
      // Fallback to straight line
      return RouteInfo(
        points: [origin, destination],
        duration: 0,
        distance: 0,
      );
    }
  }

  // Keep the old method for backward compatibility
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    final routeInfo = await getRouteInfo(origin, destination);
    return routeInfo.points;
  }
}
