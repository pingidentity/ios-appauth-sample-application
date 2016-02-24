//
//  AppDelegate.h
//  ios-appauth-sample-application
//

#import <UIKit/UIKit.h>

@protocol OIDAuthorizationFlowSession;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic, nullable) UIWindow *window;

/*! @property currentAuthorizationFlow
 @brief The authorization flow session which receives the return URL from SFSafariViewController.
 @discussion We need to store this in the app delegate as it's that delegate which receives the
 incoming URL on UIApplicationDelegate.application:openURL:options:. This property will be
 nil, except when an authorization flow is in progress.
 */
@property(nonatomic, strong, nullable) id<OIDAuthorizationFlowSession> currentAuthorizationFlow;

@end

