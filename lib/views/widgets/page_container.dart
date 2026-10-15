import 'package:flutter/widgets.dart';
import 'package:persian_ball/utils/responsive.dart';

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
          // Only tighten maxWidth; keep the incoming height constraints
          // (via copyWith) so Expanded/Flexible descendants that rely on
          // a bounded height from the Scaffold body still work.
          child: ConstrainedBox(
            constraints: constraints.copyWith(maxWidth: maxW),
            child: child,
          ),
        );
      },
    );
  }
}
