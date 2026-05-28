import 'dart:convert';
import 'package:http/http.dart' as http;

class MapApi {
  static Future<Map<String, double>?> timToaDo(String diaChi) async {
    if (diaChi.trim().isEmpty) return null;

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': diaChi,
        'format': 'jsonv2',
        'limit': '1',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'GoMate/1.0',
        'Accept': 'application/json',
        'Accept-Language': 'vi',
      },
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    if (data is List && data.isNotEmpty) {
      return {
        'lat': double.parse(data[0]['lat']),
        'lon': double.parse(data[0]['lon']),
      };
    }

    return null;
  }
}