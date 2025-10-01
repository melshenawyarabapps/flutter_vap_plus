import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'vap_controller.dart';
import 'vap_view.dart';

class VapViewForIos extends StatelessWidget {
  final void Function(VapController controller) onControllerCreated;
  final VapScaleFit fit;
  final void Function(dynamic event, dynamic arguments)? onEvent;
  final int repeatCount;

  VapViewForIos(
      {required this.onControllerCreated, required this.fit, this.onEvent, required this.repeatCount});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'scaleType': fit.name,
      'repeatCount': repeatCount
    };
    return UiKitView(
      viewType: "flutter_vap",
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: StandardMessageCodec(),
      onPlatformViewCreated: (viewId) async {
        onControllerCreated(VapController(
          viewId: viewId,
          onEvent: onEvent,
        ));
      },
    );
  }
}
