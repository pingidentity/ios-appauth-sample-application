//
//  MainViewController.h
//  ios-appauth-sample-application
//

#import <UIKit/UIKit.h>

@class OIDAuthState;
@class OIDServiceConfiguration;

@interface MainViewController : UIViewController

/*! @property authState
 @brief The authorization state. This is the AppAuth object that you should keep around and
 serialize to disk.
 */
@property(nonatomic, strong, readonly, nullable) OIDAuthState *authState;

// outlets for the text labels and text view components
@property (weak, nonatomic) IBOutlet UILabel *labelAuthenticationResult;
@property (weak, nonatomic) IBOutlet UILabel *labelSubject;
@property (weak, nonatomic) IBOutlet UITextView *textViewIdToken;
@property (weak, nonatomic) IBOutlet UITextView *textViewAccessToken;
@property (weak, nonatomic) IBOutlet UITextView *textViewRefreshToken;

// outlets for the buttons
@property (weak, nonatomic) IBOutlet UIButton *buttonSignIn;
@property (weak, nonatomic) IBOutlet UIButton *buttonRefreshAccessToken;
@property (weak, nonatomic) IBOutlet UIButton *buttonCallUserInfo;
@property (weak, nonatomic) IBOutlet UIButton *buttonClearAuthenticatedState;

@end

