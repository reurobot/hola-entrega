import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import 'package:eshop_multivendor/Model/user_client_search.dart';
import 'package:http/http.dart' as http;
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../widgets/security.dart';

class UserClientSearchRepository {
  /// This method is used to search users by name (GET request)
  static Future<List<UserClient>> fetchUsersByName({
    required String name,
  }) async {
    try {
      final uri = Uri.parse('$getUsersSearchApi?name=$name');

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: timeOut));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return UserClientResponse.fromJson(jsonData).data;
      } else {
        throw ApiException('Error: ${response.statusCode}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Something went wrong, Server not Responding');
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }
}
