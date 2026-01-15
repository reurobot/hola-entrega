import 'package:flutter/material.dart';

class RadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget? child;
  final List<Widget>? children;

  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    this.child,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [child!],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children ?? [],
    );
  }

  static T? maybeOf<T>(BuildContext context) {
    return null;
  }
}
