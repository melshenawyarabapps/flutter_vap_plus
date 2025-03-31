import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:flutter_vap_plus/flutter_vap_plus.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> downloadPathList = [];
  bool isDownload = false;
  VapController? vapController;
  VapScaleFit vapScaleFit = VapScaleFit.FIT_XY;

  @override
  void initState() {
    super.initState();
    initDownloadPath();
  }

  Future<void> initDownloadPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String rootPath = appDocDir.path;
    downloadPathList = ["$rootPath/vap_demo1.mp4", "$rootPath/vap_demo2.mp4"];
    print("downloadPathList:$downloadPathList");
  }

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        home: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 100, 241, 243),
              // image: DecorationImage(image: AssetImage("static/bg.jpeg")),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoButton(
                      color: Colors.purple,
                      child: Text(
                          "download video source${isDownload ? "(✅)" : ""}"),
                      onPressed: _download,
                    ),
                    CupertinoButton(
                      color: Colors.purple,
                      child: Text("File1 play"),
                      onPressed: () => _playFile(downloadPathList[0]),
                    ),
                    CupertinoButton(
                      color: Colors.purple,
                      child: Text("File2 play"),
                      onPressed: () => _playFile(downloadPathList[1]),
                    ),
                    CupertinoButton(
                      color: Colors.purple,
                      child: Text("asset play"),
                      onPressed: () => _playAsset("static/demo.mp4"),
                    ),
                    Builder(builder: (context) {
                      return CupertinoButton(
                        color: Colors.purple,
                        child: Text("fusion animation play"),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            barrierDismissible: true,
                            // false = user must tap button, true = tap outside dialog
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                backgroundColor: Colors.transparent,
                                content: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: IgnorePointer(
                                      child: VapView(
                                          fit: VapScaleFit.FIT_CENTER,
                                          onControllerCreated:
                                              (controller) async {
                                            var avatarFile =
                                                await _getImageFileFromAssets(
                                                    'static/bg.jpeg');
                                            await controller.playAsset(
                                                'static/video.mp4',
                                                fetchResources: [
                                                  FetchResourceModel(
                                                      tag: '01',
                                                      resource: '测试文本01'),
                                                  FetchResourceModel(
                                                      tag: '02',
                                                      resource: '测试文本02'),
                                                  FetchResourceModel(
                                                      tag: '03',
                                                      resource:
                                                          avatarFile.path),
                                                ]);

                                            Navigator.of(context).pop();
                                          }),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }),
                    CupertinoButton(
                      color: Colors.purple,
                      child: Text("stop play"),
                      onPressed: () => vapController?.stop(),
                    ),
                    CupertinoButton(
                      color: Colors.purple,
                      child: Text("queue play"),
                      onPressed: _queuePlay,
                    ),
                  ],
                ),
                Positioned.fill(
                    child: IgnorePointer(
                  // VapView可以通过外层包Container(),设置宽高来限制弹出视频的宽高
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
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<File> _getImageFileFromAssets(String path) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    var filePath = "$tempPath/$path";
    var file = File(filePath);
    if (file.existsSync()) {
      return file;
    } else {
      final byteData = await rootBundle.load(path);
      final buffer = byteData.buffer;
      await file.create(recursive: true);
      return file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
  }

  _download() async {
    await Dio().download(
        "https://res.cloudinary.com/dkmchpua1/video/upload/v1737623468/zta2wxsuokcskw0bhar7.mp4",
        downloadPathList[0]);
    await Dio().download(
        "https://res.cloudinary.com/dkmchpua1/video/upload/v1737624783/vcg9co6yyfqsadgety1n.mp4",
        downloadPathList[1]);
    setState(() {
      isDownload = true;
    });
  }

  Future<void> _playFile(String path,
      {List<FetchResourceModel> fetchResources = const []}) async {
    try {
      await vapController?.playPath(path, fetchResources: fetchResources);
    } catch (e, s) {
      print(s);
    }
  }

  Future<void> _playAsset(String asset,
      {List<FetchResourceModel> fetchResources = const []}) async {
    await vapController?.playAsset(asset, fetchResources: fetchResources);
  }

  Future<void> _queuePlay() async {
    // 模拟多个地方同时调用播放,使得按顺序执行播放。
    // Simultaneously call playback in multiple places, making the queue perform playback.
    await vapController?.playPath(downloadPathList[0]);
    await vapController?.playPath(downloadPathList[1]);
    await _playAsset("static/demo.mp4");
  }
}
