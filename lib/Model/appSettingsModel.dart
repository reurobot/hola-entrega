import 'dart:developer';
import 'package:eshop_multivendor/Helper/String.dart';

class AppSettingsModel {
  bool isAppleLoginAllowed;
  bool isGoogleLoginAllowed;
  bool isSMSGatewayActive;
  bool isCityWiseDeliveribility;
  String? iosLink;
  String? appStoreId;
  String? androidLink;
  String? defaultCountryCode;
  String? userCountryCode;

  AppSettingsModel(
      {required this.isAppleLoginAllowed,
      required this.isGoogleLoginAllowed,
      required this.isSMSGatewayActive,
      required this.isCityWiseDeliveribility,
      required this.androidLink,
      required this.iosLink,
      required this.appStoreId,
      required this.defaultCountryCode,
      required this.userCountryCode});

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    try {
      // Validate main structure
      if (map['systemSetting'] == null) {
        log('Missing systemSetting in API response, using defaults',
            name: 'AppSettingsModel');
        return _getDefaultModel();
      }

      final systemSetting = map['systemSetting'] as Map<String, dynamic>;

      // Validate system_settings array
      if (systemSetting['system_settings'] == null ||
          systemSetting['system_settings'] is! List ||
          (systemSetting['system_settings'] as List).isEmpty) {
        log('Missing or invalid system_settings in API response, using defaults',
            name: 'AppSettingsModel');
        return _getDefaultModel();
      }

      final data = systemSetting['system_settings'][0] as Map<String, dynamic>;

      // Validate shipping_method array
      Map<String, dynamic>? shippingData;
      if (systemSetting['shipping_method'] != null &&
          systemSetting['shipping_method'] is List &&
          (systemSetting['shipping_method'] as List).isNotEmpty) {
        shippingData =
            systemSetting['shipping_method'][0] as Map<String, dynamic>;
      }

      // Safe access to all fields
      final bool isAppleLoginAllowed =
          _safeStringEquals(data[APPLE_LOGIN], '1');
      final bool isGoogleLoginAllowed =
          _safeStringEquals(data[GOOGLE_LOGIN], '1');

      // SMS Gateway check with safe access
      bool isSMSGatewayActive = false;
      if (systemSetting['authentication_settings'] != null &&
          systemSetting['authentication_settings'] is List &&
          (systemSetting['authentication_settings'] as List).isNotEmpty) {
        final authSettings =
            systemSetting['authentication_settings'][0] as Map<String, dynamic>;
        isSMSGatewayActive =
            authSettings['authentication_method']?.toString().toLowerCase() ==
                'sms';
      }

      final bool isCityWiseDeliveribility = shippingData != null
          ? _safeStringEquals(shippingData['city_wise_deliverability'], '1')
          : false;

      // User data with safe access
      String userCountryCode = '';
      if (systemSetting['user_data'] != null &&
          systemSetting['user_data'] is List &&
          (systemSetting['user_data'] as List).isNotEmpty &&
          systemSetting['user_data'][0] != null) {
        final userData = systemSetting['user_data'][0] as Map<String, dynamic>;
        userCountryCode = userData[COUNTRY_CODE]?.toString() ?? '';
      }

      return AppSettingsModel(
        isAppleLoginAllowed: isAppleLoginAllowed,
        isGoogleLoginAllowed: isGoogleLoginAllowed,
        isSMSGatewayActive: isSMSGatewayActive,
        isCityWiseDeliveribility: isCityWiseDeliveribility,
        iosLink: data['ios_app_store_link']?.toString() ?? '',
        appStoreId: data['app_store_id']?.toString() ?? '',
        androidLink: data['android_app_store_link']?.toString() ?? '',
        defaultCountryCode: data['default_country_code']?.toString() ?? 'IN',
        userCountryCode: userCountryCode,
      );
    } catch (e, stackTrace) {
      log('Error parsing AppSettingsModel: $e',
          name: 'AppSettingsModel', error: e);
      log('Stack trace: $stackTrace',
          name: 'AppSettingsModel', error: stackTrace);
      log('Using fallback default settings', name: 'AppSettingsModel');
      return _getDefaultModel();
    }
  }

  static AppSettingsModel _getDefaultModel() {
    return AppSettingsModel(
      isAppleLoginAllowed: false,
      isGoogleLoginAllowed: false,
      isSMSGatewayActive: false,
      isCityWiseDeliveribility: false,
      androidLink: '',
      iosLink: '',
      appStoreId: '',
      defaultCountryCode: 'MX',
      userCountryCode: '',
    );
  }

  static bool _safeStringEquals(dynamic value, String compareTo) {
    return value?.toString() == compareTo;
  }

  AppSettingsModel copyWith({
    bool? isAppleLoginAllowed,
    bool? isGoogleLoginAllowed,
    bool? isSMSGatewayActive,
    bool? isCityWiseDeliveribility,
    String? iosLink,
    String? appStoreId,
    String? androidLink,
    String? defaultCountryCode,
    String? userCountryCode,
  }) {
    return AppSettingsModel(
      isAppleLoginAllowed: isAppleLoginAllowed ?? this.isAppleLoginAllowed,
      isGoogleLoginAllowed: isGoogleLoginAllowed ?? this.isGoogleLoginAllowed,
      isSMSGatewayActive: isSMSGatewayActive ?? this.isSMSGatewayActive,
      isCityWiseDeliveribility:
          isCityWiseDeliveribility ?? this.isCityWiseDeliveribility,
      iosLink: iosLink ?? this.iosLink,
      appStoreId: appStoreId ?? this.appStoreId,
      androidLink: androidLink ?? this.androidLink,
      defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
      userCountryCode: userCountryCode ?? this.userCountryCode,
    );
  }
}
