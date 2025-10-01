#import "NativeVapView.h"
#import "UIView+VAP.h"
#import "QGVAPWrapView.h"
#import "FetchResourceModel.h"
#import <Flutter/Flutter.h>

@interface NativeVapView : NSObject <FlutterPlatformView, VAPWrapViewDelegate>

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;

@end

@implementation NativeVapViewFactory {
    NSObject<FlutterPluginRegistrar> *_registrar;
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
    }
    return self;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id _Nullable)args {
    return [[NativeVapView alloc] initWithFrame:frame
                                 viewIdentifier:viewId
                                      arguments:args
                                binaryMessenger:_registrar.messenger];
}

@end

@implementation NativeVapView {
    UIView *_view;
    QGVAPWrapView *_wrapView;
    BOOL playStatus;
    FlutterMethodChannel *_methodChannel;
    NSArray<FetchResourceModel *> *_fetchResources;
    id _args;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    _args = args;
    if (self) {
        playStatus = NO;
        _view = [[UIView alloc] initWithFrame:frame];

        // Initialize MethodChannel
        NSString *methodChannelName = [NSString stringWithFormat:@"flutter_vap_controller_%lld", viewId];
        _methodChannel = [FlutterMethodChannel methodChannelWithName:methodChannelName binaryMessenger:messenger];
        __weak typeof(self) weakSelf = self;
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            [weakSelf handleMethodCall:call result:result];
        }];
    }
    return self;
}

#pragma mark - FlutterPlatformView

- (UIView *)view {
    return _view;
}

#pragma mark - Method Call Handling

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"playPath" isEqualToString:call.method]) {
        NSString *path = call.arguments[@"path"];
        if (path) {
            [self playByPath:path withResult:result];
        } else {
            result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                       message:@"Path is null"
                                       details:nil]);
        }
    } else if ([@"playAsset" isEqualToString:call.method]) {
        NSString *asset = call.arguments[@"asset"];
        if (asset) {
            NSString *appFrameworkPath = [[NSBundle mainBundle] privateFrameworksURL].path;
            NSString *appFrameworkName = @"App.framework";
            NSString *flutterAssetsPath = [appFrameworkPath stringByAppendingPathComponent:appFrameworkName];
            flutterAssetsPath = [flutterAssetsPath stringByAppendingPathComponent:@"flutter_assets"];
            NSString *assetPath = [flutterAssetsPath stringByAppendingPathComponent:asset];

            if (assetPath) {
                [self playByPath:assetPath withResult:result];
            } else {
                result([FlutterError errorWithCode:@"ASSET_NOT_FOUND"
                                           message:@"Asset not found"
                                           details:nil]);
            }
        } else {
            result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                       message:@"Asset is null"
                                       details:nil]);
        }
    } else if ([@"stop" isEqualToString:call.method]) {
        [self stopPlayback];
        result(nil);
    } else if ([@"setFetchResource" isEqualToString:call.method]){
        NSString *rawJson = (NSString *) call.arguments;
        _fetchResources = [FetchResourceModel fromRawJsonArray:rawJson];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Playback Control

- (void)playByPath:(NSString *)path withResult:(FlutterResult)result {
    if (playStatus) {
        result([FlutterError errorWithCode:@"ALREADY_PLAYING"
                                   message:@"A video is already playing"
                                   details:nil]);
        return;
    }

    playStatus = YES;
    _wrapView = [[QGVAPWrapView alloc] initWithFrame:_view.bounds];
    _wrapView.center = _view.center;
    _wrapView.contentMode = QGVAPWrapViewContentModeAspectFit;
    _wrapView.autoDestoryAfterFinish = YES;

    [_view addSubview:_wrapView];

    // 🔹 Read repeatCount from args
    NSInteger repeatCount = 0; // default
    if ([_args isKindOfClass:[NSDictionary class]]) {
        NSNumber *repeatArg = _args[@"repeatCount"];
        if (repeatArg != nil && [repeatArg isKindOfClass:[NSNumber class]]) {
            repeatCount = [repeatArg integerValue];
        }
    }

    // 🔹 If repeatCount = -1, loop infinitely
    if (repeatCount == -1) {
        repeatCount = NSIntegerMax;
    }

    [_wrapView vapWrapView_playHWDMP4:path repeatCount:repeatCount delegate:self];

    result(nil);
    [_methodChannel invokeMethod:@"onStart" arguments:@{@"status" : @"start"}];
}

- (void)stopPlayback {
    if (_wrapView) {
        [_wrapView removeFromSuperview];
        _wrapView = nil;
    }
    playStatus = NO;
}

#pragma mark - VAPWrapViewDelegate

- (void)vapWrap_viewDidStartPlayMP4:(VAPView *)container {
    playStatus = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_methodChannel invokeMethod:@"onStart" arguments:@{@"status" : @"start"}];
    });
}

- (void)vapWrap_viewDidFailPlayMP4:(NSError *)error {
    playStatus = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_methodChannel invokeMethod:@"onFailed" arguments:@{
                @"status": @"failure",
                @"errorMsg": error.localizedDescription ?: @"Unknown error"
        }];
    });
}

- (void)vapWrap_viewDidStopPlayMP4:(NSInteger)lastFrameIndex view:(VAPView *)container {
    playStatus = NO;
}

- (void)vapWrap_viewDidFinishPlayMP4:(NSInteger)totalFrameCount view:(VAPView *)container {
    playStatus = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_methodChannel invokeMethod:@"onComplete" arguments:@{@"status" : @"complete"}];
    });
}

- (NSString *)vapWrapview_contentForVapTag:(NSString *)tag resource:(QGVAPSourceInfo *)info {
    for(FetchResourceModel *model in _fetchResources){
        if([model.tag isEqualToString:tag]){
            NSLog(@"%@", [[@"vapWrapview_contentForVapTaging:" stringByAppendingString:tag] stringByAppendingString:model.resource]);
            return model.resource;
        }
    }
    return nil;
}

- (void)vapWrapView_loadVapImageWithURL:(NSString *)urlStr context:(NSDictionary *)context completion:(VAPImageCompletionBlock)completionBlock {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageWithContentsOfFile:urlStr];
        completionBlock(image,nil,urlStr);
    });
}

@end
