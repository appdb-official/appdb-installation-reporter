#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface InstallReporter : NSObject
+ (void)reportInstall;
+ (void)reportInstallInternal;
@property(class, nonatomic) BOOL isReporting;
@property(class, nonatomic, strong) dispatch_queue_t reportingQueue;
@end

@implementation InstallReporter

static BOOL _isReporting = NO;
static dispatch_queue_t _reportingQueue = nil;

+ (BOOL)isReporting {
  return _isReporting;
}

+ (void)setIsReporting:(BOOL)isReporting {
  _isReporting = isReporting;
}

+ (dispatch_queue_t)reportingQueue {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _reportingQueue = dispatch_queue_create("com.appdb.reporting.objc",
                                            DISPATCH_QUEUE_SERIAL);
  });
  return _reportingQueue;
}

+ (void)setReportingQueue:(dispatch_queue_t)reportingQueue {
  // This setter is required by the property declaration but not used
  // since we manage the queue creation internally
}

+ (void)reportInstallInternal {
  NSLog(@"appdb: reporting install (Objective-C)");

  @try {
    [self setIsReporting:YES];
    // Get Info.plist dictionary
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    if (!infoPlist) {
      NSLog(@"appdb: Failed to get Info.plist");
      [self setIsReporting:NO];
      return;
    }

    // Get installation UUID and team ID
    NSString *installationUUID = [infoPlist objectForKey:@"installationUUID"];
    NSString *teamID = [infoPlist objectForKey:@"assignedAppleTeamIdentifier"];

    if (!installationUUID || !teamID) {
      NSLog(@"appdb: Failed to get installationUUID or teamID from Info.plist");
      [self setIsReporting:NO];
      return;
    }

    NSLog(@"appdb: installationUUID: %@", installationUUID);

    // Get system version
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSLog(@"appdb: iOS version: %@", systemVersion);

    // Get bundle identifier
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (!bundleIdentifier) {
      NSLog(@"appdb: Failed to get bundle identifier");
      [self setIsReporting:NO];
      return;
    }

    NSLog(@"appdb: Bundle identifier: %@", bundleIdentifier);

    // URL encode parameters
    NSCharacterSet *allowedCharacters =
        [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodedUUID =
        [installationUUID stringByAddingPercentEncodingWithAllowedCharacters:
                              allowedCharacters]
            ?: @"";
    NSString *encodedOSVersion =
        [systemVersion stringByAddingPercentEncodingWithAllowedCharacters:
                           allowedCharacters]
            ?: @"";
    NSString *encodedBundleID =
        [bundleIdentifier stringByAddingPercentEncodingWithAllowedCharacters:
                              allowedCharacters]
            ?: @"";
    NSString *encodedTeamID =
        [teamID stringByAddingPercentEncodingWithAllowedCharacters:
                    allowedCharacters]
            ?: @"";

    NSLog(@"appdb: Creating URL with encoded parameters");

    // Create URL string
    NSString *urlString = [NSString
        stringWithFormat:@"https://dbservices.to/report-install/"
                         @"?uuid=%@&os_version=%@&bundle_id=%@&team_id=%@",
                         encodedUUID, encodedOSVersion, encodedBundleID,
                         encodedTeamID];

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
      NSLog(@"appdb: Failed to create URL");
      [self setIsReporting:NO];
      return;
    }

    NSLog(@"appdb: URL created successfully: %@", [url absoluteString]);

    // Create URL session configuration
    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30.0;

    NSLog(@"appdb: Creating URLSession");
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSLog(@"appdb: Creating data task");
    NSURLSessionDataTask *task = [session
          dataTaskWithURL:url
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          @try {
            if (error) {
              NSLog(@"appdb: Network error: %@", [error localizedDescription]);
              return;
            }

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
              NSLog(@"appdb: Invalid response type");
              return;
            }

            NSLog(@"appdb: Response status code: %ld",
                  (long)[httpResponse statusCode]);

            if (!data) {
              NSLog(@"appdb: Failed to get data from server");
              return;
            }

            NSLog(@"appdb: Received data length: %lu",
                  (unsigned long)[data length]);

            NSString *reply =
                [[NSString alloc] initWithData:data
                                      encoding:NSUTF8StringEncoding];
            if (!reply) {
              NSLog(@"appdb: Failed to decode server response");
              return;
            }

            NSLog(@"appdb: report install reply %@", reply);
          } @catch (NSException *exception) {
            NSLog(@"appdb: Exception in response handling: %@",
                  [exception reason]);
          }

          // Reset the flag after completion
          [InstallReporter setIsReporting:NO];
        }];

    NSLog(@"appdb: Starting network request");
    [task resume];
    NSLog(@"appdb: Network request started");

  } @catch (NSException *exception) {
    NSLog(@"appdb: Exception in reportInstall: %@", [exception reason]);
    [self setIsReporting:NO];
  }
}

+ (void)reportInstall {
  dispatch_async([self reportingQueue], ^{
    NSLog(@"appdb: In background queue, calling reportInstall");
    // Check if already reporting (now inside serial queue)
    if ([self isReporting]) {
      NSLog(@"appdb: reporting install already in progress, skipping "
            @"(Objective-C)");
      return;
    }
    [self reportInstallInternal];
    NSLog(@"appdb: reportInstall completed");
  });
}

@end

// C function to be called by constructor
void auto_report_install(void) {
  NSLog(@"appdb: auto_report_install called (Objective-C)");

  @try {
    [InstallReporter reportInstall];
    NSLog(@"appdb: Background operation dispatched");
  } @catch (NSException *exception) {
    NSLog(@"appdb: Exception in auto_report_install: %@", [exception reason]);
  }
}