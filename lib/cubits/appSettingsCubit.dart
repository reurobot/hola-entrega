import 'dart:developer';
import 'package:eshop_multivendor/repository/systemRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eshop_multivendor/Model/appSettingsModel.dart';

abstract class AppSettingsState {}

class AppSettingsInitial extends AppSettingsState {}

class AppSettingsProgress extends AppSettingsState {}

class AppSettingsSuccess extends AppSettingsState {
  final AppSettingsModel appSettingsModel;
  AppSettingsSuccess({
    required this.appSettingsModel,
  });
}

class AppSettingsFailure extends AppSettingsState {
  final String message;
  AppSettingsFailure({required this.message});
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit() : super(AppSettingsInitial());

  fetchAndStoreAppSettings() async {
    emit(AppSettingsProgress());
    try {
      log('Fetching app settings from API...', name: 'AppSettingsCubit');
      final response = await SystemRepository.fetchSystemSetting(parameter: {});
      log('API response received: ${response != null ? 'success' : 'null'}',
          name: 'AppSettingsCubit');

      if (response == null) {
        log('API response is null, using fallback', name: 'AppSettingsCubit');
        _emitDefaultSettings();
        return;
      }

      if (!response['error']) {
        log('Parsing successful response', name: 'AppSettingsCubit');
        emit(AppSettingsSuccess(
            appSettingsModel: AppSettingsModel.fromMap(response)));
        log('App settings loaded successfully', name: 'AppSettingsCubit');
      } else {
        log('API returned error: ${response['message']}',
            name: 'AppSettingsCubit');
        emit(AppSettingsFailure(message: response['message']));
      }
    } catch (e, stackTrace) {
      log('Error fetching app settings: $e',
          name: 'AppSettingsCubit', error: e);
      log('Stack trace: $stackTrace',
          name: 'AppSettingsCubit', error: stackTrace);
      log('Using fallback default settings', name: 'AppSettingsCubit');
      _emitDefaultSettings();
    }
  }

  void _emitDefaultSettings() {
    final defaultModel = AppSettingsModel(
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
    emit(AppSettingsSuccess(appSettingsModel: defaultModel));
  }

  bool isGoogleLoginOn() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess)
          .appSettingsModel
          .isGoogleLoginAllowed;
    }
    return false;
  }

  String? getiosLink() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess).appSettingsModel.iosLink;
    }
    return '';
  }

  String? getandroidLink() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess).appSettingsModel.androidLink;
    }
    return '';
  }

  String? getAppStoreId() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess).appSettingsModel.appStoreId;
    }
    return '';
  }

  String? getUserCountryCode() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess).appSettingsModel.userCountryCode;
    }
    return null; // Return null instead of an empty string
  }

  String? getDefaultCountryCode() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess).appSettingsModel.defaultCountryCode;
    }
    return null; // Return null instead of an empty string
  }

  bool isAppleLoginAllowed() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess).appSettingsModel.isAppleLoginAllowed;
    }
    return false;
  }

  bool isSMSGatewayActive() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess).appSettingsModel.isSMSGatewayActive;
    }
    return false;
  }

  bool isCityWiseDeliverability() {
    if (state is AppSettingsSuccess) {
      return (state as AppSettingsSuccess)
          .appSettingsModel
          .isCityWiseDeliveribility;
    }
    return false;
  }
}
