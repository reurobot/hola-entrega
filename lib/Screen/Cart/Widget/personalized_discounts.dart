import 'package:eshop_multivendor/Helper/String.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Provider/promoCodeProvider.dart';
import 'package:eshop_multivendor/widgets/ButtonDesing.dart';
import 'package:eshop_multivendor/widgets/desing.dart';
import 'package:eshop_multivendor/widgets/simmerEffect.dart';
import 'package:eshop_multivendor/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../Helper/Color.dart';
import '../../../Helper/Constant.dart';
import '../../../Helper/assetsConstant.dart';

class PersonalizedDiscounts extends StatefulWidget {
  final String productId;

  const PersonalizedDiscounts({super.key, required this.productId});

  @override
  State<PersonalizedDiscounts> createState() => _PersonalizedDiscountsState();
}

class _PersonalizedDiscountsState extends State<PersonalizedDiscounts> {
  final GlobalKey expansionTileKey = GlobalKey();
  bool _promoCodeApplyInProcess = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((value) {
      String userId = context.read<UserProvider>().userId ?? '';
      context
          .read<PromoCodeProvider>()
          .getPersonalizedPromoCodes(productId: widget.productId, userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      title: Text(
        'Descuentos persoalizados'.translate(context: context),
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.bold,
          fontSize: textFontSize16,
          fontFamily: 'ubuntu',
        ),
        textAlign: TextAlign.center,
      ),
      content: Consumer<PromoCodeProvider>(
        builder: (context, value, child) {
          if (value.getCurrentStatus == PromoCodeStatus.isFailure) {
            return Center(
              child: Text(value.errorMessage),
            );
          } else if (value.getCurrentStatus == PromoCodeStatus.isSuccsess) {
            return value.personalizedPromoAvailable.isEmpty
                ? Center(
                    child: Text(
                      'NO_PROMCO'.translate(context: context),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 500,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: List.generate(
                            value.personalizedPromoAvailable.length,
                            (index) => _getPromo(value, index),
                          ),
                        ),
                      ),
                    ),
                  );
          }
          return const ShimmerEffect();
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _getPromo(PromoCodeProvider value, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          ExpansionPanelList.radio(
            children: [
              ExpansionPanelRadio(
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 10,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            "${"MIN_ORDER_VALUE".translate(context: context)} ${DesignConfiguration.getPriceFormat(context, double.parse(value.personalizedPromoAvailable[index].minOrderAmt!))}",
                            style: const TextStyle(
                              fontSize: textFontSize12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 10,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            "${"MAX_DISCOUNT".translate(context: context)}  ${DesignConfiguration.getPriceFormat(context, double.parse(value.personalizedPromoAvailable[index].maxDiscountAmt!))}",
                            style: const TextStyle(
                              fontSize: textFontSize12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 10,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            "${"OFFER_VALID_FROM".translate(context: context)} ${value.personalizedPromoAvailable[index].startDate} to ${value.personalizedPromoAvailable[index].endDate}",
                            style: const TextStyle(
                              fontSize: textFontSize12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 10,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: value.personalizedPromoAvailable[index].repeatUsage == 'Allowed'
                              ? Text(
                                  "${"MAX_APPLICABLE".translate(context: context)}  ${value.personalizedPromoAvailable[index].noOfRepeatUsage} times",
                                  style: const TextStyle(
                                    fontSize: textFontSize12,
                                  ),
                                )
                              : Text(
                                  'OFFER_VALID_ONCE'.translate(context: context),
                                  style: const TextStyle(
                                    fontSize: textFontSize12,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 10,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: value.personalizedPromoAvailable[index].isInstantCashback == '0'
                              ? Text('You will get Instant Cashback'.translate(context: context),
                                  style: const TextStyle(fontSize: textFontSize12))
                              : Text(
                                  'You will get Cashback In Wallet'.translate(context: context),
                                  style: const TextStyle(
                                    fontSize: textFontSize12,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
                headerBuilder: (context, isExpanded) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 35,
                              width: 40,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  circularBorderRadius7,
                                ),
                                child: Image.network(
                                  value.personalizedPromoAvailable[index].image!,
                                  height: 30,
                                  width: 30,
                                  fit: BoxFit.fill,
                                  errorBuilder: (context, error, stackTrace) =>
                                      DesignConfiguration.erroWidget(
                                    80,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      value.personalizedPromoAvailable[index].promoCode ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      value.personalizedPromoAvailable[index].message ?? '',
                                      style: const TextStyle(
                                        fontSize: textFontSize12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                value: index,
                canTapOnHeader: true,
              ),
            ],
            elevation: 0.0,
            animationDuration: const Duration(milliseconds: 700),
            expansionCallback: (int item, bool status) {
              setState(
                () {
                  value.personalizedPromoAvailable[index].isExpanded = !status;
                },
              );
            },
          ),
          Container(
            alignment: Alignment.bottomRight,
            color: Theme.of(context).colorScheme.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: InkWell(
                                child: SvgPicture.asset(
                                  DesignConfiguration.setSvgPath(Assets.promoLight),
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.lightWhite,
                                    BlendMode.srcIn,
                                  ),
                                  height: 35,
                                ),
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: value.personalizedPromoAvailable[index].promoCode!,
                                    ),
                                  );
                                  setSnackbar(
                                      'Promo Code Copied to clipboard'.translate(context: context),
                                      context);
                                },
                              ),
                            ),
                            Text(
                              value.personalizedPromoAvailable[index].promoCode ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SimBtn(
                    borderRadius: circularBorderRadius5,
                    title: 'APPLY'.translate(context: context),
                    size: 0.2,
                    onBtnSelected: () {
                      if (_promoCodeApplyInProcess) {
                        return;
                      }
                      _promoCodeApplyInProcess =
                      true;
                      // context
                      //     .read<
                      //     PromoCodeProvider>()
                      //     .validatePromo(
                      //   value
                      //       .personalizedPromoAvailable[
                      //   index]
                      //       .promoCode!,
                      //   context,
                      //   setStateNow,
                      //   widget
                      //       .updateParent,
                      //   callShowOverlayMethod,
                      // )
                      //     .then(
                      //       (value) {
                      //     PromoCodeApplyInProccess =
                      //     false;
                      //     Navigator.of(
                      //         context)
                      //         .pop();
                      //   },
                      // );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
