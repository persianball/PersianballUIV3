import 'package:flutter/widgets.dart';
import 'package:marketky/utils/responsive.dart';

class PageContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const PageContainer({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxW = maxWidth ?? Responsive.contentMaxWidth(width);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: child,
          ),
        );
      },
    );
  }
}