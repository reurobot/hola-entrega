import 'dart:core';
import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';

class ProductListRepository {
  // get data for product list
  static Future<Map<String, dynamic>> getList({
    required var parameter,
  }) async {
    try {
      var responseData =
          await ApiBaseHelper().postAPICall(getProductApi, parameter);

      return responseData;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  // get data for section list
  static Future<Map<String, dynamic>> getSection({
    required var parameter,
  }) async {
    try {
      var responseData =
          await ApiBaseHelper().postAPICall(getSectionApi, parameter);

      return responseData;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  // get products for slide (type products)
  // param id is the unique id for slider clicked
  static Future<Map<String, dynamic>> getSlide(String id) async {
    //TODO (Adjust in API implementation)
    //For example:
    // var parameter = {
    //   SLIDER_ID: id,
    //   SLIDER_TYPE: 'products'
    // };

    //this API CALL simulate API ENDPOINT to get product for the slider
    var parameter = {
      SLIDER_ID: id,
    };
    try {
      var responseData =
          await ApiBaseHelper().postAPICall(getProductSlideApi, parameter);
      return responseData;
    } on Exception catch (e) {
      print(e);
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }
}
