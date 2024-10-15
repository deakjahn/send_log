#import "SendLogPlugin.h"
#if __has_include(<send_log/send_log-Swift.h>)
#import <send_log/send_log-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "send_log-Swift.h"
#endif

@implementation SendLogPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSendLogPlugin registerWithRegistrar:registrar];
}
@end
