#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "../Classes/NativeVapView.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  FlutterViewController *controller = (FlutterViewController *)self.window.rootViewController;

  // Get the registrar for the plugin
  NSObject<FlutterPluginRegistrar> *registrar = [controller.engine registrarForPlugin:@"NativeVapViewPlugin"];

  // Register NativeVapViewFactory with the registrar
  NativeVapViewFactory *factory = [[NativeVapViewFactory alloc] initWithRegistrar:registrar];
  [registrar registerViewFactory:factory withId:@"native_vap_view"];

  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
