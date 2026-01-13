import 'dart:io';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/widgets/bottomSheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../Helper/Constant.dart';
import '../../../Helper/String.dart';
import '../../../Helper/routes.dart';
import '../../../Provider/SettingProvider.dart';
import '../../../Provider/UserProvider.dart';
import '../../../widgets/desing.dart';

import '../../../widgets/snackbar.dart';
import '../../../widgets/validation.dart';

class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({super.key});

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  FocusNode? passFocus = FocusNode();

  final GlobalKey<FormState> _changeUserDetailsKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  Widget getUserImage(String profileImage, VoidCallback? onBtnSelected) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if (mounted) {
              if (context.read<UserProvider>().userId != '') {
                onBtnSelected!();
              }
            }
          },
          child: Container(
            margin: const EdgeInsetsDirectional.only(end: 20),
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  width: 1.0, color: Theme.of(context).colorScheme.white),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(circularBorderRadius100),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return userProvider.profilePic != ''
                      ? DesignConfiguration.getCacheNotworkImage(
                          boxFit: extendImg ? BoxFit.cover : BoxFit.contain,
                          context: context,
                          heightvalue: 64.0,
                          widthvalue: 64.0,
                          placeHolderSize: 64.0,
                          imageurlString: userProvider.profilePic,
                        )
                      : DesignConfiguration.imagePlaceHolder(62, context);
                },
              ),
            ),
          ),
        ),
        if (context.read<UserProvider>().userId != '')
          Positioned.directional(
            textDirection: Directionality.of(context),
            end: 20,
            bottom: 5,
            child: Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.all(
                  Radius.circular(circularBorderRadius20),
                ),
                border: Border.all(color: colors.primary),
              ),
              child: InkWell(
                child: const Icon(
                  Icons.edit,
                  color: colors.whiteTemp,
                  size: 10,
                ),
                onTap: () {
                  if (mounted) {
                    onBtnSelected!();
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget setNameField({required String userName}) => CustomTextField(
        controller: nameController,
        labelText: 'NAME_LBL',
        validator: (val) => StringValidation.validateUserName(
          val!,
          'USER_REQUIRED'.translate(context: context),
          'USER_LENGTH'.translate(context: context),
          'INVALID_USERNAME_LBL'.translate(context: context),
        ),
      );

  Widget setEmailField({required String email}) => CustomTextField(
        controller: emailController,
        labelText: 'EMAILHINT_LBL',
        readOnly: (context.read<UserProvider>().loginType == GOOGLE_TYPE),
        validator: (val) => StringValidation.validateEmail(
          val!,
          'EMAIL_REQUIRED'.translate(context: context),
          'VALID_EMAIL'.translate(context: context),
        ),
      );

  Widget setMobileField() => CustomTextField(
        controller: mobileController,
        labelText: 'MOBILEHINT_LBL',
        readOnly: (context.read<UserProvider>().loginType == PHONE_TYPE),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (val) => StringValidation.validateMob(
          val!,
          'MOB_REQUIRED'.translate(context: context),
          'VALID_MOB'.translate(context: context),
          check: false,
        ),
      );

  Widget saveButton({required String title, VoidCallback? onBtnSelected}) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: InkWell(
              onTap: onBtnSelected,
              child: Container(
                height: 45.0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.grad1Color, colors.grad2Color],
                    stops: [0, 1],
                  ),
                  borderRadius: BorderRadius.circular(circularBorderRadius10),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.white,
                      fontWeight: FontWeight.bold,
                      fontSize: textFontSize16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _imgFromGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'eps'],
    );
    if (result != null) {
      var image = File(result.files.single.path!);
      if (mounted) {
        Map result = await context
            .read<UserProvider>()
            .updateUserProfilePicture(image: image, context: context);

        if (!result['error']) {
          String? imageURL;
          var data = result['data'];

          for (var i in data) {
            imageURL = i[IMAGE];
          }

          await Provider.of<SettingProvider>(context, listen: false)
              .setPrefrence(IMAGE, imageURL!);
          Provider.of<UserProvider>(context, listen: false)
              .setProfilePic(imageURL);
          setSnackbar(
              'PROFILE_UPDATE_MSG'.translate(context: context), context);
          Routes.pop(context);
        } else {
          setSnackbar(result['message'], context);
        }
      }
    } else {
      // User canceled the picker
    }
  }

  Future<bool> validateAndSave(
      GlobalKey<FormState> key, BuildContext context) async {
    final form = key.currentState!;
    form.save();
    if (form.validate()) {
      await context
          .read<UserProvider>()
          .updateUserProfile(
              userID: context.read<UserProvider>().userId!,
              newPassword: '',
              oldPassword: '',
              username: nameController.text,
              userEmail: emailController.text,
              userMobile: mobileController.text)
          .then(
        (value) {
          if (value['error'] == false) {
            var settingProvider =
                Provider.of<SettingProvider>(context, listen: false);
            var userProvider =
                Provider.of<UserProvider>(context, listen: false);

            settingProvider.setPrefrence(USERNAME, nameController.text);
            userProvider.setName(nameController.text);
            settingProvider.setPrefrence(EMAIL, emailController.text);
            userProvider.setEmail(emailController.text);
            settingProvider.setPrefrence(MOBILE, mobileController.text);
            userProvider.setMobile(mobileController.text);

            setSnackbar('USER_UPDATE_MSG'.translate(context: context), context);
          } else {
            setSnackbar(value['message'], context);
          }
        },
      );

      Routes.pop(context);

      return true;
    }
    return false;
  }

  @override
  void initState() {
    Future.delayed(Duration.zero).then(
      (value) {
        nameController.text = context.read<UserProvider>().curUserName;
        emailController.text = context.read<UserProvider>().email;
        mobileController.text = context.read<UserProvider>().mob;
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return Wrap(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Form(
                    key: _changeUserDetailsKey,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomBottomSheet.bottomSheetHandle(context),
                            CustomBottomSheet.bottomSheetLabel(
                                context, 'EDIT_PROFILE_LBL'),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.profilePic,
                                builder: (context, profileImage, child) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: getUserImage(
                                        profileImage, _imgFromGallery),
                                  );
                                }),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.curUserName,
                                builder: (context, userName, child) {
                                  return setNameField(userName: userName);
                                }),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.email,
                                builder: (context, userEmail, child) {
                                  return setEmailField(email: userEmail);
                                }),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.mob,
                                builder: (context, userMob, child) {
                                  return setMobileField();
                                }),
                            Padding(
                              padding: Platform.isIOS
                                  ? EdgeInsetsDirectional.symmetric(
                                      horizontal: 0, vertical: 10)
                                  : EdgeInsetsDirectional.symmetric(
                                      horizontal: 0,
                                    ),
                              child: saveButton(
                                title: 'SAVE_LBL'.translate(context: context),
                                onBtnSelected: () {
                                  if (context.read<UserProvider>().userStatus !=
                                      UserStatus.inProgress) {
                                    validateAndSave(
                                        _changeUserDetailsKey, context);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (userProvider.userStatus == UserStatus.inProgress)
                          SizedBox(
                            height: constraints.maxHeight *
                                0.5, // Adjust the percentage as needed
                            child: Center(
                              child: DesignConfiguration.showCircularProgress(
                                  true, colors.primary),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    super.dispose();
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool readOnly;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(circularBorderRadius10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              label: Text(
                labelText.translate(context: context),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              fillColor: Theme.of(context).colorScheme.primary,
              border: InputBorder.none,
            ),
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ),
    );
  }
}
