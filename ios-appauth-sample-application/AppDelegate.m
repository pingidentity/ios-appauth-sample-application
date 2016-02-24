//
//  AppDelegate.m
//  ios-appauth-sample-application
//

#import "AppDelegate.h"

#import "AppAuth.h"
#import "MainViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
    return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {

    // Sends the URL to the current authorization flow (if any) which will process it if it relates to
    // an authorization response.
    if ([_currentAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        _currentAuthorizationFlow = nil;
        return YES;
    }
    
    // Your additional URL handling (if any) goes here.
    
    return NO;
}

@end
