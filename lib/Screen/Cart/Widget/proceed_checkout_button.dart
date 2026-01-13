import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Helper/String.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Helper/routes.dart';
import 'package:eshop_multivendor/widgets/ButtonDesing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProceedCheckoutButton extends StatelessWidget {
  final VoidCallback onCheckout;
  final Future<void> Function() onCallApi;
  final Widget cartWidget;

  const ProceedCheckoutButton({
    super.key,
    required this.onCheckout,
    required this.onCallApi,
    required this.cartWidget,
  });

  void _onProceedCheckout(BuildContext context) {
    final userId = context.read<UserProvider>().userId;

    if (userId != null && userId.isNotEmpty) {
      onCheckout();
      return;
    }

    Routes.navigateToLoginScreen(
      context,
      classType: cartWidget,
      isPop: true,
      isRefresh: true,
    ).then((value) async {
      await onCallApi();
      if (value == 'refresh') {
        onCheckout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: SimBtn(
        size: 0.5,
        paddingvalue: 0,
        height: 40,
        borderRadius: circularBorderRadius5,
        title: 'PROCEED_CHECKOUT'.translate(context: context),
        onBtnSelected: () => _onProceedCheckout(context),
      ),
    );
  }
}
