[中文文档](./README_CH.md)

This library is an independent branch from [flutter_vap](https://pub.dev/packages/flutter_vap), and the original library is no longer maintained.

Changes include: adding support for fusion animation, upgrading the flutter version, and merging existing PRs.


### Backdrop
Transparent video animation is currently one of the more popular implementations of animation. Major manufacturers have also open sourced their own frameworks. In the end, we chose [Tencent vap](https://github.com/Tencent/vap), which supports Android, IOS, and Web, and provides natural convenience for us to encapsulate flutter_vap. Provides a tool to generate a video with an alpha channel from a frame picture, which is simply awesome.



VAP（Video Animation Player）is developed by Penguin E-sports and is used to play cool animations.
- Compared with Webp and Apng animation solutions, it has the advantages of high compression rate (smaller material) and hardware decoding (faster decoding)
- Compared with Lottie, it can achieve more complex animation effects (such as particle effects)

### Preview
![image](http://file.jinxianyun.com/flutter_vap.gif)

[video for youtube](https://youtu.be/OCLkFhcYqwA)

[video for qiniu](http://file.jinxianyun.com/flutter_vap.mp4)

[apk download](http://file.jinxianyun.com/flutter_vap.apk)

### Setup
```
flutter_vap_plus: ${last_version}
```

### How to use
```dart
import 'package:flutter_vap_plus/flutter_vap_plus.dart';

late VapController vapController;

IgnorePointer(
  // VapView can set the width and height through the outer package Container() to limit the width and height of the pop-up video
  child: VapView(
    fit: VapScaleFit.FIT_XY,
    onEvent: (event, args) {
      debugPrint('VapView event:${event}');
    },
    onControllerCreated: (controller) {
      vapController = controller;
    },
  ),
),
```

1. Play local video
```dart
  import 'package:flutter_vap_plus/flutter_vap_plus.dart';

  
  Future<void> _playFile(String path) async {
    if (path == null) {
      return null;
    }
    await vapController.playPath(path);
  }
```

2. Play asset video
```dart
  Future<void> _playAsset(String asset) async {
    if (asset == null) {
      return null;
    }
    await vapController.playAsset(asset);
  }
```

3. Set fusion animation during playback
```dart
import 'package:flutter_vap_plus/flutter_vap_plus.dart';

Future<void> _playFile(String path) async {
  if (path == null) {
    return null;
  }
  await vapController.playPath(path, fetchResources: [
    FetchResourceModel(tag: 'tag', resource: '1.png'),
    FetchResourceModel(
        tag: 'text', resource: 'test user 1'),
  ]);
}
```

3. Stop play
```dart
  VapController.stop()
```

4. Queue play
```dart
  _queuePlay() async {。
    // Simultaneously call playback in multiple places, making the queue perform playback.
    QueueUtil.get("vapQueue").addTask(() => VapController.playPath(downloadPathList[0]));
    QueueUtil.get("vapQueue").addTask(() => VapController.playPath(downloadPathList[1]));
  }

  _queuePlay2()async{
    await vapController?.playPath(downloadPathList[0]);
    await vapController?.playPath(downloadPathList[1]);
    await _playAsset("static/demo.mp4");
  }
```

5. Cancel queue playback
```dart
  QueueUtil.get("vapQueue").cancelTask();
```

Example

[github](https://github.com/Astra1427/flutter_vap_plus/blob/main/example/lib/main.dart)


