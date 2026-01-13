import '../Helper/ApiBaseHelper.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';

class PromoCodeRepository {
  //
  ///This method is used to get PromoCodes
  static Future<Map<String, dynamic>> fetchPromoCodes({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var promoCodeList = await ApiBaseHelper().postAPICall(getPromoCodeApi, parameter);
      return {
        'totalPromoCodes': promoCodeList['total'].toString(),
        'promoCodeList': (promoCodeList['promo_codes'] as List)
            .map((promoCodeData) => (Promo.fromJson(promoCodeData)))
            .toList()
      };
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchPersonalizedPromoCodes({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      // var promoCodeList =
      // await ApiBaseHelper().postAPICall(getPersonalizedPromoCodeApi, parameter);
      // return {
      //   'totalPromoCodes': promoCodeList['total'].toString(),
      //   'promoCodeList': (promoCodeList['promo_codes'] as List)
      //       .map((promoCodeData) => (Promo.fromJson(promoCodeData)))
      //       .toList()
      // };
      //SIMULATE API RESPONSE
      await Future.delayed(Duration(seconds: 1));
      final today = DateTime.now();
      return {
        'totalPromoCodes': '5',
        'promoCodeList': List.generate(
          5,
          (index) => Promo(
            id: '$index',
            promoCode: 'LOP258',
            message: 'BLACK FRIDAY',
            startDate: today.subtract(Duration(days: 4)).toString(),
            endDate: today.add(Duration(days: 4)).toString(),
            discount: '10%',
            discountType: 'PERCENTAGE',
            repeatUsage: 'NO',
            minOrderAmt: '10',
            maxDiscountAmt: '200',
            image: 'https://www.pngmart.com/files/7/Discount-Background-PNG.png',
          ),
        ),
      };
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  //
  ///This method is used to validate PromoCodes
  static Future<Map<String, dynamic>> validatePromoCodes({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var validateOutPut = await ApiBaseHelper().postAPICall(validatePromoApi, parameter);

      return validateOutPut;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }
}
