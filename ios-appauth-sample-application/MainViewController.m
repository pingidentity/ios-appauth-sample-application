//
//  MainViewController.m
//  ios-appauth-sample-application
//

#import "MainViewController.h"
#import "AppAuth.h"
#import "AppDelegate.h"

/*! @var kIssuer
 @brief The OIDC issuer from which the configuration will be discovered.
 @discussion This is your base PingFederate server URL.
 */
static NSString *const kIssuer = @"https://sso.pingdevelopers.com";

/*! @var kClientID
 @brief The OAuth client ID.
 @discussion This is configured in your PingFederate administration console under OAuth Settings > Client Management. The example "ac_client" from the OAuth playground can be used here.
 */
static NSString *const kClientID = @"ac_client";

/*! @var KRedirectURI
 @brief The OAuth redirect URI for the client @c kClientID.
 @discussion The redirect URI that PingFederate will send the user back to after the authorization step. To avoid collisions, this should be a reverse domain formatted string. You must define this in your OAuth client in PingFederate.
 */
static NSString *const KRedirectURI = @"com.pingidentity.developer.appauth://oidc_callback";

/*! @var kAppAuthExampleAuthStateKey
 @brief NSCoding key for the authState property.
 */
static NSString *const kAppAuthExampleAuthStateKey = @"com.pingidentity.developer.appauth.authState";


@interface MainViewController () <OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate>
- (void)setAuthState:(nullable OIDAuthState *)authState;
@end

@implementation MainViewController

- (IBAction)actionSignIn {
    
    NSURL *issuer = [NSURL URLWithString:kIssuer];
    NSURL *redirectURI = [NSURL URLWithString:KRedirectURI];
    
    [self logMessage:@"Fetching configuration for issuer: %@", issuer];
    
    // discovers endpoints
    [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer
            completion:^(OIDServiceConfiguration *_Nullable configuration, NSError *_Nullable error) {

                if (!configuration) {
                    [self logMessage:@"Error retrieving discovery document: %@", [error localizedDescription]];
                    [self setAuthState:nil];
                    return;
                }
                
                [self logMessage:@"Got configuration: %@", configuration];
                
                // NOTE: PingFederate 8.1 and earlier do not support the S256 PKCE challenge method
                // therefore we must manually configure PKCE to use the plain method and set a
                // code_challenge and code_verifier parameter.
                NSString *code_challenge_method = @"plain";
                NSString *code_verifier = [OIDAuthorizationRequest generateCodeVerifier];
                NSString *state = [OIDAuthorizationRequest generateState];
                
                // OPTIONAL: You can include additional parameters to the authorization request
                // by including them in the additionalParameters parameters. Set this to nil if
                // you have no additional parameters. The example below sets the "acr_values" param
                // to urn:acr:form.
                NSMutableDictionary *additionalParams = [[NSMutableDictionary alloc] init];
                additionalParams[@"acr_values"] = @"urn:acr:form";
                                                           

                // builds authentication request
                OIDAuthorizationRequest *request = [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                                                                 clientId:kClientID
                                                                                                    scope:@"openid profile email address phone"
                                                                                              redirectURL:redirectURI
                                                                                             responseType:OIDResponseTypeCode
                                                                                                    state:state
                                                                                             codeVerifier:code_verifier
                                                                                            codeChallenge:code_verifier
                                                                                      codeChallengeMethod:code_challenge_method
                                                                                     additionalParameters:additionalParams];
                                                            

                // performs authentication request
                AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                [self logMessage:@"Initiating authorization request with scope: %@", request.scope];
                
                appDelegate.currentAuthorizationFlow =
                    [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                                   presentingViewController:self
                                                                   callback:^(OIDAuthState *_Nullable authState,
                                                                              NSError *_Nullable error) {
                                                                       if (authState) {
                                                                           [self setAuthState:authState];
                                                                           [self logMessage:@"Got authorization tokens. Access token: %@",
                                                                            authState.lastTokenResponse.accessToken];
                                                                       } else {
                                                                           [self logMessage:@"Authorization error: %@", [error localizedDescription]];
                                                                           [self setAuthState:nil];
                                                                       }
                                                                   }];
            }];
}

- (IBAction)actionRefreshAccessToken {
    
    // Note: Setting this value on state will force a token refresh, otherwise the tokens will be
    // automatically refreshed when they expired if using the "withFreshTokensPerformAction" method.
    [_authState setNeedsTokenRefresh];
    
    NSString *currentAccessToken = _authState.lastTokenResponse.accessToken;
    
    [self logMessage:@"Performing userinfo request"];
    
    [_authState withFreshTokensPerformAction:^(NSString *_Nonnull accessToken,
                                               NSString *_Nonnull idToken,
                                               NSError *_Nullable error) {
        if (error) {
            [self logMessage:@"Error fetching fresh tokens: %@", [error localizedDescription]];
            return;
        }
        
        // log whether a token refresh occurred
        if (currentAccessToken != accessToken) {
            [self logMessage:@"Access token was refreshed automatically (%@ to %@)",
             currentAccessToken,
             accessToken];
        } else {
            [self logMessage:@"Access token was fresh and not updated [%@]", accessToken];
        }
    }];
}

- (IBAction)actionCallUserInfo {
    
    NSURL *userinfoEndpoint =
    _authState.lastAuthorizationResponse.request.configuration.discoveryDocument.userinfoEndpoint;
    
    if (!userinfoEndpoint) {
        [self logMessage:@"Userinfo endpoint not declared in discovery document"];
        return;
    }
    
    NSString *currentAccessToken = _authState.lastTokenResponse.accessToken;
    
    [self logMessage:@"Performing userinfo request"];
    
    [_authState withFreshTokensPerformAction:^(NSString *_Nonnull accessToken,
                                               NSString *_Nonnull idToken,
                                               NSError *_Nullable error) {
        if (error) {
            [self logMessage:@"Error fetching fresh tokens: %@", [error localizedDescription]];
            return;
        }
        
        // log whether a token refresh occurred
        if (currentAccessToken != accessToken) {
            [self logMessage:@"Access token was refreshed automatically (%@ to %@)",
             currentAccessToken,
             accessToken];
        } else {
            [self logMessage:@"Access token was fresh and not updated [%@]", accessToken];
        }
        
        // creates request to the userinfo endpoint, with access token in the Authorization header
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:userinfoEndpoint];
        NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", accessToken];
        [request addValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];
        
        NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                              delegate:nil
                                                         delegateQueue:nil];
        
        // performs HTTP request
        NSURLSessionDataTask *postDataTask =
        [session dataTaskWithRequest:request
                   completionHandler:^(NSData *_Nullable data,
                                       NSURLResponse *_Nullable response,
                                       NSError *_Nullable error) {
                       dispatch_async(dispatch_get_main_queue(), ^() {
                           
                           if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                               [self logMessage:@"Non-HTTP response %@", error];
                               return;
                           }
                           
                           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                           NSError *jsonError;
                           id jsonDictionaryOrArray =
                           [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                           
                           if (httpResponse.statusCode != 200) {
                               // server replied with an error
                               NSString *responseText = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                               if (httpResponse.statusCode == 401) {
                                   // "401 Unauthorized" generally indicates there is an issue with the authorization
                                   // grant. Puts OIDAuthState into an error state.
                                   NSError *oauthError =
                                   [OIDErrorUtilities resourceServerAuthorizationErrorWithCode:0
                                                                                 errorResponse:jsonDictionaryOrArray
                                                                               underlyingError:error];
                                   [_authState updateWithAuthorizationError:oauthError];
                                   // log error
                                   [self logMessage:@"Authorization Error (%@). Response: %@", oauthError, responseText];
                               } else {
                                   [self logMessage:@"HTTP: %d. Response: %@",
                                    (int)httpResponse.statusCode,
                                    responseText];
                               }
                               return;
                           }
                           
                           // success response
                           [self logMessage:@"Success: %@", jsonDictionaryOrArray];
                           _labelSubject.text = jsonDictionaryOrArray[@"sub"];
                       });
                   }];
        
        [postDataTask resume];
    }];
}

- (IBAction)actionClearAuthenticatedState {
    
  [self setAuthState:nil];
}

- (void)updateUI {
    
    // refresh the view...
    _buttonClearAuthenticatedState.enabled = (_authState != nil);
    _buttonRefreshAccessToken.enabled = (_authState != nil);
    _buttonCallUserInfo.enabled = [_authState isAuthorized];

    if (!_authState) {
        // Not authorized
        _labelAuthenticationResult.text = @"NOT AUTHORIZED";
        _textViewAccessToken.text = @"NOT AUTHORIZED";
        _textViewRefreshToken.text = @"NOT AUTHORIZED";
        _textViewIdToken.text = @"NOT AUTHORIZED";
        _labelSubject.text = @"CALL USERINFO";
    } else {
        _labelAuthenticationResult.text = @"AUTHORIZED";
        _textViewAccessToken.text = _authState.lastTokenResponse.accessToken;
        _textViewRefreshToken.text = _authState.lastTokenResponse.refreshToken;
        _textViewIdToken.text = _authState.lastTokenResponse.idToken;
    }
}

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [self loadState];
    [self updateUI];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*! @fn saveState
 @brief Saves the @c OIDAuthState to @c NSUSerDefaults.
 */
- (void)saveState {
    
    // for production usage consider using the OS Keychain instead
    NSData *archivedAuthState = [ NSKeyedArchiver archivedDataWithRootObject:_authState];
    [[NSUserDefaults standardUserDefaults] setObject:archivedAuthState
                                              forKey:kAppAuthExampleAuthStateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/*! @fn loadState
 @brief Loads the @c OIDAuthState from @c NSUSerDefaults.
 */
- (void)loadState {
    
    // loads OIDAuthState from NSUSerDefaults
    NSData *archivedAuthState =
    [[NSUserDefaults standardUserDefaults] objectForKey:kAppAuthExampleAuthStateKey];
    OIDAuthState *authState = [NSKeyedUnarchiver unarchiveObjectWithData:archivedAuthState];
    [self setAuthState:authState];
}

- (void)setAuthState:(nullable OIDAuthState *)authState {
    
    _authState = authState;
    _authState.stateChangeDelegate = self;
    [self stateChanged];
}

- (void)stateChanged {
    
    [self saveState];
    [self updateUI];
}

- (void)didChangeState:(OIDAuthState *)state {
    
    [self stateChanged];
}

- (void)authState:(OIDAuthState *)state didEncounterAuthorizationError:(nonnull NSError *)error {
    
    [self logMessage:@"Received authorization error: %@", error];
}

- (void)logMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
    
    // gets message as string
    va_list argp;
    va_start(argp, format);
    NSString *log = [[NSString alloc] initWithFormat:format arguments:argp];
    va_end(argp);
    
    // outputs to stdout
    NSLog(@"%@", log);
}

@end
