# iOS9 Native Application SSO Sample Application

**ios-appauth-sample-application** is a basic sample application to demonstrate native application single sign-on using the [AppAuth library for iOS](https://github.com/openid/AppAuth-iOS) from the OpenID Foundation.

This sample application is based on the "example" in the AppAuth reference libraries and will authenticate the user and present the user's subject and tokens on the screen. Options to refresh the OAuth 2.0 access token and to refresh the authentication session are also demonstrated.

Refer to the [Mobile Application SSO Developers Guide](https://developer.pingidentity.com/en/resources/napps-native-app-sso) for more detailed information.

Note: You can get developer licenses and the PingFederate software at https://developer.pingidentity.com/get-started


## Installation

This sample application has been built using PingFederate 8.0.1 and the OAuth Playground 3.2. Follow the documentation for PingFederate and the OAuth Playground to quickly stand up an OpenID Connect Provider / OAuth Authorization Server.

### You will need

- PingFederate server & license ([download developer software and licenses](https://developer.pingidentity.com/get-started))
- OAuth Playground (available from [product downloads](https://www.pingidentity.com/en/products/downloads/pingfederate-downloads.html))
- [AppAuth library for iOS](https://github.com/openid/AppAuth-iOS)

### XCode & project configuration

- Open this project (ios-appauth-sample-application) in XCode
- Add the [AppAuth library for iOS](https://github.com/openid/AppAuth-iOS) project to your XCode project (File > Add Files to Project.. and browse to the AppAuth.xcodeproj file)
- Modify the project settings of the ios-appauth-sample-application
..- under Build Settings, modify the "Header Search Paths" to include the location of the AppAuth .h files
..- under Build Phases, add to the "Link Binary With Libraries" list and add libAppAuth.a and SafariServices.framework
- Modify the MainViewController.m file to define your PingFederate server, your client_id and redirect_uri

### PingFederate configuration

- Install PingFederate and the OAuth Playground (see the readme in the OAuth Playground distribution)
- Modify the OAuth client "ac_client" in the PingFederate configuration:
..- OAuth Settings -> Client Management -> ac_client
..- Edit the "Redirect URIs" option to include the application callback URI (com.pingidentity.developer.appauth://oidc_callback)


Note: Due to the Application Transport Security (ATS) feature of iOS9, your PingFederate server must have a valid SSL certificate.


## Disclaimer

*This software is open sourced by Ping Identity but not supported commercially as such. Any questions/issues/comments should be directed to the "Developer Q&A" group in the Ping Identity Support Communities https://community.pingidentity.com/collaborate.*
