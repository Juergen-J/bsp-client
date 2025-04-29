import 'dart:convert';
import 'package:dio/dio.dart';

Future<void> fetchLocation() async {
  final dio = Dio();
  final response = await dio.get('https://ipwho.is/');

  if (response.statusCode == 200) {
    final data = response.data;
    print(data);
    print("City: ${data['city']}, Country: ${data['country']}");
  } else {
    print("Failed to get location data");
  }
}
//{
//   "ip": "176.0.5.102",
//   "success": true,
//   "type": "IPv4",
//   "continent": "Europe",
//   "continent_code": "EU",
//   "country": "Germany",
//   "country_code": "DE",
//   "region": "Berlin",
//   "region_code": "BE",
//   "city": "Berlin",
//   "latitude": 52.5200066,
//   "longitude": 13.404954,
//   "is_eu": true,
//   "postal": "10178",
//   "calling_code": "49",
//   "capital": "Berlin",
//   "borders": "AT,BE,CH,CZ,DK,FR,LU,NL,PL",
//   "flag": {
//     "img": "https://cdn.ipwhois.io/flags/de.svg",
//     "emoji": "🇩🇪",
//     "emoji_unicode": "U+1F1E9 U+1F1EA"
//   },
//   "connection": {
//     "asn": 6805,
//     "org": "Telefonica Germany GmbH Co. Ohg",
//     "isp": "Telefonica Germany GmbH Co.ohg",
//     "domain": "telefonica.com"
//   },
//   "timezone": {
//     "id": "Europe/Berlin",
//     "abbr": "CEST",
//     "is_dst": true,
//     "offset": 7200,
//     "utc": "+02:00",
//     "current_time": "2025-04-26T18:03:01+02:00"
//   }
// }
