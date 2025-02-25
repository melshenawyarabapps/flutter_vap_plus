
该库是从[flutter_vap](https://pub.dev/packages/flutter_vap)独立的分支，原库已经没人维护。

改动包括：新增支持融合动画，升级flutter版本，合并现有的PR。

---
### 背景
透明视频动画是目前比较流行的实现动画的一种, 大厂也相继开源自己的框架，最终我们选中[腾讯vap](https://github.com/Tencent/vap)，它支持了Android、IOS、Web，为我们封装flutter_vap提供了天然的便利，并且它提供了将帧图片生成带alpha通道视频的工具，这简直太赞了。


VAP（Video Animation Player）是企鹅电竞开发，用于播放酷炫动画的实现方案。
- 相比Webp, Apng动图方案，具有高压缩率(素材更小)、硬件解码(解码更快)的优点
- 相比Lottie，能实现更复杂的动画效果(比如粒子特效)

### 预览
![image](http://file.jinxianyun.com/flutter_vap.gif)

[video for youtube](https://youtu.be/OCLkFhcYqwA)

[video for qiniu](http://file.jinxianyun.com/flutter_vap.mp4)

[apk download](http://file.jinxianyun.com/flutter_vap.apk)

### 安装
```
flutter_vap: ${last_version}
```

### 使用
```dart
import 'package:flutter_vap_plus/flutter_vap_plus.dart';

late VapController vapController;

IgnorePointer(
  // VapView可以通过外层包Container(),设置宽高来限制弹出视频的宽高
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

1. 播放本地视频
```dart
  import 'package:flutter_vap_plus/flutter_vap_plus.dart';

  
  Future<void> _playFile(String path) async {
    if (path == null) {
      return null;
    }
    await vapController.playPath(path);
  }
```

2. 播放asset视频
```dart
  Future<void> _playAsset(String asset) async {
    if (asset == null) {
      return null;
    }
    await vapController.playAsset(asset);
  }
```

3. 播放时设置融合动画
```dart
import 'package:flutter_vap_plus/flutter_vap_plus.dart';

Future<void> _playFile(String path) async {
  if (path == null) {
    return null;
  }
  await vapController.playPath(path, fetchResources: [
    FetchResourceModel(tag: 'tag', resource: '1.png'),
    FetchResourceModel(
        tag: 'text', resource: '测试用户1'),
  ]);
}
```

4. 停止播放
```dart
  vapController.stop()
```

5. 队列播放
```dart
  _queuePlay() async {
    // 模拟多个地方同时调用播放,使得队列执行播放。
    QueueUtil.get("vapQueue").addTask(() => vapController.playPath(downloadPathList[0]));
    QueueUtil.get("vapQueue").addTask(() => vapController.playPath(downloadPathList[1]));
  }
  
  _queuePlay2()async{
    await vapController?.playPath(downloadPathList[0]);
    await vapController?.playPath(downloadPathList[1]);
    await _playAsset("static/demo.mp4");
  }
```

6. 取消队列播放
```dart
  QueueUtil.get("vapQueue").cancelTask();
```

### 例子
[github](https://github.com/Astra1427/flutter_vap_plus/blob/main/example/lib/main.dart)
