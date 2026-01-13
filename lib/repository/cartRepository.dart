import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import 'dart:convert';

class CartRepository {
  static Future<Map<String, dynamic>> clearCart(
      {required Map<String, dynamic> parameter}) async {
    try {
      var cartData = await ApiBaseHelper().postAPICall(clearCartApi, parameter);
      return cartData;
    } catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchUserCart(
      {required Map<String, dynamic> parameter}) async {
    try {
      var cartData = await ApiBaseHelper().postAPICall(getCartApi, parameter);
      return cartData;
    } catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchUserOfflineCart(
      {required Map<String, dynamic> parameter}) async {
    try {
      var offlineCartData =
          await ApiBaseHelper().postAPICall(getProductApi, parameter);
      return {
        'error': offlineCartData['error'],
        'message': offlineCartData['message'],
        'offlineCartList': (offlineCartData['data'] as List)
            .map((data) => Product.fromJson(data))
            .toList()
      };
    } catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> manageCartAPICall({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var result = await ApiBaseHelper().postAPICall(manageCartApi, parameter);

      return result;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> deleteProductFromCartAPICall({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var result =
          await ApiBaseHelper().postAPICall(deleteProductFrmCartApi, parameter);

      return result;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> checkDeliverable({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var result = await ApiBaseHelper()
          .postAPICall(checkShipRocketChargesOnProduct, parameter);

      return result;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> solicitarDescuentos({
    required String customerErpId,
    required List<Map<String, dynamic>> productos,
  }) async {
    try {
      final parameter = {
        'customer_erp_id': customerErpId,
        'productos': jsonEncode(productos),
      };

      var result = await ApiBaseHelper().postAPICall(
        Uri.parse('https://api.ejemplo.com/solicitar_descuentos'),
        parameter,
      );

      return result;
    } on Exception catch (e) {
      throw ApiException('Error al solicitar descuentos: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> obtenerCreditoDisponible(
      String customerErpId) async {
    try {
      final parameter = {
        'customer_erp_id': customerErpId,
      };

      var result = await ApiBaseHelper().postAPICall(
        Uri.parse('https://api.ejemplo.com/obtener_credito'),
        parameter,
      );

      return result;
    } on Exception catch (e) {
      throw ApiException(
          'Error al obtener crédito disponible: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> obtenerTablaDescuentosDinamica() async {
    try {
      var result = await ApiBaseHelper().getAPICall(
        Uri.parse('https://api.ejemplo.com/obtener_tabla_descuentos'),
      );

      return result;
    } on Exception catch (e) {
      throw ApiException(
          'Error al obtener tabla de descuentos: ${e.toString()}');
    }
  }
}
