import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VapController {
  late final MethodChannel _methodChannel;
  final int viewId;
  final void Function(dynamic event,dynamic arguments)? onEvent;

  VapController({
    required this.viewId,
    this.onEvent,
  }) {
    _methodChannel = MethodChannel('flutter_vap_controller_$viewId');
    _methodChannel.setMethodCallHandler(_onMethodCallHandler);
  }

  Completer<void>? playCompleter;


  /// return: play error:       {"status": "failure", "errorMsg": ""}
  ///         play complete:    {"status": "complete"}
  Future<void> playPath(String path,
      {List<FetchResourceModel> fetchResources = const []}) async {
    try {
      playCompleter = Completer<void>();
      await Future.delayed(const Duration(milliseconds: 50));
      await _methodChannel.invokeMethod('playPath', {"path": path});
      await setFetchResources(fetchResources);
      return playCompleter!.future.timeout(const Duration(seconds: 20),
          onTimeout: () {
            playCompleter?.completeError(
                TimeoutException("wait play complete timeout"));
          });
    } catch (e, s) {
      playCompleter?.completeError(e, s);
    }
  }

  Future<void> playAsset(String asset,
      {List<FetchResourceModel> fetchResources = const []}) async {
    try {
      playCompleter = Completer<void>();
      await _methodChannel.invokeMethod('playAsset', {"asset": asset});
      await setFetchResources(fetchResources);
      return playCompleter!.future.timeout(const Duration(seconds: 20),
          onTimeout: () {
            playCompleter?.completeError(
                TimeoutException("wait play complete timeout"));
          });
    } catch (e, s) {
      playCompleter?.completeError(e, s);
    }
  }

  stop() {
    _methodChannel.invokeMethod('stop');
  }

  Future setFetchResources(List<FetchResourceModel> resources) {
    return _methodChannel.invokeMethod(
        'setFetchResource',
        jsonEncode(resources.map((e) => e.toMap()).toList()));
  }

  void dispose() {
    _methodChannel.setMethodCallHandler(null);
  }

  Future _onMethodCallHandler(MethodCall call) async {
    onEvent?.call(call.method,call.arguments);
    switch (call.method) {
      case "onComplete":
        playCompleter?.complete();
        break;
      case "onFailed":
        playCompleter?.completeError(call.arguments);
        break;
    }
  }
}

class FetchResourceModel {
  /// vap资源文件中预设的tag
  final String tag;

  /// 图片本地路径或者文本字符串
  final String resource;

  FetchResourceModel({required this.tag, required this.resource});

  Map<String, String> toMap() =>
      {
        'tag': tag,
        'resource': resource,
      };

}
