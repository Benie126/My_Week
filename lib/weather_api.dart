import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temp;
  final int code;
  WeatherData(this.temp, this.code);

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      (json['temperature_2m'] as num).toDouble(),
      (json['weather_code'] as num).toInt(),
    );
  }
}

Future<WeatherData> fetchKigaliWeather() async {
  final url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
        '?latitude=-1.9441&longitude=30.0619'
        '&current=temperature_2m,weather_code'
        '&timezone=Africa%2FKigali',
  );
  final response = await http.get(url, headers: {'Accept': 'application/json'});
  if (response.statusCode != 200) throw Exception('Error ${response.statusCode}');
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return WeatherData.fromJson(data['current'] as Map<String, dynamic>);
}